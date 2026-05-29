#!/bin/bash
# Serve a directory of generated flow diagrams over HTTP.
# Usage: start-server.sh [serve-dir] [port]
#   serve-dir  directory to serve (default: current directory)
#   port       0 or omitted picks a random free port

SERVE_DIR="${1:-$PWD}"
PORT="${2:-0}"

if [ ! -d "$SERVE_DIR" ]; then
    echo "Directory not found: $SERVE_DIR" >&2
    exit 1
fi

if [ "$PORT" -eq 0 ]; then
    PORT=$(python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()")
fi

echo "Serving $SERVE_DIR at http://localhost:$PORT"
cd "$SERVE_DIR" || exit 1
exec python3 -m http.server "$PORT"
