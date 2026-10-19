---
name: fixture-kpis-create-no-scope
description: >
  Fixture for the CLI-example gate. Not a skill.
license: MIT
---
<!--
FIXTURE — NOT A SKILL. Never symlinked into plugins/, never installed.

Four commands the gate must REJECT and three it must ACCEPT. The multi-line
cases are the point: a reviewer scanning a diff sees `--calculator-id formula \`
and cannot tell from that line whether --scope follows, which is how 13 broken
examples shipped. The DUPLICATE case is here because a blanket regex sweep
added a second --scope to the one file that was already correct. The two
trailing-comment cases are here because a comment that MENTIONS --scope is not
the flag: it must neither count as a duplicate nor hide a missing one.
-->

Reject — single line, no scope:

```bash
olakai kpis create --name "A" --calculator-id formula --formula "1" --agent-id ID
```

Reject — multi-line, no scope:

```bash
olakai kpis create \
  --name "B" \
  --calculator-id formula \
  --formula "2" \
  --agent-id ID
```

Reject — multi-line with two scopes:

```bash
olakai kpis create \
  --name "C" \
  --scope PROMPT_REQUEST \
  --calculator-id formula \
  --scope CHAT \
  --agent-id ID
```

Accept — single line with a scope:

```bash
olakai kpis create --name "D" --formula "3" --scope PROMPT_REQUEST --agent-id ID
```

Accept — multi-line with a scope on a continuation:

```bash
olakai kpis create \
  --name "E" \
  --calculator-id classifier --template-id time_saved_estimator \
  --scope CHAT --agent-id ID
```

Accept — a trailing comment that mentions the flag is not a second flag:

```bash
olakai kpis create --name "F" --formula "4" --scope PROMPT_REQUEST --agent-id ID  # Create KPI (--scope is required)
```

Reject — a comment that mentions the flag does not stand in for it:

```bash
olakai kpis create --name "G" --formula "5" --agent-id ID  # --scope is required
```
