<!-- Version: 1.2 | Last updated: 2026-07-17 -->

# summarize-text

AI-powered text processing tool supporting multiple AI providers (OpenAI, Claude, Ollama). Summarize complex content into digestible insights or polish rough drafts into refined prose.

## Quick Start

```bash
brew tap tigger04/tap
brew install summarize-text
```

### Dependencies

**Required:**
- At least one of: OpenAI API key, Claude API key, or Ollama running locally
- `curl`
- `jq`

**Optional:**
- `pdftotext` (from `poppler`) for PDF input
- `pandoc` for DOCX/ODT/RTF input
- `pbcopy`/`pbpaste` (macOS) or `xclip`/`xsel` (Linux) for clipboard operations

### Configuration

```bash
mkdir -p ~/.config/summarize-text
cp config.example ~/.config/summarize-text/config
# Edit with your API keys
```

To avoid storing a key in the configuration file, configure a command that prints it to standard output:

```bash
openai_api_key_command="op read 'op://Private/OpenAI/credential'"
claude_api_key_command="op read 'op://Private/Claude/credential'"
```

Environment variables take precedence over these command values. Ollama does not use an API key; configure `OLLAMA_API_URL` only when using a remote server.

## Usage

```bash
# Summarize a file
summarize-text document.txt

# Summarize from URL
summarize-text https://example.com/article

# Summarize from clipboard, output to clipboard
summarize-text --clipboard --paste

# Polish text (improve language and clarity)
polish-text document.txt

# Generate a smart filename from content
smart-filename receipt.pdf
smart-filename -y invoice.pdf  # auto-rename

# Choose AI provider
summarize-text document.txt --claude
summarize-text document.txt --openai
summarize-text document.txt --ollama=llama2
```

### Input Sources

| Flag | Source |
|------|--------|
| *(positional)* | File path |
| `http://...` | URL |
| `-c, --clipboard` | System clipboard |
| `-s, --selection` | Selected text (0.3s delay) |
| `-` | Standard input |

### Output Destinations

| Flag | Destination |
|------|-------------|
| *(default)* | stdout |
| `-p, --paste` | Clipboard |
| `-n, --notification` | System notification |
| `-d, --dialog` | Dialog window |
| `-t, --type` | Type out result |

## Important Files

| File | Purpose |
|------|---------|
| `summarize-text` | Main summarization script |
| `polish-text` | Text polishing/improvement script |
| `smart-filename` | AI-powered filename generator |
| `summarize-text-lib.sh` | Shared library: AI providers, I/O, argument parsing |
| `config.example` | Example configuration file |
| `VERSION` | Current version number |
| `Makefile` | Build, test, release, and install targets |

## Documentation

| Document | Description |
|----------|-------------|
| [docs/vision.md](docs/vision.md) | Project vision, goals, and design principles |
| [docs/architecture.md](docs/architecture.md) | High-level architecture and component design |
| [docs/testing.md](docs/testing.md) | Testing strategy, structure, and procedures |
| [docs/patterns.md](docs/patterns.md) | Coding patterns and conventions |

## Development

```bash
git clone https://github.com/tigger04/summarize-text.git
cd summarize-text

make test          # Run regression tests
make install       # Dev symlinks in ~/.local/bin (PREFIX=path overrides it)
make release       # Tag and release (VERSION=x.y.z optional)
make sync          # Git add/commit/pull/push
make help          # Show all targets
```

## License

MIT License --- Copyright (c) Taḋg Paul. See [LICENSE](LICENSE).

## Changelog

### 1.2

- Documented command-backed OpenAI and Claude API-key configuration.

### 1.1

- Documented the user-local development symlink installation path.
