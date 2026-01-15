# Olakai Skills for Claude Code

Official skills for integrating AI agents with [Olakai](https://olakai.ai) - the enterprise AI observability and governance platform.

These skills follow the [Agent Skills Open Standard](https://agentskills.io) and work with Claude Code, Cursor, VS Code Copilot, and other compatible AI coding assistants.

## Available Skills

| Skill | Description |
|-------|-------------|
| **olakai-create-agent** | Create a new AI agent with Olakai monitoring from scratch |
| **olakai-add-monitoring** | Add Olakai monitoring to an existing AI agent or LLM integration |
| **olakai-troubleshoot** | Troubleshoot monitoring issues - missing events, KPI problems, SDK errors |

## Installation

### Option 1: Claude Code Plugin Marketplace (Recommended)

```bash
# Add the Olakai skills marketplace
/plugin marketplace add olakai/olakai-skills

# Install individual skills
/plugin install olakai-create-agent@olakai-skills
/plugin install olakai-add-monitoring@olakai-skills
/plugin install olakai-troubleshoot@olakai-skills
```

### Option 2: Direct Git Installation (User-level)

Install for all your projects:

```bash
git clone https://github.com/olakai/olakai-skills ~/.claude/skills/olakai-skills
```

### Option 3: Project-level Installation

Install for a specific project (add to version control):

```bash
git clone https://github.com/olakai/olakai-skills .claude/skills/olakai-skills
```

### Option 4: Claude Desktop / claude.ai

Download the ZIP files from the [Releases](https://github.com/olakai/olakai-skills/releases) page and upload through **Settings > Capabilities > Skills**.

## Usage

Once installed, simply ask Claude to help with Olakai-related tasks:

- "Create a new AI agent with Olakai monitoring"
- "Add monitoring to my existing OpenAI integration"
- "My KPIs are showing string values instead of numbers"

Claude will automatically invoke the relevant skill.

## The Golden Rule: Test → Fetch → Validate

**Always validate your Olakai integration by generating a test event and inspecting it:**

```bash
# 1. Run your agent/trigger LLM call
# 2. Fetch the event
olakai activity list --agent-id AGENT_ID --limit 1 --json
olakai activity get EVENT_ID --json | jq '{customData, kpiData}'

# 3. Validate:
#    - customData has all expected fields
#    - kpiData shows NUMBERS (not strings like "MyVariable")
#    - kpiData shows VALUES (not null)
```

## Prerequisites

- [Olakai CLI](https://www.npmjs.com/package/olakai-cli): `npm install -g olakai-cli`
- Olakai account and API key

## Quick Reference

```bash
# CLI Authentication
olakai login
olakai whoami

# View Activity
olakai activity list --limit 10
olakai activity get EVENT_ID --json

# Manage Agents (includes API key generation)
olakai agents list
olakai agents create --name "Agent Name" --with-api-key --json
olakai agents get AGENT_ID --json | jq '.apiKey'

# Manage KPIs
olakai kpis list --agent-id ID
olakai kpis create --formula "Variable" --agent-id ID

# Manage Custom Data
olakai custom-data list
olakai custom-data create --name "Field" --type NUMBER
```

## SDK Quick Start

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

## Documentation

- [Olakai Documentation](https://app.olakai.ai/llms.txt)
- [TypeScript SDK](https://www.npmjs.com/package/@olakai/sdk)
- [Python SDK](https://pypi.org/project/olakai-sdk/)
- [CLI Reference](https://www.npmjs.com/package/olakai-cli)

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome! Please read our contributing guidelines before submitting PRs.

---

Built with ❤️ by [Olakai](https://olakai.ai)
