# Codebase Flow Diagrammer Plugin

A Claude Code plugin that visualizes codebase processes with interactive React Flow (xyflow) diagrams.

## Features

- **Process Search**: Provide a search term (e.g., "user signup", "payment processing")
- **Automated Investigation**: Traces entry points, execution paths, and dependencies
- **Interactive Diagrams**: React Flow-based HTML pages with clickable code references
- **Guided Tours**: Context, descriptions, and high-level decision points
- **Local Server**: Spins up a local page to view the diagram

## Installation

```bash
# Install Claude Code globally
npm install -g @anthropic-ai/claude-code

# Navigate to your project
cd your-project

# Run Claude Code with this plugin
claude --plugin-dir ./codebase-flow-diagrammer
```

## Usage

```bash
# Usage with argument (the process/search term)
/codebase-flow-diagrammer:flow "user signup flow"
/codebase-flow-diagrammer:flow "payment processing"
/codebase-flow-diagrammer:flow "order creation"
```

## What It Does

1. **Investigates** the codebase to find the relevant process
2. **Traces** the execution flow from entry point to completion
3. **Generates** an interactive HTML diagram with React Flow
4. **Spins up** a local server to view the diagram
5. **Provides** clickable references to code files

## Output

After investigation, you'll receive:
- A summary of the process in the chat
- A local URL to view the interactive diagram
- Clickable nodes that jump to relevant code files

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

**Diagram:** http://localhost:4321/user-authentication-flow.html

Click nodes to jump to code. Hover for context.
```

## Technical Details

- Uses React Flow (xyflow) for diagram rendering
- Generates self-contained HTML with embedded CSS/JS
- Color-coded node types (endpoints, logic, databases, external services)
- Decision points shown as diamond nodes
- Decision branches with labeled edges

## Development

To test changes:
```bash
claude --plugin-dir ./codebase-flow-diagrammer
# Then run: /reload-plugins
```

## License

MIT
