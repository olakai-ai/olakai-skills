# How to bundle, package, and distribute Claude Code skills

**Claude Code skills can be distributed through multiple channels**: GitHub repositories registered as plugin marketplaces, npm-based installers, direct directory installation, and embedded within subagent configurations. The most robust approach combines packaging skills as a GitHub repository, registering it as a plugin marketplace, and optionally bundling skills within custom subagents for specialized workflows. All methods leverage the same **SKILL.md format**, which is language-agnostic and now part of an open standard adopted across multiple AI coding tools.

---

## The SKILL.md format is the foundation

Every Claude Code skill requires exactly one file: **SKILL.md**. This file uses YAML frontmatter followed by Markdown instructions:

```yaml
---
name: my-skill-name
description: Clear description of what this skill does and when Claude should use it
allowed-tools: Read, Grep, Glob
---

# My Skill Name

[Instructions Claude will follow when this skill is active]
```

The `name` and `description` fields are loaded into Claude's context at startup (~100 tokens), while the full Markdown body loads only when Claude determines the skill is relevant—a design called **progressive disclosure** that minimizes context bloat.

Skills can include additional files organized in subdirectories:

```
.claude/skills/code-review/
├── SKILL.md              # Required: overview and workflows
├── scripts/              # Executable code Claude can run
│   └── run-linters.sh
├── references/           # Documentation loaded as needed
│   └── SECURITY.md
└── assets/               # Templates, images, data files
```

This structure is now part of the **Agent Skills Open Standard** at agentskills.io, adopted by Microsoft, OpenAI, Cursor, VS Code Copilot, GitHub, and others—meaning skills you create for Claude Code can work across multiple AI coding assistants.

---

## Four distribution mechanisms ranked by reliability

**1. Plugin Marketplaces (recommended for third-party distribution)**

The official Claude Code plugin system transforms any GitHub repository into an installable skill source. Clients install skills with two commands:

```bash
/plugin marketplace add your-org/skills-repo
/plugin install skill-name@your-org-skills-repo
```

Your repository needs a `marketplace.json` file at the root:

```json
{
  "name": "your-org-skills",
  "description": "Collection of productivity skills",
  "plugins": [
    {
      "name": "code-review",
      "path": "skills/code-review",
      "description": "Automated code review workflows"
    }
  ]
}
```

**2. NPM-based installers (best for cross-platform compatibility)**

Several community tools enable `npx` installation:

- `npx ai-agent-skills install <skill-name>` — installs to Claude Code, Cursor, VS Code, and Amp
- `npx openskills install <skill>` — universal agent skills installer  
- `npx skild install <skill>` — npm-style package manager for skills

These tools automatically detect the correct installation directory for each platform.

**3. Direct Git repository distribution**

Clients can clone your repository directly:

```bash
git clone https://github.com/your-org/skills-repo ~/.claude/skills/your-skills
```

Or for project-level installation:

```bash
git clone https://github.com/your-org/skills-repo .claude/skills/your-skills
```

**4. ZIP upload for Claude Desktop/Web**

Non-CLI users can install skills by packaging the skill folder as a ZIP file and uploading through **Settings > Capabilities > Skills** in Claude Desktop or claude.ai.

---

## Installation locations determine skill scope

Claude Code discovers skills from four locations with strict priority (highest first):

| Location | Scope | Use Case |
|----------|-------|----------|
| `managed-settings.json` | Enterprise | IT-deployed skills for organizations |
| `~/.claude/skills/` | User (personal) | Skills available across all projects |
| `.claude/skills/` | Project | Team skills committed to version control |
| Plugin marketplace | Plugin | Third-party installable skills |

For third-party distribution, **project-level installation via `.claude/skills/`** is most practical—clients can commit skills to their repository and share them with their team automatically. User-level installation at `~/.claude/skills/` works for personal productivity tools.

When skills share the same name, higher-priority locations override lower ones, allowing enterprises to enforce specific skill versions.

---

## Subagents provide skill bundling for specialized workflows

Subagents are custom agents that run in isolated contexts with their own system prompts and tool permissions. They can bundle multiple skills together using the `skills` field:

```markdown
# .claude/agents/code-reviewer.md
---
name: code-reviewer
description: Review code for quality and security best practices
skills: pr-review, security-check, testing-patterns
tools: Read, Grep, Glob, Bash
model: inherit
---

You are a senior code reviewer focused on identifying bugs, security issues, and performance problems.
```

When this subagent activates, **all listed skills are injected into its context at startup**, creating a specialized agent with bundled expertise.

Subagent files live in these locations:

| Location | Scope |
|----------|-------|
| `.claude/agents/` | Project-specific (version controlled) |
| `~/.claude/agents/` | User-wide |
| Via `--agents` flag | Session-only |

To distribute a bundled subagent with its skills, package them together:

```
your-distribution/
├── agents/
│   └── code-reviewer.md
├── skills/
│   ├── pr-review/SKILL.md
│   ├── security-check/SKILL.md
│   └── testing-patterns/SKILL.md
└── README.md
```

Clients copy both directories to their `.claude/` folder, and the subagent automatically finds its bundled skills.

---

## Configuration files control the installation process

**settings.json hierarchy** (priority order):

1. `/Library/Application Support/ClaudeCode/managed-settings.json` (macOS enterprise)
2. `.claude/settings.local.json` (project, gitignored)
3. `.claude/settings.json` (project, version controlled)
4. `~/.claude/settings.json` (user global)

To automate skill installation for teams, add marketplace sources to `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "team-skills": {
      "source": {
        "source": "github",
        "repo": "your-org/claude-skills"
      }
    }
  },
  "enabledPlugins": {
    "code-review@team-skills": true,
    "security-scan@team-skills": true
  }
}
```

**CLAUDE.md files** provide project context and can reference skills:

```markdown
# CLAUDE.md

This project uses our standard code review skill.
@.claude/skills/code-review/SKILL.md

## Build Commands
- `npm run test` - Run tests
- `npm run lint` - Check code style
```

**MCP configuration** (`.mcp.json`) adds external tool integrations that skills can reference:

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://mcp.github.com"
    }
  }
}
```

Skills can then restrict themselves to specific MCP tools using `allowed-tools: mcp__github__create_pr`.

---

## Best practices for third-party skill distribution

**Package structure for maximum compatibility:**

```
your-skills/
├── marketplace.json          # Plugin marketplace manifest
├── skills/
│   ├── skill-one/
│   │   ├── SKILL.md
│   │   └── scripts/
│   └── skill-two/
│       └── SKILL.md
├── agents/                   # Optional bundled subagents
│   └── specialized-agent.md
└── README.md                 # Installation instructions
```

**Security considerations are critical.** Anthropic warns: *"We strongly recommend using Skills only from trusted sources: those you created yourself or obtained from Anthropic."* Skills can direct Claude to execute arbitrary code, so document your skills thoroughly and encourage code review before installation.

**Keep skills focused.** The official guidance recommends keeping SKILL.md under **500 lines** and splitting larger content into separate reference files. This preserves Claude's context for actual work rather than instruction loading.

---

## Conclusion

The most effective distribution strategy combines **GitHub-based plugin marketplaces** for discoverability with **project-level installation** (`.claude/skills/`) for team sharing. For complex use cases requiring multiple skills to work together, **subagents with the `skills` field** provide clean bundling. The Agent Skills Open Standard means your investment in SKILL.md files pays dividends across Claude Code, Cursor, VS Code Copilot, and other adopting platforms—truly language-agnostic distribution that works regardless of your clients' tech stacks.