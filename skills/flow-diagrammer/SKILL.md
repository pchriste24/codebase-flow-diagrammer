---
name: flow-diagrammer
description: Visual codebase flow explorer that identifies core processes, traces execution paths, and generates interactive React Flow (xyflow) diagrams with clickable code references. Use when user wants to understand codebase architecture, get a guided tour of processes/services, or visualize data flows.
---

# Codebase Flow Diagrammer

## Purpose
Given a search term for a desired process, this skill will:
1. Investigate the codebase to identify the core flow/process
2. Trace entry points, dependencies, and execution paths
3. Generate a local interactive HTML page with a React Flow (xyflow) diagram
4. Include context, descriptions, high-level decisions, and clickable references to relevant code files

### Two diagram modes
The same template renders either mode — set `diagramType` in the data:

- **`"process"`** (default) — a flow that spans **multiple services**: routes,
  handlers, DB calls, external APIs. The original use case.
- **`"algorithm"`** — a **single service's** algorithm, decision tree, or control
  flow: branches, loops, guards, recursion, early returns within one function/module.

### Nested drill-down
A process node whose core logic is itself a non-trivial algorithm can carry a
`subDiagram` reference. In the rendered page that node is **drillable**: clicking it
zooms into a nested diagram (its own layout/sidebar/docs), with a breadcrumb to climb
back. This lets one artifact hold both the high-level flow **and** the algorithm
detail without cramming them onto one canvas. See "When to nest a sub-diagram" below.

## Workflow

### Step 1: Understand the Request
- Get the process/search term from the user (e.g., "user signup flow", "payment processing", "order creation")
- Clarify scope if needed (frontend, backend, specific service)
- **Decide the mode.** If the target spans multiple services/endpoints → `"process"`.
  If it's the internal logic of a single function/module (an algorithm, a decision
  tree, a state machine) → `"algorithm"`. When in doubt, ask, or default to `process`
  and nest the algorithm as a sub-diagram (see Step 3).

### Step 2: Codebase Exploration
Use these tools in sequence. Pick the lens that matches the mode.

**Process mode — trace across services (the default lens):**

1. **Find entry points**: Search for routes, handlers, CLI commands, scheduled jobs related to the process
   - Use `grep`, `rg`, `find` to locate relevant files
   - Look for route definitions, controller actions, service entry points

2. **Trace the flow**:
   - Use Code Flow Tracer logic to map execution paths
   - Trace function calls, API endpoints, database queries, external service calls

3. **Identify components**:
   - List all services, modules, and files involved
   - Note data transformations at each step
   - Identify decision points and conditional branches

**Algorithm mode — trace control flow *within* one function/module:**

1. **Find the function**: locate the function/method and read it end to end. Note its
   signature (parameters → `inputs`) and every `return`/throw (→ `outputs`/terminals).
2. **Map control flow**, not service calls:
   - Each `if`/`switch`/ternary/guard clause → a `decision` node; label every branch
     ("true"/"false", case values, ranges).
   - Each `for`/`while`/`map`/recursion → a `loop` node; the edge that returns to the
     loop head is a **loop-back** edge (`loopBack: true`).
   - Guard clauses and early returns → `return`/`terminal` nodes.
   - Note preconditions/invariants the code assumes (→ `preconditions`).
3. **Estimate complexity** (time/space) if it's meaningful (→ `complexity`).
4. Keep nodes pointing at **line ranges within the one file** — in algorithm mode the
   "which file" matters less than "which lines."

### Step 3: Build the Flow Diagram Data
Create a structured JSON representation. The full schema is documented in the comment
at the top of `templates/flow-diagram.html`; the key fields:

**Always:**
- `processName`: title of the diagram
- `description`: one-line summary
- `diagramType`: `"process"` (default) or `"algorithm"`
- `direction`: `"TB"` (default, top→bottom) or `"LR"` (left→right — better for wide
  decision trees)
- `nodes[]`: `{ id, label, type, file, line, description, subDiagram }`
- `edges[]`: `{ id, from, to, label, loopBack }`
  - `label`: branch text — "valid"/"invalid"/"true"/"false"/case values
  - `loopBack: true`: a loop-back/repeat edge (drawn dashed + cyan, animated)
- `decisions[]`: `{ id, label, file, line, branches:[{ when, then }] }`

**Sidebar/docs sections — include whichever fit (they render only when present):**
- `entryPoints[]`: `{ label, file, line }` (or a `"POST /x (file:line)"` string)
- `externalServices[]`: databases, APIs, third-party services (process mode)
- `inputs[]`: `{ name, type, description }` — function params (algorithm mode)
- `preconditions[]`: strings — guards/assumptions (algorithm mode)
- `outputs[]`: `{ name, type, description }` — return values (algorithm mode)
- `complexity`: `"O(n log n)"` or `{ time, space }` (algorithm mode)

**Node types:**
- process: `endpoint` · `logic` · `database` · `external-service` · `decision`
- algorithm: `start` · `terminal`/`return`/`end` · `logic` · `decision` · `loop` ·
  `input` · `output`

Positions are auto-computed (dagre) — **do not** supply `x`/`y`.

#### When to nest a sub-diagram
Emit a `subDiagram` when, while tracing a process, you hit a node whose internal logic
is a non-trivial algorithm that deserves its own explanation (e.g. a matching
algorithm, a ranking/scoring pass, a retry/backoff state machine). Instead of flattening
its 15 decision nodes into the high-level flow:

1. Keep the process node as one step, and add `"subDiagram": "<key>"` to it.
2. Add a top-level `subDiagrams` registry: `{ "<key>": <full flow-data object> }`.
   The nested object is a complete diagram in its own right — usually
   `"diagramType": "algorithm"` with its own `inputs`/`outputs`/`nodes`/`edges`.
3. Sub-diagrams may nest further (a sub-diagram node can reference another key).

Rule of thumb: if a single node would need more than ~5–6 internal steps to explain,
nest it rather than inlining. Keep each level readable.

```json
{
  "nodes": [
    { "id": "match", "label": "Match snapshot rows", "type": "logic",
      "file": "src/match.js", "line": 12, "subDiagram": "match-algo" }
  ],
  "subDiagrams": {
    "match-algo": {
      "processName": "Row-Matching Algorithm",
      "diagramType": "algorithm", "direction": "LR",
      "inputs": [ ... ], "outputs": [ ... ],
      "nodes": [ ... ], "edges": [ ... ]
    }
  }
}
```

### Step 4: Generate Interactive HTML with React Flow (docs-canvas style)

This skill **bundles** the HTML template. Do **NOT** build the HTML from scratch —
always start from the bundled template so output stays consistent.

1. Locate the bundled template at `templates/flow-diagram.html` **relative to this
   SKILL.md file** (i.e. the skill's own directory — the same directory this file
   lives in). Read it from there; it is not in the user's project.
2. Create an output directory in the **user's current working directory** (e.g.
   `./flow-diagrams/`) and copy the template to
   `./flow-diagrams/{process-name}-flow.html`. Never write generated files into the
   skill's install directory.
3. Replace the placeholder JSON inside the `<script id="flow-data">` block with the
   actual flow data (see the Step 3 schema and the template's header comment):
   - processName, description, diagramType, direction
   - nodes (with file:line, type, label; `subDiagram` where you nest)
   - edges (from, to, label, loopBack)
   - decisions, and the section data that fits (entryPoints/externalServices for
     process; inputs/preconditions/outputs/complexity for algorithm)
   - subDiagrams registry, if any node is drillable
4. The HTML is self-contained and opens in any browser.
5. Start a local HTTP server serving the output directory on a random port (see Step 5).
6. Print the URL to the user.

The data is injected via an embedded JSON `<script>` block that the page reads on load:

```html
<script id="flow-data" type="application/json">
{
  "processName": "User Signup Flow",
  "description": "Handles user registration from request to database persistence",
  "diagramType": "process",
  "nodes": [...],
  "edges": [...],
  "decisions": [...],
  "entryPoints": ["POST /api/auth/signup (src/routes/auth.js:45)"],
  "externalServices": ["PostgreSQL", "SendGrid", "Redis"],
  "subDiagrams": { "...": { "diagramType": "algorithm", "...": "..." } }
}
</script>
```

The generated page (docs-canvas style) includes:

- A fixed left sidebar with the title/description and a table-of-contents nav that
  adapts to the data (Entry Points / Inputs / Preconditions / Steps / Decision Points
  / Outputs / External Services — only those present), plus a clickable entry-points
  or inputs list and any external-dependency / complexity info
- A main area with the interactive React Flow diagram on top and detailed,
  anchored documentation sections below it
- Color-coded React Flow nodes by type:
  - endpoint: blue (#3b82f6) — pill
  - logic: green (#22c55e) — rectangle
  - database: orange (#f97316) — rectangle with DB icon
  - external-service: purple (#a855f7) — rectangle with external icon
  - decision: yellow diamond (#eab308)
  - start/terminal/return/end: stadium (teal / slate)
  - loop: cyan (#06b6d4), dashed
  - input/output: pink (#ec4899) / indigo (#6366f1)
- Clickable nodes (`openCodeFile(filePath, line)`) that open the file in
  Claude/Cursor's viewer, fall back to an editor deep link / `file://` URL, and
  show a friendly message if it can't open
- **Drillable nodes** (those with a `subDiagram`): a double border + `⤵` badge;
  clicking the body zooms into the nested diagram with a breadcrumb to climb back,
  while clicking the node's file:line still opens the code
- Hover tooltips showing file:line, context, and what the step does
- Edges labeled for branches ("valid"/"invalid"/"true"/"false"/cases); loop-back
  edges drawn dashed + cyan
- Zoom/pan, a minimap, and an "Export to PNG" button

### Step 5: Spin Up Local Server
- Serve the output directory created in Step 4 (e.g. `./flow-diagrams/`) on a random port.
- Use the bundled helper (relative to this SKILL.md):
  `bash bin/start-server.sh ./flow-diagrams` — it picks a random free port and prints the URL.
  (Or run `python3 -m http.server <port>` from that directory directly.)
- Run it in the background so the session can continue.
- Print the local URL to the user (e.g., "http://localhost:4321/user-signup-flow.html").
- Provide a summary of the flow in the chat.

## Output Format

### In Chat (docs-canvas style):
```text
## {Process Name} Flow

I've analyzed the `{process}` flow and created an interactive diagram.

### Entry Points
- **POST /api/auth/signup** (`src/routes/auth.js:45`)
- **POST /api/auth/register** (`src/routes/auth.js:78`)

### Core Flow Steps
1. Validate input → AuthService.validate()
2. Create user → User.create()
3. Hash password → bcrypt.hash()
4. Save to DB → PostgreSQL users table
5. Send welcome email → SendGrid API

### Decision Points
- **Validate input**:
  - ✅ Valid email → Continue to create user
  - ❌ Invalid email → Return 400 error

### External Dependencies
- PostgreSQL (users table)
- SendGrid (welcome email)
- Redis (session cache)

### Interactive Diagram
Local page is spinning up at: **http://localhost:{PORT}/{process}-flow.html**

Click nodes to jump to code. Hover for context. Use sidebar to navigate sections.
Export to PNG using the button in the diagram.
```

### HTML Page Features:
- Interactive React Flow (xyflow) diagram with zoom/pan and a minimap
- Two modes (process / algorithm) from one template, via `diagramType`
- Auto-layout (dagre) — no manual coordinates; handles loops/cycles; TB or LR
- Drill-down: click a node with a `subDiagram` to zoom in; breadcrumbs to climb back
- Adaptive sidebar + table-of-contents (sections render only when their data exists)
- Detailed documentation sections below the diagram
- Clickable code references that open files in the editor
- Color-coded node types with shape/icon per type (incl. start/terminal/loop/input/output)
- Hover tooltips with file:line and context
- Export to PNG

## Cursor Canvas Alternative (optional)

If the user is running this inside **Cursor IDE (3.1+ with the Canvas feature)**, offer to
generate a **Cursor Canvas** instead of a standalone HTML file. Canvas is a native,
React-based interactive UI that persists in the Agents Window with no local server.
When using Canvas, structure it like the HTML output:
- A table-of-contents section
- An architecture/flow diagram component
- Code reference blocks with clickable links
- Sections grouped by importance

If the user is **not** in Cursor IDE, use the standalone HTML + local server approach above.

## Tools Used
- `grep`, `rg`, `find` -- for searching codebase
- `Read` -- for reading files
- `Bash` -- for running local server and generating HTML

## Example Invocation
User: `/codebase-flow-diagrammer:flow "user payment processing"`

Result: Analyzes payment flow, creates interactive diagram at `http://localhost:4321/payment-processing-flow.html`
