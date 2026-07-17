<!-- Version: 1.0 | Last updated: 2026-07-17 -->

# smart-filename help

## Usage

`smart-filename [-y] [OPTIONS] FILENAME...`

`smart-filename [OPTIONS] --clipboard`

Generate descriptive filenames from file or clipboard content. The command asks before renaming unless `-y` is supplied.

## Options

- `-l`, `--ollama[=MODEL]`: use Ollama, optionally naming a model.
- `-o`, `--openai[=MODEL]`: use OpenAI, optionally naming a model.
- `--claude`: use Claude.
- `--prompt=TEXT`: provide a custom prompt.
- `-c`, `--clipboard`: use the system clipboard as input.
- `-y`, `--yes`: rename without confirmation.
- `-h`, `--help`: show this help text.
- `--version`: show the command version.

## Examples

```text
smart-filename receipt.pdf
smart-filename -y invoice.pdf
smart-filename -y file1.pdf file2.txt file3.md
smart-filename --clipboard
smart-filename document.txt --claude
```
