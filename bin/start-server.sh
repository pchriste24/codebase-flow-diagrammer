#!/bin/bash
# Start a simple HTTP server in the output directory

OUTPUT_DIR="$(cd "$(dirname "$0")/../output" && pwd)"
PORT=${1:-0}  # 0 means random available port

if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
fi

# Find an available port
if [ "$PORT" -eq 0 ]; then
    PORT=$(python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()")
fi

echo "Starting HTTP server on port $PORT..."
echo "Serving: $OUTPUT_DIR"

cd "$OUTPUT_DIR"
python3 -m http.server "$PORT" &
SERVER_PID=$!

echo $SERVER_PID > "$(dirname "$0")/../output/.server.pid"

echo "Server running at: http://localhost:$PORT"
echo "PID: $SERVER_PID"

# Wait for the server
wait $SERVER_PID
