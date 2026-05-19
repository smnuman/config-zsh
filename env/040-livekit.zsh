# LiveKit Cloud credentials — voice/video/AI agent platform.
# Fill in real values from https://cloud.livekit.io  (Project Settings -> Keys).
# These are inherited by any shell that sources ~/.zshrc, including ones
# that subsequently launch openClaw, lk, or the python agent at
# ~/livekit/agents-py/agent.py.
export LIVEKIT_URL="${LIVEKIT_URL:-wss://shahana-qhu0zm6g.livekit.cloud}"
export LIVEKIT_API_KEY="${LIVEKIT_API_KEY:-APILeXc5hD3n2ZQ}"
export LIVEKIT_API_SECRET="${LIVEKIT_API_SECRET:-CI9yZUy2HUlkDTH3u4dD3OEQHmXKncXgZg101herEel}"

# LLM provider used by the agent (openai realtime model).
export OPENAI_API_KEY="${OPENAI_API_KEY:-}"
