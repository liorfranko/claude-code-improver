# Architecture Discovery Process

## Philosophy

Every project has a natural hierarchy waiting to be discovered. Instead of imposing a structure, ask questions to reveal the organization that already exists in your code.

The goal: **When you look at a folder, you immediately know what belongs there and what doesn't.**

---

## Step 1: Map What Exists

Before reorganizing, understand what you have.

### Questions to Ask

1. **What are all the "things" in your codebase?**
   - List every folder at the top level
   - For each: write a one-sentence description of what it contains

2. **Which things are similar?**
   - Group folders that "feel" related
   - What do they have in common?

3. **Which things could exist independently?**
   - If you deleted everything else, what would still make sense on its own?
   - These are your foundational pieces

### Exercise: Dependency Mapping

For each module, ask: "What does this import from?"

```
Module A imports from: [B, C, E]
Module B imports from: [E]
Module C imports from: [E]
Module D imports from: [A, B, C]
Module E imports from: [nothing internal]
```

Draw this as a graph. Modules at the bottom (imported by many, import from few) are foundational. Modules at the top (import from many) are coordinators.

---

## Step 2: Identify Natural Layers

Layers emerge from dependency patterns. Look for clusters.

### Questions to Ask

1. **What knows about nothing else?**
   - These are your foundation: config, utilities, base classes
   - They should be importable by everything

2. **What represents your core concepts?**
   - The "nouns" of your system: User, Session, Agent, Tool
   - These define WHAT your system is about

3. **What coordinates those concepts?**
   - The "verbs": orchestrate, process, handle, execute
   - These define HOW things work together

4. **What talks to the outside world?**
   - APIs, CLIs, webhooks, message consumers
   - These are entry/exit points

### Pattern Recognition

| If you see... | It might be... |
|--------------|----------------|
| No internal imports | Foundation layer |
| Only imports "nouns" (models, entities) | Core/domain layer |
| Imports and coordinates multiple things | Application/orchestration layer |
| Handles HTTP/CLI/external protocols | Interface layer |

---

## Step 3: Define Your Layers

Based on discovery, name YOUR layers. There's no magic number.

### Questions to Ask

1. **What name captures this group's responsibility?**
   - Use a name that answers: "What question does this layer answer?"
   - Examples: "How do we connect to things?" → `connections/`
   - "What are the core concepts?" → `domain/` or `core/`
   - "How do users interact?" → `interfaces/` or `api/`

2. **Can you explain the layer in one sentence?**
   - If you need more, the layer might be too broad
   - Split it or reconsider the grouping

3. **Is there a clear "in" and "out"?**
   - What can this layer import?
   - What should import from this layer?

### Template

For each layer you define:

```
Layer: [name]
Responsibility: [one sentence]
Contains: [types of things]
Imports from: [other layers]
Imported by: [other layers]
```

---

## Step 4: Establish Dependency Rules

The hierarchy becomes real when you enforce it.

### The Golden Rule

**Dependencies flow in one direction.** Pick a direction and stick to it.

Common patterns:
- **Bottom-up**: Foundation → Core → Application → Interfaces
- **Inside-out**: Core → Application → Infrastructure + Interfaces

### Questions to Ask

1. **If I change layer X, what else might break?**
   - Layers should minimize ripple effects
   - High-change things shouldn't be deep in the hierarchy

2. **Can I test layer X without layer Y?**
   - If not, maybe Y should be below X
   - Or maybe they're actually one layer

3. **Where do cycles exist?**
   - A imports B, B imports A = problem
   - Either merge them or extract shared code downward

### Enforcement

Add a comment at the top of each layer's `__init__.py`:

```python
"""
Layer: [name]
Responsibility: [one sentence]
May import: [layers below]
Imported by: [layers above]
"""
```

---

## Step 5: Handle the Exceptions

Some code doesn't fit. That's okay.

### Questions to Ask

1. **Is this truly cross-cutting?**
   - Used by multiple layers equally?
   - Examples: logging decorators, retry utilities, metrics

2. **Is this a bridge between layers?**
   - Adapters, translators, mappers
   - These often live at layer boundaries

3. **Is this temporary?**
   - Migration code, compatibility shims
   - Mark it clearly, plan to remove it

### Options for Cross-Cutting Code

- **`shared/` or `common/`**: Importable by anyone
- **Keep in foundation layer**: If it truly has no dependencies
- **Duplicate**: Sometimes copying is cleaner than coupling

---

## Step 6: Validate Your Design

Test your hierarchy with scenarios.

### Questions to Ask

1. **"Where does X go?"**
   - Pick 5 random classes/functions
   - Can you place them without hesitation?
   - If not, your layer definitions need work

2. **"What if we add feature Y?"**
   - New features should fit naturally
   - If every feature creates new folders, structure is too rigid

3. **"Can a new developer understand this?"**
   - Walk through the structure out loud
   - Where do you struggle to explain?

### Red Flags

| Symptom | Possible Issue |
|---------|---------------|
| Folder has 1-2 files | Over-fragmentation |
| Folder has 20+ files | Under-organization |
| Same prefix everywhere (`user_service.py`, `user_repo.py`, `user_model.py`) | Should be a subfolder |
| Circular imports | Layer boundary violation |
| "utils" folder growing forever | Missing domain concepts |

---

## Example Discovery Session

Starting point:
```
agent/
├── agents/
├── api/
├── cli/
├── config/
├── core/
├── evaluations/
├── frameworks/
├── memory/
├── models/
├── orchestrator/
├── sessions/
├── storage/
├── tools/
├── tracing/
└── utils/
```

### Step 1: Describe each

| Folder | What it contains |
|--------|-----------------|
| agents | Agent implementations |
| api | REST endpoints |
| cli | Command-line interface |
| config | Settings and configuration |
| core | ??? (need to look inside) |
| evaluations | Testing/benchmarking |
| frameworks | LangChain, etc. integrations |
| memory | Conversation memory |
| models | Data models |
| orchestrator | Agent coordination |
| sessions | User sessions |
| storage | Database access |
| tools | Agent tools |
| tracing | Logging/observability |
| utils | Shared utilities |

### Step 2: Map dependencies

```
What imports nothing internal?
→ config, utils, tracing

What imports those basics + defines core concepts?
→ models, memory, sessions

What coordinates those concepts?
→ agents, orchestrator, tools

What handles external communication?
→ api, cli

What's cross-cutting/special?
→ evaluations, frameworks, core (investigate more)
```

### Step 3: Define layers (example outcome)

```
foundation/     → config, storage, tracing, utils
domain/         → models, memory, sessions
application/    → agents, orchestrator, tools, core
interfaces/     → api, cli
support/        → evaluations, frameworks
```

Or maybe:

```
infrastructure/ → config, storage, tracing
core/           → models, memory, sessions, utils
agents/         → agents, orchestrator, tools
interfaces/     → api, cli
experimental/   → evaluations, frameworks
```

**Your layers depend on YOUR project's natural shape.**

---

## Checklist

Before finalizing your structure:

- [ ] Every folder has a clear, one-sentence responsibility
- [ ] Dependencies flow in one direction (no cycles)
- [ ] You can answer "where does X go?" for any new code
- [ ] Layer boundaries are documented
- [ ] A new team member could understand the structure in 10 minutes

---

## Remember

The best structure is one that:
1. **Matches how you think** about the problem
2. **Makes the right thing easy** and the wrong thing hard
3. **Grows naturally** as the project evolves

There's no universal answer. Discover what works for YOUR codebase.
