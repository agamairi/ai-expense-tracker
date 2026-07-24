---
title: Project Rules
type: rule
author: Antigravity
tags: [rules, git, flutter]
---

# Project Rules

## Git Branching
- `main`: Production releases ONLY.
- `development`: Primary integration branch. All work merges into `development`.
- `feature/*`: Cut from `development` for individual tasks.

## Code Quality
- Clean Architecture (Data, Domain, Presentation).
- MVVM design pattern.
- Solid Principles: strict interface segregation.
- No direct database connections outside the Data layer.

## UI Guidelines
- Material 3 Expressive: Dynamic color, spring physics, dynamic morphing shapes, fluid containers.
- Wealthsimple-style rich interface.
