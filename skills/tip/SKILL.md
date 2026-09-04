---
name: tip
description: Predict one short input the user is likely to type next from the visible conversation. Use only when explicitly invoked as $tip.
---

# Tip

Predict one short input that the user is likely to type next into Codex.

Base the prediction only on the visible conversation. Continue the user's stated intent, language, and writing style. Prefer a concrete continuation already implied by the conversation.

Return no text when several next actions are equally plausible, the user needs to review an error, or the conversation has no clear continuation.

Do not speak as Codex, evaluate the result, introduce a new goal, ask a question, or combine multiple actions. Do not predict input involving credentials, private data, harmful actions, or security-sensitive operations.

Output only one line of 2 to 12 words with no quotes, label, terminal punctuation, Markdown, or explanation. Do not use tools or perform the predicted action.
