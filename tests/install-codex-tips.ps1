$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceInstaller = Join-Path $repoRoot "bin\install-codex-tips.ps1"
$fixture = Join-Path ([System.IO.Path]::GetTempPath()) ("install-codex-tips-test-" + [Guid]::NewGuid().ToString("N"))

try {
    $testRepo = Join-Path $fixture "repo"
    $testBin = Join-Path $testRepo "bin"
    $testPatches = Join-Path $testRepo "patches\codex-tips"
    $installer = Join-Path $testBin "install-codex-tips.ps1"
    New-Item -ItemType Directory -Path $testBin, $testPatches | Out-Null
    Copy-Item -LiteralPath $sourceInstaller -Destination $installer
    foreach ($version in "0.151.0", "0.152.0") {
        [System.IO.File]::WriteAllText((Join-Path $testPatches "rust-v$version.patch"), "")
    }

    foreach ($version in "0.151.0", "0.152.0") {
        # Given a versioned official Windows runtime package and existing patched binary.
        $caseRoot = Join-Path $fixture "version-$version"
        New-Item -ItemType Directory -Path $caseRoot | Out-Null
        $officialCommand = Join-Path $caseRoot "codex-official.cmd"
        Set-Content -LiteralPath $officialCommand -Value "@echo off`r`necho codex-cli $version`r`n" -NoNewline

        $runtimeRoot = Join-Path $caseRoot "runtime"
        $runtimeBin = Join-Path $runtimeRoot "bin"
        $runtimeResources = Join-Path $runtimeRoot "codex-resources"
        $runtimePath = Join-Path $runtimeRoot "codex-path"
        New-Item -ItemType Directory -Path $runtimeBin, $runtimeResources, $runtimePath | Out-Null
        Set-Content -LiteralPath (Join-Path $runtimeRoot "codex-package.json") -Value "{`"layoutVersion`":1,`"version`":`"$version`"}"
        Set-Content -LiteralPath (Join-Path $runtimeBin "codex-code-mode-host.exe") -Value "host fixture"
        Set-Content -LiteralPath (Join-Path $runtimeResources "codex-command-runner.exe") -Value "runner fixture"
        Set-Content -LiteralPath (Join-Path $runtimeResources "codex-windows-sandbox-setup.exe") -Value "sandbox fixture"
        Set-Content -LiteralPath (Join-Path $runtimePath "rg.exe") -Value "rg fixture"

        $source = Join-Path $caseRoot "codex.rs"
        Set-Content -LiteralPath $source -Value "fn main() { println!(`"codex-cli $version`"); }"
        $fixtureBinary = Join-Path $runtimeBin "codex.exe"
        & rustc $source -o $fixtureBinary
        if ($LASTEXITCODE -ne 0) { throw "failed to build Windows fixture executable for $version" }

        $installRoot = Join-Path $caseRoot "install"
        $installedDir = Join-Path $installRoot $version
        $installedBin = Join-Path $installedDir "bin"
        $visibleBin = Join-Path $caseRoot "visible-bin"
        New-Item -ItemType Directory -Path $installedBin | Out-Null
        Copy-Item -LiteralPath $fixtureBinary -Destination (Join-Path $installedBin "codex.exe")

        $env:CODEX_TIPS_CODEX = $officialCommand
        $env:CODEX_TIPS_RUNTIME_PACKAGE = $runtimeRoot
        $env:CODEX_TIPS_INSTALL_ROOT = $installRoot
        $env:CODEX_TIPS_BIN_DIR = $visibleBin
        $env:CODEX_TIPS_UPDATE_PATH = "0"

        # When the native PowerShell installer repairs the matching fast-path installation.
        & $installer

        # Then the package helpers and managed launchers are complete and runnable.
        $expectedFiles = @(
            "bin\codex-code-mode-host.exe",
            "codex-resources\codex-command-runner.exe",
            "codex-resources\codex-windows-sandbox-setup.exe",
            "codex-path\rg.exe",
            "codex-package.json"
        )
        foreach ($relativePath in $expectedFiles) {
            if (-not (Test-Path -LiteralPath (Join-Path $installedDir $relativePath))) {
                throw "missing installed runtime file for ${version}: $relativePath"
            }
        }
        $codexTipsLauncher = Join-Path $visibleBin "codex-tips.cmd"
        $codexLauncher = Join-Path $visibleBin "codex.cmd"
        if ((& $codexTipsLauncher --version) -ne "codex-cli $version") {
            throw "codex-tips launcher did not run the $version patched binary"
        }
        if ((& $codexLauncher --version) -ne "codex-cli $version") {
            throw "codex launcher did not run the $version patched binary"
        }
    }

    # Given an unsupported official Codex version.
    $unsupportedCommand = Join-Path $fixture "codex-unsupported.cmd"
    Set-Content -LiteralPath $unsupportedCommand -Value "@echo off`r`necho codex-cli 0.153.0`r`n" -NoNewline
    $env:CODEX_TIPS_CODEX = $unsupportedCommand

    # When installation is attempted, then it fails before source checkout or build.
    $unsupportedOutput = & pwsh -NoProfile -File $installer 2>&1
    if ($LASTEXITCODE -eq 0) { throw "unsupported Codex version unexpectedly succeeded" }
    if (($unsupportedOutput | Out-String) -notmatch "unsupported Codex version 0.153.0; supported versions: 0.151.0, 0.152.0") {
        throw "unsupported version failure did not explain the compatibility boundary"
    }
    $global:LASTEXITCODE = 0
} finally {
    Remove-Item Env:CODEX_TIPS_CODEX -ErrorAction SilentlyContinue
    Remove-Item Env:CODEX_TIPS_RUNTIME_PACKAGE -ErrorAction SilentlyContinue
    Remove-Item Env:CODEX_TIPS_INSTALL_ROOT -ErrorAction SilentlyContinue
    Remove-Item Env:CODEX_TIPS_BIN_DIR -ErrorAction SilentlyContinue
    Remove-Item Env:CODEX_TIPS_UPDATE_PATH -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $fixture) {
        Remove-Item -LiteralPath $fixture -Recurse -Force
    }
}
