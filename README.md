# summarize-text

AI-powered text summarization tool supporting multiple AI providers (OpenAI, Claude, Ollama).

## Features

- Summarize text from files, URLs, clipboard, or stdin
- Support for multiple AI models (OpenAI, Claude, Ollama)
- Flexible output options (stdout, clipboard, notifications, dialog)
- Configurable AI provider selection

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/summarize-text.git
cd summarize-text

# Make executable
chmod +x summarize-text

# Optional: Link to PATH
ln -s "$(pwd)/summarize-text" /usr/local/bin/summarize-text
```

## Configuration

The tool automatically detects available AI providers and uses the first available one. Configuration is loaded in this order:

1. **Environment variables** (highest priority)
2. **Config file**: `~/.config/summarize-text/config`
3. **Built-in defaults**

### Quick Setup

```bash
# Create config directory
mkdir -p ~/.config/summarize-text

# Copy example config
cp config.example ~/.config/summarize-text/config

# Edit with your API keys
nano ~/.config/summarize-text/config
```

### Configuration Options

```bash
# ~/.config/summarize-text/config

# API Keys (set at least one)
export OPENAI_API_KEY="sk-..."
export CLAUDE_API_KEY="sk-ant-..."
# export OLLAMA_API_URL="http://localhost:11434"  # Optional: remote Ollama

# Default provider (optional - auto-detects if not set)
export DEFAULT_AI="openai"  # or "claude" or "ollama"

# Model configurations
openai_model="gpt-4o-mini"
claude_model="claude-3-5-sonnet-20241022"
ollama_model="mistral"

# Custom pre-prompt (optional)
# pre_prompt="Your custom summarization instructions..."
```

### Auto-Detection

- If only one API key is provided, that provider becomes the default
- If multiple keys are available, preference order: OpenAI → Claude → Ollama
- If no API keys but Ollama is running locally, uses Ollama

## Usage

```bash
# Summarize a file
summarize-text document.txt

# Summarize from URL
summarize-text https://example.com/article

# Summarize from clipboard
summarize-text --clipboard

# Use specific AI provider
summarize-text document.txt --claude
summarize-text document.txt --openai
summarize-text document.txt --ollama

# Output to clipboard
summarize-text document.txt --paste

# Output as notification
summarize-text document.txt --notification
```

## Options

### AI Models
- `-l, --ollama[=model]`: Use Ollama API
- `-o, --openai[=model]`: Use OpenAI API
- `--claude`: Use Claude API
- `--preprompt=TEXT`: Custom prompt prefix

### Input
- `-c, --clipboard`: Read from clipboard
- `-s, --selection`: Read from selection (0.3s delay)

### Output
- `-n, --notification`: Show as system notification
- `-d, --dialog`: Show in dialog window
- `-t, --type`: Type out the result
- `-p, --paste`: Copy to clipboard

## License

MIT License - See LICENSE file for details