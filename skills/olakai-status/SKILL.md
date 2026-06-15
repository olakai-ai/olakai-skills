---
name: olakai
description: >
  Show your Olakai developer Coding IQ status — monitoring health, personal spend, and budget.

  AUTO-INVOKE when user asks about: their Olakai monitoring health, personal AI spend,
  budget status, Coding IQ digest, whether their workspace is monitored, how much
  they've spent on AI this month, whether they're approaching their budget limit,
  or wants a quick overview of their Olakai coding status.

  TRIGGER KEYWORDS: olakai status, my spend, my budget, coding iq status,
  am I monitored, monitoring health, personal spend, budget limit,
  how much have I spent, olakai digest, coding status, my olakai,
  workspace monitored, check my olakai.

  DO NOT load for: setting up monitoring (use olakai-monitor-local-coding-agent),
  troubleshooting events or KPIs (use olakai-troubleshoot),
  generating analytics reports (use olakai-reports),
  or creating new agents (use olakai-new-project).
license: MIT
metadata:
  author: olakai
  version: "1.16.0"
---

# Olakai Developer Status Digest

This skill fetches your Olakai Coding IQ status and formats it as a clean in-terminal digest — monitoring health, personal spend, and budget — without leaving Claude Code.

It can also surface your **Builder Profile** — your AI-collaboration archetype, six dimension scores, and personal ROI — via `olakai profile`. See the [Builder Profile](#builder-profile-olakai-profile) section below.

## Step 1: Check prerequisites

```bash
which olakai || echo "NOT_INSTALLED"
```

If the output is `NOT_INSTALLED`, tell the user:

> The Olakai CLI is not installed. Run `npm install -g olakai-cli` then try again.

Stop here if not installed.

## Step 2: Fetch status

```bash
olakai status --json 2>&1
```

Parse the output as JSON. The shape is:

```json
{
  "localMonitor": {
    "workspaces": [
      { "tool": "claude-code", "agentId": "...", "workspacePath": "...", "configured": true }
    ]
  },
  "backend": {
    "identity": { "found": true, "displayName": "alice@company.com", "identityCount": 2, "projectNames": ["Backend Services"] },
    "spend": { "mtdCents": 1208, "providers": [...], "forecastMonthEndCents": 4030, "forecastConfidence": "high" },
    "budget": { "found": true, "monthlyLimitCents": 5000, "alertThresholds": [80, 100], "usagePct": 24.2, "status": "ok", "forecastPct": 80.6 },
    "monitoring": { "agentCount": 2, "recentSessionCount": 14, "lastActivityAt": "2026-06-09T12:00:00Z" }
  },
  "backendError": null
}
```

`backendError` is one of: `null`, `"not logged in"`, `"session expired"`, `"unreachable"`, or another error string.

## Step 3: Format as a markdown digest

Use today's month and year in the heading (e.g., `## Olakai Status — June 2026`).

**Helper — formatting cents:** divide by 100, show two decimal places. Examples:
- `1208 cents` → `$12.08`
- `5000 cents` → `$50.00`
- `0 cents` → `$0.00`

**Helper — formatting a timestamp as relative time:**
- < 1 hour ago → "X minutes ago"
- 1–23 hours ago → "X hours ago"
- ≥ 24 hours ago → the date string

### Monitoring section (always shown)

```markdown
### Monitoring
- <tool display name>: ✓ configured (`<workspacePath>`)
- Last activity: <relative time> — <recentSessionCount> sessions this month
```

- Repeat a line for each workspace in `localMonitor.workspaces`.
- If `localMonitor.workspaces` is empty, show:
  ```markdown
  ### Monitoring
  - This workspace is not monitored.
  ```
- `tool` display names: `claude-code` → "Claude Code", `codex` → "Codex CLI", `cursor` → "Cursor"
- If `backend.monitoring` is null (offline) or `backend` is null, omit the "Last activity" line.

### Personal Spend section (show only if `backend.identity.found = true`)

```markdown
### Personal Spend (<Month> MTD)
- Est. cost: **$<mtdCents formatted>**
- Forecast: ~$<forecastMonthEndCents formatted> by month-end *(<forecastConfidence> confidence)*
- Providers: <Provider 1> $<amount> · <Provider 2> $<amount>
```

- Omit the Forecast line if `forecastMonthEndCents` is null.
- Replace `forecastConfidence` label: `"high"` → "high", `"medium"` → "medium", `"low"` → "low", `"insufficient_data"` → omit the entire forecast line and note it in Action Items.
- Format each provider name with title case. Sort providers by spend descending.

### Budget section (show only if `backend.budget.found = true`)

```markdown
### Budget
- Limit: $<monthlyLimitCents formatted>/month
- Used: <usagePct>% ($<mtdCents formatted> of $<monthlyLimitCents formatted>)
- Forecast: <forecastPct>% by month-end <status indicator>
```

Status indicators:
- `status = "ok"` and `forecastPct < 80` → no indicator
- `status = "ok"` and `forecastPct >= 80` → `⚠️ (approaching limit)`
- `status = "warning"` → `⚠️ (approaching limit)`
- `status = "exceeded"` → `🚨 (limit exceeded)`

Omit the Forecast line if `forecastMonthEndCents` is null.

### Identity section (show only if `backend.identity.found = true`)

```markdown
### Identity
- Recognized as: <displayName> (<identityCount> identities)
- Projects: <projectNames joined by ", ">
```

Omit the Projects line if `projectNames` is empty.

---

## Step 4: Surface action items

Collect all applicable items and append an `### Action Items` section at the end. Omit the section entirely if there are no items.

| Condition | Action Item |
|-----------|-------------|
| `localMonitor.workspaces` is empty | `[ ] This workspace is not monitored. Run \`olakai monitor init\` to set it up.` |
| `backendError = "not logged in"` | `[ ] Log in with \`olakai login\` to see your personal spend and budget.` |
| `backendError = "session expired"` | `[ ] Your session has expired. Run \`olakai login\` to refresh.` |
| `backendError = "unreachable"` | `[ ] Could not reach the Olakai backend. Local monitoring is still active. Check your network or try again later.` |
| `backend.identity.found = false` (and no backendError) | `[ ] You are not yet recognized in Olakai Coding IQ. Your first session needs to be processed — this usually takes a few minutes after your first monitored session.` |
| `backend.budget.status = "warning"` | `[ ] Your spend is approaching your budget limit ($<limit>). Forecast: <forecastPct>% by month-end. Contact your admin if you need a higher limit.` |
| `backend.budget.status = "exceeded"` | `[ ] Your budget limit ($<limit>) has been exceeded. Contact your admin to request an increase.` |
| `backend.spend.forecastConfidence = "insufficient_data"` | `[ ] Forecast not available yet — less than 5 days of spend data. Check back later.` |

---

## Full example output

```markdown
## Olakai Status — June 2026

### Monitoring
- Claude Code: ✓ configured (`/Users/alice/dev/my-project`)
- Last activity: 2 hours ago — 14 sessions this month

### Personal Spend (June MTD)
- Est. cost: **$12.08**
- Forecast: ~$40.30 by month-end *(high confidence)*
- Providers: Anthropic $10.20 · Cursor $1.88

### Budget
- Limit: $50.00/month
- Used: 24.2% ($12.08 of $50.00)
- Forecast: 80.6% by month-end ⚠️ (approaching limit)

### Identity
- Recognized as: alice@company.com (2 identities)
- Projects: Backend Services

### Action Items
- [ ] Your forecast (80.6%) is approaching your budget limit ($50.00). Contact your admin if you need a higher limit.
```

---

## Builder Profile (`olakai profile`)

When the user asks about their **Builder Profile**, their **archetype**, their AI-collaboration **dimension scores**, or their **personal ROI / leaked spend** (as opposed to the spend/budget snapshot above), use `olakai profile` instead of `olakai status`.

Requires `olakai-cli >= 0.10.0`.

### Step 1: Fetch the profile

```bash
olakai profile --json 2>&1
```

Parse the output as JSON. The shape is:

```json
{
  "backend": {
    "found": true,
    "reason": "ok",
    "profile": {
      "identity": { "found": true, "displayName": "Walt Mann" },
      "episodeCount": 5,
      "dimensions": {
        "delegation":       { "meanScore": 6.2, "evidenceCount": 5 },
        "direction":        { "meanScore": 6.8, "evidenceCount": 5 },
        "verification":     { "meanScore": 7.6, "evidenceCount": 5 },
        "product_judgment": { "meanScore": 6.4, "evidenceCount": 5 },
        "preparation":      { "meanScore": 4.2, "evidenceCount": 5 },
        "spend_efficiency": { "meanScore": 4.8, "evidenceCount": 5 }
      },
      "archetype": {
        "dominant":  { "dimension": "verification", "archetype": "The Inspector", "meanScore": 7.6, "evidenceCount": 5 },
        "secondary": null
      },
      "growthEdge": {
        "dimension": "preparation", "archetype": "The Architect", "meanScore": 4.2, "evidenceCount": 5,
        "citedRationale": "...", "suggestedPatternKey": "plan_before_build"
      },
      "roi": {
        "personalSpendCents": 74210,
        "costPerCommitCents": null,
        "outcomeDataAvailable": false,
        "leakedSpendCents": 2948,
        "secretsIncidentCount": 0,
        "roiMultiplier": null,
        "spendEfficiency": { "score": 7, "rationale": "4% leak rate; 0% over-provisioned spend" }
      },
      "reducedFidelity": false,
      "narrative": { "archetypeNarrative": "...", "growthEdgeNarrative": "..." },
      "narrativeUnavailable": false
    }
  },
  "backendError": null
}
```

`backendError` is one of: `null`, `"not logged in"`, `"session expired"`, `"unreachable"`.

### Step 2: The honesty contract (do NOT break this)

The backend deliberately returns `null` for any value it cannot ground in evidence. **Never invent a number to fill a gap.** Specifically:

| Field | When `null` / empty | What to render |
|-------|---------------------|----------------|
| `dimensions.<key>.meanScore` is `null`, missing, or `evidenceCount = 0` | dimension has no evidence | "no evidence yet" — **never** a middle score like 5/10 |
| `roi.costPerCommitCents` is `null` | no shipped-outcome data | "insufficient outcome data" — **never** "$0" |
| `roi.roiMultiplier` is `null` | outcomes not measurable | "insufficient outcome data" — **never** "100%" or "1x" |
| `roi.leakedSpendCents` is `null` | not computed | "—" |
| `roi.leakedSpendCents = 0` | computed, no leak | "none detected" |
| `profile.narrativeUnavailable = true` | narrative generation failed | omit the narrative lines; fall back to `growthEdge.citedRationale` only |

This honesty is the whole point of the feature — a fabricated profile is worse than an honest "not enough data yet."

### Step 3: Format as a markdown digest

```markdown
## Your Builder Profile

**<archetype.dominant.archetype>** — <meanScore>/10 across <evidenceCount> episodes
<if secondary present:> Secondary strength: <archetype.secondary.archetype> (<meanScore>/10)

### Dimensions
| Dimension | Score |
|-----------|-------|
| Delegation | <score>/10 or "no evidence yet" |
| Direction | ... |
| Verification | ... |
| Product Judgment | ... |
| Preparation | ... |
| Spend Efficiency | ... |

### Personal ROI (this month)
- AI spend: **$<personalSpendCents formatted>**
- Cost per commit: $<costPerCommitCents formatted> *or* "insufficient outcome data"
- Top leak: $<leakedSpendCents formatted> leaked (<spendEfficiency.rationale>) *or* "none detected"
- ROI: <roiMultiplier>x *or* "insufficient outcome data"

### Growth Edge
**<growthEdge.archetype>** (<meanScore>/10)
<narrative.growthEdgeNarrative, or growthEdge.citedRationale if narrative unavailable>
Suggested practice: <growthEdge.suggestedPatternKey>
```

- Dimension display order: Delegation, Direction, Verification, Product Judgment, Preparation, Spend Efficiency.
- Format cents the same way as the status digest (divide by 100, two decimals).
- If `roi.secretsIncidentCount > 0`, add a ⚠️ line: "<n> secrets incident(s) this month."
- Close with a link to the full report (the CLI prints `reportUrl` in `--json`).

### Graceful no-profile

If `backend.found = false`, `backend.profile = null`, or a `backendError` is present, show ONE friendly line and stop — never a stack trace, never a fabricated profile:

| Condition | Message |
|-----------|---------|
| `backendError = "not logged in"` | Log in with `olakai login` to see your Builder Profile. |
| `backendError = "session expired"` | Session expired — run `olakai login` to refresh. |
| `backendError = "unreachable"` | Could not reach Olakai; try again when you're back online. |
| `reason = "opted_out"` | Your Builder Profile is turned off; re-enable it in Olakai settings. |
| `reason = "insufficient_data"` (or any other not-found) | Not enough coding sessions yet — your profile appears after your first few analyzed sessions. |

The CLI's human output (`olakai profile`, no `--json`) already renders all of this correctly; prefer `--json` only when you want to reformat into the conversation.

---

## Graceful degradation

| Situation | What to show |
|-----------|--------------|
| `backend = null` or `backendError` present | Show Monitoring section, skip Spend/Budget/Identity, put the error in Action Items |
| `budget.found = false` | Skip Budget section entirely |
| `identity.found = false` | Skip Personal Spend and Identity sections; add Action Item |
| `forecastMonthEndCents = null` | Omit Forecast line from both Spend and Budget |
| `localMonitor.workspaces` is empty | Show "not monitored" message; add Action Item |
| CLI command fails (non-JSON output) | Show the raw error and suggest `olakai login` or `olakai whoami` |
