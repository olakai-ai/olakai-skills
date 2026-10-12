---
name: fixture-escaped-dollar
description: >
  Fixture for the argument-substitution gate. Not a skill.
license: MIT
---
<!--
FIXTURE — NOT A SKILL. Never symlinked into plugins/, never installed.

The companion to unescaped-dollar-digit.md: every line here is already SAFE
and the gate must stay silent on all of it. Without this file the obvious way
to make the gate "work" is to broaden the pattern until it flags the corrected
skills too, and nothing would catch that.
-->

Escaped amounts: \$0, \$0.00, \$55/hour, \$200/developer/month, \$114,400/yr.

Escaped inside a code span: `\$5,000` is the limit.

Escaped in a fenced block:

```
cost: \$16,059
```

Non-digit dollars are not positional arguments: $AGENT_ID, $WORKSPACE, $ARGUMENTS.

A lone dollar with a space is also safe: $ 50.
