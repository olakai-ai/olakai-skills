---
name: fixture-more-indented
description: >
  A folded description whose middle line is more indented than the rest,
    so this line keeps its own line breaks,
  and then the fold resumes as normal.
license: MIT
---
<!--
FIXTURE — NOT A SKILL. Never symlinked into plugins/, never installed.

Its description exercises the folded-scalar MORE-INDENTED rule: the break
before and after an extra-indented line are preserved instead of folded to a
space. That is the most intricate branch in the parser and no fixture covered
it originally. Expected length is asserted exactly in the self-test.
-->
