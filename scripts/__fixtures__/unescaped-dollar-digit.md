---
name: fixture-unescaped-dollar
description: >
  Fixture for the argument-substitution gate. Not a skill.
license: MIT
---
<!--
FIXTURE — NOT A SKILL. Never symlinked into plugins/, never installed.

Every line below is a spelling the gate must REJECT, including the two that
look safe and are not: an inline code span and a fenced code block. Both are
substituted at invoke time exactly like bare prose, which is the result a
reviewer is most likely to assume otherwise.
-->

Bare prose: a budget of $0 means no spend allowed.

Inline code span: `$0` is a real limit.

Table row: | "Engineering has a $0 budget" | wrong |

Fenced block:

```
cost: $5,000
```
