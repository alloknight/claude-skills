# My Claude Skills

A repository of custom workflows, agents, and prompts.

## Install

```bash
./install.sh              # symlink every skill into ~/.claude/skills
./install.sh --dry-run    # preview changes
./install.sh --uninstall  # remove only the links pointing into this repo
```

Skills are symlinked rather than copied, so this repo stays the single source of
truth — a `git pull` or a local edit takes effect immediately, with no reinstall.
The script is idempotent, refuses to clobber a real directory in
`~/.claude/skills`, and prunes links whose source has been removed. Multi-skill
bundles like `superpowers` are expanded so each of their skills is linked
individually. Restart Claude Code or start a new session to pick up changes.

## Skills Inventory
<!-- CLAUDE: ADD NEW SKILLS DIRECTLY BELOW THIS LINE -->

* **[build-premium-website](./skills/build-premium-website/SKILL.md)** — Builds a premium, animated single-page marketing website adapted to any industry, starting from a mandatory intake interview covering brand, tone, services, and contact details. Use it when you want a high-end company site or landing page rather than a generic template.
  * **Stack/Tools:** React 19, Vite, Tailwind CSS, GSAP, Unsplash imagery, `AskUserQuestion` for intake. Bundles a complete working reference implementation under `reference/` (app JSX, CSS, HTML, Tailwind config, plus design-system, animation, and industry-theme guides).
* **[composio](./skills/composio/SKILL.md)** — Connects AI agents to 1000+ third-party apps (GitHub, Gmail, Slack, Notion, Salesforce) through Composio, covering toolkits, OAuth auth configs, connected accounts, event triggers, and MCP. Use it when an agent needs to actually act in someone else's SaaS rather than just talk about it.
  * **Stack/Tools:** Composio Python and TypeScript SDKs, Anthropic SDK, MCP. Requires `COMPOSIO_API_KEY` and `ANTHROPIC_API_KEY`. Reference docs: `sdk-reference.md` (sessions, tools, executing actions) and `auth-and-triggers.md` (OAuth/API-key flows, webhooks, polling). Note that Composio is a hosted service that takes custody of your users' OAuth tokens.
* **[cost-reducer](./skills/cost-reducer/SKILL.md)** — Cuts cloud and operational spend without giving up performance, ranked by a cost-impact hierarchy that puts architecture and data-transfer routing ahead of the bundle-size tweaks people usually reach for first. Use it when sizing infrastructure, choosing between services, or reviewing code for cost waste.
  * **Stack/Tools:** Prompt-only. Three reference docs: `code-level-savings.md` (bundles, image pipelines, query cost, caching ROI), `cloud-and-infra.md` (right-sizing, serverless tuning, storage tiers, egress traps, CI/CD), `services-and-finops.md` (pricing comparisons, observability cost control, unit economics). Contains AWS/GCP/Vercel pricing figures that are a point-in-time snapshot — treat them as orders of magnitude, not quotes.
* **[create-skill](./skills/create-skill/SKILL.md)** — Authors new Claude Code skills and slash commands, working through skill type (task / research / knowledge / dynamic), scope, and frontmatter before any writing starts. Use it when adding a skill to this repo, since it treats the `description` field as an auto-activation trigger rather than documentation.
  * **Stack/Tools:** Prompt-only. Includes `reference.md` (full frontmatter fields, variables, shell injection, invocation control, permissions) and `examples.md` (worked examples of all four skill types). Overlaps deliberately with superpowers' `writing-skills`, which emphasizes subagent testing instead.
* **[customer-support](./skills/customer-support/SKILL.md)** — Handles support work as a senior specialist: drafting replies, triaging tickets, writing help articles, and reviewing conversations for quality. Use it when you need an empathetic, scannable response that owns the problem and closes with a concrete next step.
  * **Stack/Tools:** Prompt-only (drafts text, no helpdesk API integration). Includes `response-templates.md` for refunds/bugs/outages/billing and `escalation-guide.md` for routing, SLAs, and handoffs.
* **[frontend-design](./skills/frontend-design/SKILL.md)** *(third-party, license unconfirmed)* — Pushes frontend work toward a bold, committed aesthetic direction instead of the default generic AI look, with hard rules on typography, color, motion, and spatial composition. Use it when building any component, page, or interface that needs to feel genuinely designed.
  * **Stack/Tools:** Prompt-only and framework-agnostic (HTML/CSS/JS, React, Vue). See [`PROVENANCE.md`](./skills/frontend-design/PROVENANCE.md) — it references a `LICENSE.txt` that was missing from the source copy.
* **[know-me](./skills/know-me/SKILL.md)** *(auto-activating — read the compatibility note first)* — Learns about you across sessions by watching for stated preferences, corrections, and repeated choices, then saves them to memory topic files and recalls them before responding. Use it when you want continuity between sessions instead of re-explaining context every time.
  * **Stack/Tools:** Prompt-only, writes plain markdown to `~/.claude/projects/<project>/know-me/`. Includes `what-to-track.md` (signal taxonomy) and `memory-operations.md` (store/organize/update/recall). **Modified from source** — the write path was retargeted off Claude Code's built-in memory directory to avoid a layout collision; see [`COMPATIBILITY.md`](./skills/know-me/COMPATIBILITY.md), which also notes that it sets `auto-activate: true`.
* **[n8n](./skills/n8n/SKILL.md)** — Builds n8n workflow automations, custom TypeScript nodes, and integrations, including the raw workflow JSON schema so files can be authored or patched directly instead of clicked together in the UI. Use it when creating workflows, writing n8n expressions, configuring triggers, or driving n8n's REST API.
  * **Stack/Tools:** n8n (Docker or npm), TypeScript, `n8n-workflow`. Three reference docs: `workflow-reference.md` (triggers, flow control, error handling, expressions), `custom-nodes-reference.md` (declarative vs programmatic nodes, credentials, testing), `api-reference.md` (workflow management, execution control).
* **[scalability](./skills/scalability/SKILL.md)** — Diagnoses and fixes growth bottlenecks via a decision tree that routes from "slow response times" to the actual culprit (database, external calls, or CPU) before any optimizing happens. Use it when writing queries, caching, queues, or background jobs, or when reviewing code for performance problems.
  * **Stack/Tools:** Prompt-only, vendor-neutral reference material. Four reference docs: `database-scaling.md` (indexing, pooling, replicas, sharding, N+1), `caching-and-queues.md` (Redis, invalidation, message queues, event-driven), `api-and-services.md` (pagination, rate limiting, circuit breakers, load balancing), `infrastructure.md` (Kubernetes autoscaling, serverless, CDN, observability).
* **[security](./skills/security/SKILL.md)** — Applies a security-first lens when writing or reviewing auth, API endpoints, queries, file uploads, IPC handlers, and crypto, organized around attacker-controlled input and blast radius. Use it while building anything that handles untrusted data, or to review existing code for real exploits rather than theater.
  * **Stack/Tools:** Prompt-only reference material (no scanners invoked). Four reference docs: `web-security.md` (OWASP Top 10, XSS/CSRF/SSRF/injection, headers), `auth-and-secrets.md` (JWT, OAuth2 PKCE, password hashing, secrets), `desktop-security.md` (Electron/Tauri hardening, IPC, auto-updater), `database-and-deps.md` (SQLi, ORM safety, supply chain).
* **[single-file-business-site](./skills/single-file-business-site/SKILL.md)** — Turns a Google Maps URL, business website, or plain description into one self-contained HTML landing page with real business data and verified Unsplash photography. Use it for fast client or prospect demos where a build step would be overkill.
  * **Stack/Tools:** Vanilla HTML/CSS/JS with GSAP, Lenis smooth scroll, and Swiper; `WebFetch` for business research, Unsplash for imagery. Output is a single `index.html` that auto-opens in the browser.
* **[trigger-dev](./skills/trigger-dev/SKILL.md)** — Builds Trigger.dev v4 background jobs and workflows in TypeScript: queued processing, cron schedules, retries, idempotency, and AI agent orchestration. Use it for any work that needs to outlive an HTTP request.
  * **Stack/Tools:** Trigger.dev v4 (`@trigger.dev/sdk`), TypeScript, Zod for `schemaTask` payload validation. Three reference docs: `core-reference.md` (tasks, queues, concurrency, retries, waits), `config-reference.md` (`trigger.config.ts`, deployment, CLI, monorepos), `advanced-reference.md` (AI integration, streams, realtime, lifecycle hooks). Optionally uses the Trigger.dev MCP server for live docs lookup.
* **[superpowers](./skills/superpowers/README.md)** *(vendored, third-party)* — A 14-skill engineering-workflow library covering brainstorming, plan writing and execution, TDD, systematic debugging, code review (both directions), git worktrees, subagent orchestration, and verification before claiming completion. Use it to impose a disciplined process on feature work instead of improvising.
  * **Stack/Tools:** Prompt-driven skills plus per-skill helper scripts (Node, shell). Vendored from [obra/superpowers](https://github.com/obra/superpowers) v6.2.0 (commit `3dcbd5c`), MIT licensed, © 2025 Jesse Vincent. Skills tree only — upstream hooks, tests, and plugin manifests are not included.
