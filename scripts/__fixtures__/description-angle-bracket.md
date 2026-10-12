---
name: fixture-angle-bracket
description: >
  Short description that names a <tool> placeholder in angle brackets, which
  the Agent Skills spec forbids in a description.
license: MIT
---
<!--
FIXTURE — NOT A SKILL. Never symlinked into plugins/, never installed.

Its description is well under the cap but contains `<` and `>`, which the
spec forbids. The gate must REJECT it for that reason, not for length.
-->
