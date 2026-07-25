# My Claude Skills

A repository of custom workflows, agents, and prompts.

## Skills Inventory
<!-- CLAUDE: ADD NEW SKILLS DIRECTLY BELOW THIS LINE -->

* **[build-premium-website](./skills/build-premium-website/SKILL.md)** — Builds a premium, animated single-page marketing website adapted to any industry, starting from a mandatory intake interview covering brand, tone, services, and contact details. Use it when you want a high-end company site or landing page rather than a generic template.
  * **Stack/Tools:** React 19, Vite, Tailwind CSS, GSAP, Unsplash imagery, `AskUserQuestion` for intake. Bundles a complete working reference implementation under `reference/` (app JSX, CSS, HTML, Tailwind config, plus design-system, animation, and industry-theme guides).
* **[customer-support](./skills/customer-support/SKILL.md)** — Handles support work as a senior specialist: drafting replies, triaging tickets, writing help articles, and reviewing conversations for quality. Use it when you need an empathetic, scannable response that owns the problem and closes with a concrete next step.
  * **Stack/Tools:** Prompt-only (drafts text, no helpdesk API integration). Includes `response-templates.md` for refunds/bugs/outages/billing and `escalation-guide.md` for routing, SLAs, and handoffs.
* **[superpowers](./skills/superpowers/README.md)** *(vendored, third-party)* — A 14-skill engineering-workflow library covering brainstorming, plan writing and execution, TDD, systematic debugging, code review (both directions), git worktrees, subagent orchestration, and verification before claiming completion. Use it to impose a disciplined process on feature work instead of improvising.
  * **Stack/Tools:** Prompt-driven skills plus per-skill helper scripts (Node, shell). Vendored from [obra/superpowers](https://github.com/obra/superpowers) v6.2.0 (commit `3dcbd5c`), MIT licensed, © 2025 Jesse Vincent. Skills tree only — upstream hooks, tests, and plugin manifests are not included.
