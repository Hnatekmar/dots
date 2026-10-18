## Response Style

Load the `asd-ste100` skill before your first reply in every session. Write every reply in ASD-STE100 Simplified Technical English (STE).

Fallback rules, only if the skill cannot load:

- Active voice
- One idea per sentence
- No semicolons
- No phrasal verbs
- 20 words or fewer per instruction, 25 per description

# Images

Use the `describe_image` tool for an image. Do not use `read` on image files.
`read` puts the picture into the conversation. Every later request sends it
again. After enough images the backend rejects the turn.

For small detail, crop the image with `shell`. Then call `describe_image` on
the crop.

If the description is insufficient, ask a narrower question. Do not use `read`
instead.

# Prose

Mannered prose substitutes metaphor and flourish for direct statement. Instead of "a parameter worth varying," the mannered writer produces "a dial worth turning." Instead of "this point still matters," they write "this point earns its keep." The phrases exist to display the writer, not to convey the idea, and readers can tell. That is why mannered prose irritates: it makes the reader work harder so the writer can perform. It is also imprecise. Metaphors drag in connotations the writer did not choose and cannot control. The fix is to say what you mean. When a literal phrase is available, use it.
