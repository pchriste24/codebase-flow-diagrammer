# Codebase Flow Diagrammer Plugin

A Claude Code plugin that visualizes codebase processes with interactive React Flow (xyflow) diagrams.

## Features

- **Process Search**: Provide a search term (e.g., "user signup", "payment processing")
- **Automated Investigation**: Traces entry points, execution paths, and dependencies
- **Two modes**: high-level **process** flows across services, or single-service
  **algorithm** / decision-tree / control-flow diagrams (loops, guards, returns)
- **Drill-down**: a process node whose core logic is a non-trivial algorithm can zoom
  into a nested sub-diagram, with breadcrumb navigation
- **Interactive Diagrams**: React Flow-based HTML pages with clickable code references
- **Auto-layout**: nodes positioned by dagre (no overlap, handles loops/cycles; TB or LR)
- **Guided Tours**: context, descriptions, and high-level decision points
- **No server needed**: a single self-contained HTML file you open directly in a browser

## Installation

### Option A — install the skill globally (recommended)

```bash
npx skills add pchriste24/codebase-flow-diagrammer -g
```

This installs the `flow-diagrammer` skill (with its bundled `templates/` and `bin/`)
into your global skills directory. Invoke it in any project with `/flow-diagrammer`.

### Option B — run as a Claude Code plugin

```bash
# Install Claude Code globally
npm install -g @anthropic-ai/claude-code

# Navigate to your project
cd your-project

# Run Claude Code with this plugin
claude --plugin-dir ./codebase-flow-diagrammer
```

> The HTML template and server script are bundled **inside**
> `skills/flow-diagrammer/` so they travel with the skill on install. Generated
> diagrams are written into a `flow-diagrams/` directory in your current project.

## Usage

Invoke the skill and pass the process or function you want diagrammed:

```bash
/flow-diagrammer "user signup flow"
/flow-diagrammer "payment processing"
/flow-diagrammer "the row-matching algorithm in src/match.js"
```

For a single-service algorithm or decision tree, just describe the function — the
skill picks `algorithm` mode and traces the internal control flow.

## What It Does

1. **Investigates** the codebase to find the relevant process
2. **Traces** the execution flow from entry point to completion
3. **Generates** an interactive HTML diagram with React Flow
4. **Opens** the self-contained HTML file directly in your browser
5. **Provides** clickable references that open code in VS Code

## Output

After investigation, you'll receive:
- A summary of the process in the chat
- A self-contained HTML file (opened in your browser) with the interactive diagram
- Clickable nodes that open the relevant code in VS Code

## Example

```
User: /codebase-flow-diagrammer:flow "user authentication"

Claude:
## User Authentication Flow

I've analyzed the authentication flow and created an interactive diagram.

**Entry Points:**
- POST /api/auth/login (src/routes/auth.js:45)
- POST /api/auth/register (src/routes/auth.js:78)

**Key Components:**
- AuthService (src/services/auth.js)
- TokenManager (src/utils/tokens.js)
- User Model (src/models/User.js)

**Diagram:** opened ./flow-diagrams/user-authentication-flow.html

Click nodes to open code in VS Code. Hover for context.
```

## Technical Details

- Uses React Flow (xyflow) for diagram rendering, with dagre auto-layout
- A single HTML file per diagram; React Flow / dagre load from CDN at runtime
  (so viewing needs network access), with data injected as an embedded JSON block
- Color-coded node types:
  - process: `endpoint`, `logic`, `database`, `external-service`, `decision`
  - algorithm: `start`, `terminal`/`return`/`end`, `loop`, `input`, `output`
- Decision points shown as diamond nodes; branches drawn as labeled edges
- Loop-back edges drawn dashed; cycles handled automatically
- Drillable nodes (with a `subDiagram`) zoom into a nested diagram with breadcrumbs
- Adaptive sidebar/docs — sections render only when their data is present
- Clickable code references open in **VS Code** via `vscode://file/` (the diagram's
  `projectRoot` is set to your project's absolute path so the links resolve)
- Export to PNG

## Development

To test changes:
```bash
claude --plugin-dir ./codebase-flow-diagrammer
# Then run: /reload-plugins
```

## License

MIT
