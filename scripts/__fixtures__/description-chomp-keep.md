---
name: fixture-chomp-keep
description: |+
  Literal block with keep chomping, so every trailing newline counts too. Literal block with keep chomping, so every trailing new
  Literal block with keep chomping, so every trailing newline counts too. Literal block with keep chomping, so every trailing new
  Literal block with keep chomping, so every trailing newline counts too. Literal block with keep chomping, so every trailing new
  Literal block with keep chomping, so every trailing newline counts too. Literal block with keep chomping, so every trailing new
  Literal block with keep chomping, so every trailing newline counts too. Literal block with keep chomping, so every trailing new
  Literal block with keep chomping, so every trailing newline counts too. Literal block with keep chomping, so every trailing ne
  Literal block with keep chomping, so every trailing newline counts too. Literal block with keep chomping, so every trailing ne
  Literal block with keep chomping, so every trailing newline counts too. Literal block with keep chomping, so every trailing ne



license: MIT
---
<!--
FIXTURE — NOT A SKILL. Never symlinked into plugins/, never installed.

Its description is a LITERAL block with KEEP chomping (`|+`) and three
trailing blank lines, so its value is exactly 1024 characters only if those
newlines are counted. Measured as clip it comes out at 1021 — which is how
the bug this fixture pins went unnoticed: no skill uses `+`, so nothing
exercised it.
-->
