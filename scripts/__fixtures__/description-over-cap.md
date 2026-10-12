---
name: fixture-over-cap
description: |
  One character over the spec cap, literal so every newline is preserved as it. One character over the spec cap, literal so every 
  One character over the spec cap, literal so every newline is preserved as it. One character over the spec cap, literal so every
  One character over the spec cap, literal so every newline is preserved as it. One character over the spec cap, literal so every
  One character over the spec cap, literal so every newline is preserved as it. One character over the spec cap, literal so every
  One character over the spec cap, literal so every newline is preserved as it. One character over the spec cap, literal so every
  One character over the spec cap, literal so every newline is preserved as it. One character over the spec cap, literal so every
  One character over the spec cap, literal so every newline is preserved as it. One character over the spec cap, literal so every
  One character over the spec cap, literal so every newline is preserved as it. One character over the spec cap, literal so every
license: MIT
---
<!--
FIXTURE — NOT A SKILL. Never symlinked into plugins/, never installed.

Its description is EXACTLY 1025 characters, literal (`|`). The gate must
REJECT it, reporting 1025. Paired with description-at-cap.md it straddles the
boundary by one character, and it proves `|` is measured as a literal: folding
it to `>` would turn the newlines into spaces and change the length.
-->
