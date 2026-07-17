<!-- Version: 1.0 | Last updated: 2026-07-17 -->

# summarize-text help

## Usage

`summarize-text [OPTIONS] INPUT [OUTPUT]`

Summarize text using an available AI provider.

Input may be a filename, an HTTP(S) URL, `-` for standard input, the clipboard, or selected text. Output defaults to standard output and can instead be copied, pasted, typed, shown as a notification, or displayed in a dialog.

## Options

- `-l`, `--ollama[=MODEL]`: use Ollama, optionally naming a model.
- `-o`, `--openai[=MODEL]`: use OpenAI, optionally naming a model.
- `--claude`: use Claude.
- `--preprompt=TEXT`: provide a custom prompt.
- `-c`, `--clipboard`: use the system clipboard as input.
- `-s`, `--selection`: use selected text as input.
- `-n`, `--notification`: show the result as a notification.
- `-d`, `--dialog`: show the result in a dialog.
- `-t`, `--type`: type the result.
- `-p`, `--paste`: copy the result to the clipboard.
- `-h`, `--help`: show this help text.
- `--version`: show the command version.

## Examples

```text
summarize-text document.txt
summarize-text --clipboard --paste
summarize-text https://example.com --claude
cat document.txt | summarize-text
```
