# My Claude Skills

A repository of custom workflows, agents, and prompts.

## Skills Inventory
<!-- CLAUDE: ADD NEW SKILLS DIRECTLY BELOW THIS LINE -->

* **[albert-dm](./skills/albert-dm/SKILL.md)** — Drafts DM and chat replies in the voice of Albert Olgaard, an agency owner selling AI voice agents and lead automation to local service businesses. Use it when you paste a conversation and want the next message written in his casual, question-heavy, no-pressure style.
  * **Stack/Tools:** Prompt-only (no external APIs). Ships with `voice-reference.md`, a set of annotated real transcripts used for tone calibration.
* **[customer-support](./skills/customer-support/SKILL.md)** — Handles support work as a senior specialist: drafting replies, triaging tickets, writing help articles, and reviewing conversations for quality. Use it when you need an empathetic, scannable response that owns the problem and closes with a concrete next step.
  * **Stack/Tools:** Prompt-only (drafts text, no helpdesk API integration). Includes `response-templates.md` for refunds/bugs/outages/billing and `escalation-guide.md` for routing, SLAs, and handoffs.
