<!-- Version: 1.0 | Last updated: 2026-03-19 -->

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
make install       # Dev install to /usr/local/bin (requires sudo)
make release       # Tag and release (VERSION=x.y.z optional)
make sync          # Git add/commit/pull/push
make help          # Show all targets
```

## License

MIT License — Copyright (c) Taḋg Paul. See [LICENSE](LICENSE).
