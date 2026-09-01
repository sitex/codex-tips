[CmdletBinding()]
param([switch]$Force)

$ErrorActionPreference = "Stop"

function Fail([string]$Message) {
    throw "install-codex-tips: $Message"
}

function Resolve-CommandPath([string]$Command) {
    $resolved = Get-Command $Command -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $resolved) { Fail "command not found: $Command" }
    return [System.IO.Path]::GetFullPath($resolved.Source)
}

function Get-OfficialCodex([string]$ManagedBin) {
    if ($env:CODEX_TIPS_CODEX) { return Resolve-CommandPath $env:CODEX_TIPS_CODEX }

    $managedLauncher = [System.IO.Path]::GetFullPath((Join-Path $ManagedBin "codex.cmd"))
    $fallback = $null
    foreach ($command in @(Get-Command codex -All -CommandType Application -ErrorAction SilentlyContinue)) {
        $path = [System.IO.Path]::GetFullPath($command.Source)
        if ($path -ieq $managedLauncher) { continue }
        if (-not $fallback) { $fallback = $path }
        if ($path.EndsWith(".cmd", [System.StringComparison]::OrdinalIgnoreCase)) {
            $content = Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue
            if ($content -match '@openai[\\/]codex') { return $path }
        }
    }
    if (-not $fallback) { Fail "official Codex command not found; set CODEX_TIPS_CODEX" }
    return $fallback
}

function Test-RuntimePackage([string]$Root) {
    return (Test-Path -LiteralPath (Join-Path $Root "codex-package.json") -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root "bin\codex.exe") -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root "bin\codex-code-mode-host.exe") -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root "codex-resources") -PathType Container) -and
        (Test-Path -LiteralPath (Join-Path $Root "codex-path") -PathType Container)
}

function Get-RuntimePackage([string]$CodexCommand) {
    if ($env:CODEX_TIPS_RUNTIME_PACKAGE) {
        $root = [System.IO.Path]::GetFullPath($env:CODEX_TIPS_RUNTIME_PACKAGE)
        if (-not (Test-RuntimePackage $root)) { Fail "invalid Codex runtime package: $root" }
        return $root
    }

    $commandParent = Split-Path -Parent $CodexCommand
    $directRoot = Split-Path -Parent $commandParent
    if ((Split-Path -Leaf $commandParent) -ieq "bin" -and (Test-RuntimePackage $directRoot)) {
        return $directRoot
    }

    $packageRoots = [System.Collections.Generic.List[string]]::new()
    $packageRoots.Add((Join-Path $commandParent "node_modules\@openai\codex"))
    $npmRoot = (& npm root -g 2>$null | Out-String).Trim()
    if ($LASTEXITCODE -eq 0 -and $npmRoot) {
        $packageRoots.Add((Join-Path $npmRoot "@openai\codex"))
    }

    $matches = [System.Collections.Generic.List[string]]::new()
    foreach ($packageRoot in $packageRoots | Select-Object -Unique) {
        if (-not (Test-Path -LiteralPath $packageRoot -PathType Container)) { continue }
        foreach ($metadata in @(Get-ChildItem -LiteralPath $packageRoot -Filter "codex-package.json" -File -Recurse)) {
            if (Test-RuntimePackage $metadata.DirectoryName) { $matches.Add($metadata.DirectoryName) }
        }
    }
    $matches = @($matches | Select-Object -Unique)
    if ($matches.Count -ne 1) {
        Fail "expected one Codex runtime package, found $($matches.Count); set CODEX_TIPS_RUNTIME_PACKAGE"
    }
    return $matches[0]
}

function Copy-RuntimeSupport([string]$RuntimeRoot, [string]$InstalledDir) {
    $installedBin = Join-Path $InstalledDir "bin"
    New-Item -ItemType Directory -Force -Path $InstalledDir, $installedBin | Out-Null
    Copy-Item -LiteralPath (Join-Path $RuntimeRoot "codex-package.json") -Destination $InstalledDir -Force
    foreach ($directory in "codex-resources", "codex-path") {
        $destination = Join-Path $InstalledDir $directory
        if (Test-Path -LiteralPath $destination) { Remove-Item -LiteralPath $destination -Recurse -Force }
        Copy-Item -LiteralPath (Join-Path $RuntimeRoot $directory) -Destination $destination -Recurse -Force
    }
    foreach ($item in @(Get-ChildItem -LiteralPath (Join-Path $RuntimeRoot "bin"))) {
        if ($item.Name -ieq "codex.exe") { continue }
        Copy-Item -LiteralPath $item.FullName -Destination (Join-Path $installedBin $item.Name) -Recurse -Force
    }
}

function Write-ManagedLauncher([string]$Path, [string]$Binary, [string]$InstallRoot) {
    $content = "@echo off`r`n`"$Binary`" %*`r`n"
    if (Test-Path -LiteralPath $Path) {
        $existing = Get-Content -LiteralPath $Path -Raw
        if ($existing -ne $content -and $existing.IndexOf($InstallRoot, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            Fail "refusing to replace unmanaged command: $Path"
        }
    }
    $temporary = "$Path.$PID.tmp"
    [System.IO.File]::WriteAllText($temporary, $content, [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporary -Destination $Path -Force
}

function Install-Launchers([string]$Binary, [string]$BinDir, [string]$InstallRoot) {
    New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
    Write-ManagedLauncher (Join-Path $BinDir "codex-tips.cmd") $Binary $InstallRoot
    Write-ManagedLauncher (Join-Path $BinDir "codex.cmd") $Binary $InstallRoot

    if ($env:CODEX_TIPS_UPDATE_PATH -match '^(1|true|yes)$') {
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $entries = @($userPath -split ';' | Where-Object { $_ })
        if (-not ($entries | Where-Object { $_ -ieq $BinDir })) {
            [Environment]::SetEnvironmentVariable("Path", (($BinDir + $entries) -join ';'), "User")
            Write-Host "Added $BinDir to the user PATH; open a new terminal."
        }
    }
    Write-Host "Installed patched Codex commands in $BinDir"
}

function Test-BinaryVersion([string]$Binary, [string]$Version) {
    if (-not (Test-Path -LiteralPath $Binary -PathType Leaf)) { return $false }
    $output = (& $Binary --version 2>$null | Out-String).Trim()
    return $LASTEXITCODE -eq 0 -and $output.Contains($Version)
}

$localData = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { Join-Path $HOME ".local\share" }
$binDir = if ($env:CODEX_TIPS_BIN_DIR) { $env:CODEX_TIPS_BIN_DIR } else { Join-Path $localData "codex-tips\bin" }
$installRoot = if ($env:CODEX_TIPS_INSTALL_ROOT) { $env:CODEX_TIPS_INSTALL_ROOT } else { Join-Path $localData "codex-tips\lib" }
$cacheDir = if ($env:CODEX_TIPS_CACHE_DIR) { $env:CODEX_TIPS_CACHE_DIR } else { Join-Path $localData "codex-tips\cache" }
$codexCommand = Get-OfficialCodex $binDir
$versionOutput = (& $codexCommand --version 2>$null | Out-String).Trim()
if ($LASTEXITCODE -ne 0) { Fail "failed to run '$codexCommand --version'" }
if ($versionOutput -notmatch '(\d+\.\d+\.\d+)') { Fail "could not parse Codex version from: $versionOutput" }
$codexVersion = $Matches[1]
$codexTag = "rust-v$codexVersion"
$patchFile = Join-Path (Split-Path -Parent $PSScriptRoot) "patches\codex-tips\$codexTag.patch"
if (-not (Test-Path -LiteralPath $patchFile -PathType Leaf)) {
    Fail "unsupported Codex version $codexVersion; supported versions: 0.152.0"
}
$expectedCommit = switch ($codexTag) {
    "rust-v0.152.0" { "316795b3cf2a45e90d121d9f46499d4658b2645c" }
    default { Fail "missing trusted upstream commit for $codexTag" }
}

$runtimeRoot = Get-RuntimePackage $codexCommand
$installedDir = Join-Path $installRoot $codexVersion
$installedBinary = Join-Path $installedDir "bin\codex.exe"
if (-not $Force -and (Test-BinaryVersion $installedBinary $codexVersion)) {
    Copy-RuntimeSupport $runtimeRoot $installedDir
    Install-Launchers $installedBinary $binDir $installRoot
    & (Join-Path $binDir "codex-tips.cmd") --version
    exit $LASTEXITCODE
}

$upstream = if ($env:CODEX_TIPS_UPSTREAM) { $env:CODEX_TIPS_UPSTREAM } else { "https://github.com/openai/codex.git" }
$sourceRepo = Join-Path $cacheDir "upstream.git"
$targetDir = if ($env:CODEX_TIPS_TARGET_DIR) { $env:CODEX_TIPS_TARGET_DIR } else { Join-Path ([System.IO.Path]::GetTempPath()) "codex-tips-target-$codexVersion" }
New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
if (-not (Test-Path -LiteralPath $sourceRepo -PathType Container)) {
    & git init --bare $sourceRepo | Out-Null
    if ($LASTEXITCODE -ne 0) { Fail "failed to initialize source cache" }
    & git --git-dir=$sourceRepo remote add origin $upstream
} else {
    $currentUpstream = (& git --git-dir=$sourceRepo remote get-url origin 2>$null | Out-String).Trim()
    if ($currentUpstream -ne $upstream) { & git --git-dir=$sourceRepo remote set-url origin $upstream }
}
& git --git-dir=$sourceRepo config core.longpaths true
if ($LASTEXITCODE -ne 0) { Fail "failed to enable long source paths" }
& git --git-dir=$sourceRepo config core.autocrlf false
if ($LASTEXITCODE -ne 0) { Fail "failed to preserve upstream line endings" }
& git --git-dir=$sourceRepo show-ref --verify --quiet "refs/tags/$codexTag"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Fetching Codex source tag $codexTag..."
    & git --git-dir=$sourceRepo fetch --depth=1 origin "refs/tags/${codexTag}:refs/tags/$codexTag"
    if ($LASTEXITCODE -ne 0) { Fail "failed to fetch $codexTag" }
}
$actualCommit = (& git --git-dir=$sourceRepo rev-parse "$codexTag^{}" | Out-String).Trim()
if ($actualCommit -ne $expectedCommit) { Fail "upstream tag $codexTag resolved to untrusted commit $actualCommit" }

$checkoutRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("ct-" + [Guid]::NewGuid().ToString("N").Substring(0, 8))
$checkout = Join-Path $checkoutRoot "source"
New-Item -ItemType Directory -Path $checkoutRoot | Out-Null
try {
    & git --git-dir=$sourceRepo worktree add --detach $checkout $codexTag | Out-Null
    if ($LASTEXITCODE -ne 0) { Fail "failed to create source checkout" }
    & git -C $checkout apply --3way $patchFile
    if ($LASTEXITCODE -ne 0) { Fail "patch does not apply cleanly to $codexTag" }
    Write-Host "Building codex-tips $codexVersion..."
    $env:CARGO_TARGET_DIR = $targetDir
    $env:CARGO_INCREMENTAL = "0"
    & cargo build --manifest-path (Join-Path $checkout "codex-rs\Cargo.toml") -p codex-cli --release
    if ($LASTEXITCODE -ne 0) { Fail "cargo build failed" }
    $builtBinary = Join-Path $targetDir "release\codex.exe"
    if (-not (Test-BinaryVersion $builtBinary $codexVersion)) { Fail "built binary version does not match $codexVersion" }
    Copy-RuntimeSupport $runtimeRoot $installedDir
    Copy-Item -LiteralPath $builtBinary -Destination $installedBinary -Force
    Install-Launchers $installedBinary $binDir $installRoot
    & (Join-Path $binDir "codex-tips.cmd") --version
    if ($LASTEXITCODE -ne 0) { Fail "installed launcher failed" }
} finally {
    if (Test-Path -LiteralPath $checkout) {
        & git --git-dir=$sourceRepo worktree remove --force $checkout 2>$null | Out-Null
    }
    if (Test-Path -LiteralPath $checkoutRoot) { Remove-Item -LiteralPath $checkoutRoot -Recurse -Force }
}
