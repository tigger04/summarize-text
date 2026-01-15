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

The tool looks for configuration in the following order:
1. Environment variables: `OPENAI_API_KEY`, `CLAUDE_API_KEY`, `OLLAMA_API_URL`
2. Config file: `~/.config/summarize-text/config`

### Example config file

```bash
# ~/.config/summarize-text/config
export OPENAI_API_KEY="your-openai-key"
export CLAUDE_API_KEY="your-claude-key"
export DEFAULT_AI="openai"  # or "claude" or "ollama"

# Model configurations
openai_model="gpt-4o-mini"
claude_model="claude-3-5-sonnet-20241022"
ollama_model="mistral"
```

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