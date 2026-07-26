# Graphiti Memory

I have access to a temporal knowledge graph at graphity.personal-hermes.hnatekmar.dev
via the `graphiti` MCP server. Use it for cross-session memory.

## When to store
- Architectural decisions → `add_memory`
- Library/stack choices → `add_memory`
- User preferences about code style → `add_memory`
- Bug root causes and fixes → `add_memory`

## When to retrieve
- Start of session → `search_memory_facts` for current project context
- Before making tech choices → check memory for prior decisions
- When investigating issues → search for related history
