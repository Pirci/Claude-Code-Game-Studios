# Agent Coordination Rules

1. **Vertical Delegation**: Leadership agents delegate to department leads, who
   delegate to specialists. Never skip a tier for complex decisions.
2. **Horizontal Consultation**: Agents at the same tier may consult each other
   but must not make binding decisions outside their domain.
3. **Conflict Resolution**: When two agents disagree, escalate to the shared
   parent. If no shared parent, escalate to `creative-director` for design
   conflicts or `technical-director` for technical conflicts.
4. **Change Propagation**: When a design change affects multiple domains, the
   `producer` agent coordinates the propagation.
5. **No Unilateral Cross-Domain Changes**: An agent must never modify files
   outside its designated directories without explicit delegation.

## Model Tier Assignment

Skills and agents are assigned to model tiers based on task complexity:

| Tier | Model | When to use |
|------|-------|-------------|
| **Haiku** | `claude-haiku-4-5-20251001` | Read-only status checks, formatting, simple lookups, templated output — no creative judgment needed |
| **Sonnet** | `claude-sonnet-4-6` | Implementation, design authoring, analysis of individual systems — default for most work |
| **Opus** | `claude-opus-4-6` | Multi-document synthesis, high-stakes phase gate verdicts, cross-system holistic review, architecture decisions |

### Agent Tier Dağılımı

| Tier | Agents |
|------|--------|
| **Opus** (5) | creative-director, technical-director, producer, narrative-director, lead-programmer |
| **Sonnet** (37) | Tüm designer'lar, programmer'lar, specialist'ler (varsayılan) |
| **Haiku** (7) | devops-engineer, community-manager, qa-tester, tools-programmer, sound-designer, localization-lead, release-manager |

### Skill Tier Dağılımı

Skills with `model: haiku`: `/help`, `/sprint-status`, `/story-readiness`, `/scope-check`,
`/project-stage-detect`, `/changelog`, `/patch-notes`, `/onboard`, `/smoke-check`,
`/bug-report`, `/estimate`, `/test-evidence-review`

Skills with `model: opus`: `/review-all-gdds`, `/architecture-review`, `/gate-check`,
`/create-architecture`, `/milestone-review`, `/design-review`, `/team-combat`,
`/content-audit`, `/balance-check`

All other skills default to Sonnet.

### Tier Seçim Kuralları

Yeni skill veya agent oluştururken:

1. **Haiku** ata eğer: sadece okuma yapıyorsa, template dolduruyorsa, checklist
   doğruluyorsa, formatlama yapıyorsa. Yaratıcı yargı gerektirmiyorsa.
2. **Sonnet** ata eğer: tek bir sistem tasarlıyor/uyguluyorsa, kod yazıyorsa,
   tek bir doküman analiz ediyorsa. Çoğu iş buraya düşer.
3. **Opus** ata eğer: 5+ dokümanı sentezliyorsa, çapraz-sistem kararlar veriyorsa,
   geri dönüşü zor yüksek riskli çıktılar üretiyorsa, veya birden fazla agent'ı
   koordine ediyorsa.

### Dinamik Model Override

Bir agent veya skill çalışma sırasında farklı zorluktaki alt görevlerle
karşılaşabilir. Bu durumda subagent spawn ederken `model:` parametresini
override edebilir:

```
# Sonnet agent, karmaşık bir alt görev için Opus subagent çağırır:
Agent(subagent_type="narrative-director", model="opus", prompt="...")

# Opus agent, basit bir arama için Haiku subagent çağırır:
Agent(subagent_type="Explore", model="haiku", prompt="...")
```

Bu sayede aynı iş akışı içinde maliyet-verimlilik dengesi sağlanır.

## Subagents vs Agent Teams

This project uses two distinct multi-agent patterns:

### Subagents (current, always active)
Spawned via `Task` within a single Claude Code session. Used by all `team-*` skills
and orchestration skills. Subagents share the session's permission context, run
sequentially or in parallel within the session, and return results to the parent.

**When to spawn in parallel**: If two subagents' inputs are independent (neither
needs the other's output to begin), spawn both Task calls simultaneously rather
than waiting. Example: `/review-all-gdds` Phase 1 (consistency) and Phase 2
(design theory) are independent — spawn both at the same time.

### Agent Teams (experimental — opt-in)
Multiple independent Claude Code *sessions* running simultaneously, coordinated
via a shared task list. Each session has its own context window and token budget.
Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` environment variable.

**Use agent teams when**:
- Work spans multiple subsystems that will not touch the same files
- Each workstream would take >30 minutes and benefits from true parallelism
- A senior agent (technical-director, producer) needs to coordinate 3+ specialist
  sessions working on different epics simultaneously

**Do not use agent teams when**:
- One session's output is required as input for another (use sequential subagents)
- The task fits in a single session's context (use subagents instead)
- Cost is a concern — each team member burns tokens independently

**Current status**: Opt-in via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Document first usage here when adopted.

## Parallel Task Protocol

When an orchestration skill spawns multiple independent agents:

1. Issue all independent Task calls before waiting for any result
2. Collect all results before proceeding to dependent phases
3. If any agent is BLOCKED, surface it immediately — do not silently skip
4. Always produce a partial report if some agents complete and others block
