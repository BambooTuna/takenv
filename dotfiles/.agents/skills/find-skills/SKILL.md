---
name: find-skills
description: Helps users discover and install agent skills when they ask questions like "how do I do X", "find a skill for X", "is there a skill that can...", or express interest in extending capabilities. This skill should be used when the user is looking for functionality that might exist as an installable skill.
---

# Find Skills

Discover and install skills from the open agent skills ecosystem via the Skills CLI (`npx skills`).

## When to Use

- "how do I do X" / "find a skill for X" / "is there a skill for X" / "can you do X"
- User wants to extend agent capabilities with a specialized tool, template, or workflow

## Skills CLI Commands

- `npx skills find [query] [--owner <owner>]` — search interactively or by keyword, optionally scoped to a GitHub owner
- `npx skills add <package>` — install a skill from GitHub or other sources
- `npx skills add <owner/repo@skill> -g -y` — `-g` installs globally (user-level), `-y` skips confirmation prompts
- `npx skills update` — update all installed skills
- `npx skills init <name>` — scaffold a new skill of your own
- Browse: https://skills.sh/

## Search Flow

1. Check the [skills.sh leaderboard](https://skills.sh/) first — it ranks by total installs. Top examples for web dev: `vercel-labs/agent-skills` (React/Next.js/web design, 100K+ installs), `anthropics/skills` (frontend design, document processing, 100K+ installs).
2. If the leaderboard doesn't cover the need, run `npx skills find [query] [--owner <owner>]`. Use specific keywords ("react performance" beats "testing" alone); try alternative terms if the first search misses (e.g. "deploy" → "deployment" or "ci-cd").
3. Other popular sources worth checking: `vercel-labs/agent-skills`, `ComposioHQ/awesome-claude-skills`.

## Verify Before Recommending (required)

Never recommend a skill from search results alone. Check:

1. **Install count** — prefer 1K+ installs; be cautious with anything under 100.
2. **Source reputation** — official sources (`vercel-labs`, `anthropics`, `microsoft`) over unknown authors.
3. **GitHub stars** — a source repo with <100 stars deserves skepticism.

## Presenting Results

Include: skill name + what it does, install count + source, the install command, and a link to skills.sh.

Example:

```
I found a skill that might help! The "react-best-practices" skill provides
React and Next.js performance optimization guidelines from Vercel Engineering.
(185K installs)

To install it:
npx skills add vercel-labs/agent-skills@react-best-practices

Learn more: https://skills.sh/vercel-labs/agent-skills/react-best-practices
```

## If No Skill Is Found

Acknowledge the gap and offer to help directly with general capabilities. If it's a recurring task, suggest `npx skills init my-xyz-skill` so the user can create their own.
