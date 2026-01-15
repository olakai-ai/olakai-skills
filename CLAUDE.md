# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Claude Code skills repository for the Olakai AI observability platform. It contains skills that follow the [Agent Skills Open Standard](https://agentskills.io) and work with Claude Code, Cursor, VS Code Copilot, and other compatible AI coding assistants.

**Purpose**: Provide guided workflows for integrating AI agents with Olakai monitoring, analytics, and governance.

## Repository Structure

```
olakai-skills/
├── marketplace.json              # Plugin marketplace manifest
├── skills/
│   ├── olakai-create-agent/     # Create new agents with monitoring
│   │   └── SKILL.md
│   ├── olakai-add-monitoring/   # Add monitoring to existing agents
│   │   └── SKILL.md
│   └── olakai-troubleshoot/     # Diagnose and fix monitoring issues
│       └── SKILL.md
└── docs/
    └── publishing-guide.md      # How to distribute skills
```

## Skills Overview

| Skill | When to Use |
|-------|-------------|
| `olakai-create-agent` | Building new AI features/agents from scratch with observability |
| `olakai-add-monitoring` | Adding Olakai to existing working AI code |
| `olakai-troubleshoot` | Events missing, KPIs showing strings/nulls, SDK errors |

## SKILL.md Format

Each skill uses YAML frontmatter + Markdown:

```yaml
---
name: skill-name
description: When Claude should use this skill
---

# Instructions body...
```

The `name` and `description` load at startup (~100 tokens). Full body loads only when skill is activated (progressive disclosure).

## Editing Skills

When modifying SKILL.md files:
- Keep under 500 lines (preserves Claude's context for actual work)
- Split large content into separate reference files in subdirectories
- Test by invoking the skill in Claude Code after changes

## Adding New Skills

1. Create directory under `skills/` with a `SKILL.md` file
2. Add entry to `marketplace.json`:
```json
{
  "name": "new-skill-name",
  "path": "skills/new-skill-name",
  "description": "What this skill does"
}
```

## Installation Methods

**Plugin Marketplace (recommended):**
```bash
/plugin marketplace add olakai/olakai-skills
/plugin install olakai-create-agent@olakai-skills
```

**Direct Git (user-level):**
```bash
git clone https://github.com/olakai/olakai-skills ~/.claude/skills/olakai-skills
```

**Project-level:**
```bash
git clone https://github.com/olakai/olakai-skills .claude/skills/olakai-skills
```

## The Golden Rule for All Skills

Every Olakai skill emphasizes the same validation pattern:

```bash
# 1. Run agent (generate event)
# 2. Fetch event
olakai activity list --agent-id AGENT_ID --limit 1 --json
olakai activity get EVENT_ID --json | jq '{customData, kpiData}'

# 3. Validate:
#    - customData has expected fields
#    - kpiData shows NUMBERS (not strings like "MyVariable")
#    - kpiData shows VALUES (not null)
```

This pattern should be preserved across all skills and is the foundation of Olakai integration validation.

## Key CLI Commands Referenced in Skills

```bash
# Authentication
olakai login
olakai whoami

# Agents
olakai agents list
olakai agents create --name "Name" --with-api-key --json
olakai agents get AGENT_ID --json | jq '.apiKey'

# Activity
olakai activity list --limit 10
olakai activity get EVENT_ID --json

# KPIs
olakai kpis list --agent-id ID
olakai kpis create --formula "Variable" --agent-id ID
olakai kpis validate --formula "Variable" --agent-id ID

# Custom Data
olakai custom-data list
olakai custom-data create --name "Field" --type NUMBER
```

## SDK Patterns Referenced in Skills

**TypeScript:**
```typescript
import { OlakaiSDK } from "@olakai/sdk";
const olakai = new OlakaiSDK({ apiKey: process.env.OLAKAI_API_KEY! });
await olakai.init();
const openai = olakai.wrap(new OpenAI({ apiKey }), { provider: "openai" });
```

**Python:**
```python
from olakaisdk import olakai_config, instrument_openai
olakai_config(os.getenv("OLAKAI_API_KEY"))
instrument_openai()
```

## Related Repositories

This skills repo is part of the Olakai ecosystem. See the workspace CLAUDE.md at `/Users/esteban/dev/olakai/CLAUDE.md` for the full repository map including:
- `localnode-app` - Main backend/frontend
- `olakai-sdk-typescript` - TypeScript SDK
- `olakai-sdk-python` - Python SDK
- `olakai-cli` - CLI tool
