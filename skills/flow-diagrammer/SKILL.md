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

## Workflow

### Step 1: Understand the Request
- Get the process/search term from the user (e.g., "user signup flow", "payment processing", "order creation")
- Clarify scope if needed (frontend, backend, specific service)

### Step 2: Codebase Exploration
Use these tools in sequence:

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

### Step 3: Build the Flow Diagram Data
Create a structured JSON representation with:
- `processName`: name of the process
- `entryPoints`: list of entry points with file:line
- `nodes`: array of step nodes (id, label, type, file, line)
- `edges`: array of connections (from, to, label)
- `decisions`: decision points with conditions and next steps
- `externalServices`: databases, APIs, third-party services

Node types: `endpoint`, `logic`, `database`, `external-service`, `decision`

### Step 4: Generate Interactive HTML with React Flow (docs-canvas style)
1. Copy `templates/flow-diagram.html` to `output/{process-name}-flow.html`
2. Replace the placeholder JSON data with actual flow data:
   - processName, description
   - nodes (with file:line, type, label)
   - edges (from, to, label)
   - decisions (conditions and next steps)
   - entryPoints and externalServices
3. The HTML should be self-contained and open in any browser
4. Start a local HTTP server serving the `output/` directory on a random port
5. Print the URL to the user

The data is injected via an embedded JSON `<script>` block that the page reads on load:

```html
<script id="flow-data" type="application/json">
{
  "processName": "User Signup Flow",
  "description": "Handles user registration from request to database persistence",
  "nodes": [...],
  "edges": [...],
  "decisions": [...],
  "entryPoints": ["POST /api/auth/signup (src/routes/auth.js:45)"],
  "externalServices": ["PostgreSQL", "SendGrid", "Redis"]
}
</script>
```

The generated page (docs-canvas style) includes:

- A fixed left sidebar with the process name/description, a table-of-contents nav
  (Entry Points, Core Flow Steps, Decision Points, External Services), a clickable
  entry-points list, and the external-dependency list
- A main area with the interactive React Flow diagram on top and detailed,
  anchored documentation sections below it
- Color-coded React Flow nodes by type:
  - endpoint: blue (#3b82f6) — rounded/pill
  - logic: green (#22c55e) — rectangle
  - database: orange (#f97316) — rectangle with DB icon
  - external-service: purple (#a855f7) — rectangle with external icon
  - decision: yellow diamond (#eab308)
- Clickable nodes (`openCodeFile(filePath, line)`) that open the file in
  Claude/Cursor's viewer, fall back to an editor deep link / `file://` URL, and
  show a friendly message if it can't open
- Hover tooltips showing file:line, context, and what the step does
- Edges labeled for decision branches ("valid", "invalid", "true", "false", …)
- Zoom/pan, a minimap, and an "Export to PNG" button

### Step 5: Spin Up Local Server
- Create `output/` directory if it doesn't exist
- Start a simple HTTP server on a random port serving the `output/` directory
- Print the local URL to the user (e.g., "http://localhost:4321/user-signup-flow.html")
- Provide summary of the flow in the chat

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
- Fixed sidebar with process description and table-of-contents navigation
- Detailed documentation sections (entry points, steps, decisions, services) below the diagram
- Clickable code references that open files in the editor
- Color-coded node types with shape/icon per type
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
