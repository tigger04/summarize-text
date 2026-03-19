<!-- Version: 1.0 | Last updated: 2026-03-19 -->

# Architecture

## Overview

summarize-text is a bash CLI tool suite built around a shared library pattern. Three user-facing scripts (`summarize-text`, `polish-text`, `smart-filename`) each source a common library (`summarize-text-lib.sh`) that provides AI provider integration, I/O handling, and argument parsing.

## Component Diagram

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ summarize-   │  │  polish-     │  │   smart-     │
│    text      │  │    text      │  │  filename    │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       └─────────────────┼─────────────────┘
                         │
              ┌──────────┴──────────┐
              │ summarize-text-     │
              │     lib.sh          │
              ├─────────────────────┤
              │ • load_config()     │
              │ • parse_arguments() │
              │ • execute_processing│
              │ • run_ai_function() │
              │ • openai()          │
              │ • claude()          │
              │ • ollama()          │
              │ • output_result()   │
              └──────────┬──────────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
    ┌─────┴─────┐  ┌────┴────┐  ┌─────┴─────┐
    │  OpenAI   │  │  Claude  │  │  Ollama   │
    │  API      │  │  API     │  │ (local/   │
    │           │  │          │  │  remote)  │
    └───────────┘  └─────────┘  └───────────┘
```

## Script Roles

Each script sets its own `pre_prompt` and optionally overrides behaviour, then delegates to the shared library:

- **summarize-text**: Summarises text into bullet points with themes
- **polish-text**: Refines and improves text clarity
- **smart-filename**: Generates descriptive filenames from content, with optional rename

## Data Flow

1. **Input**: Script resolves the source (file, URL, clipboard, selection, or stdin)
2. **Processing**: `execute_processing()` reads the input and calls `construct_prompt()` to combine the pre-prompt with the input text
3. **AI dispatch**: `run_ai_function()` dispatches to the appropriate AI provider via `case` statement
4. **Output**: `output_result()` routes the response to the configured output destination (stdout, clipboard, notification, etc.)

## Configuration

Configuration is loaded by `load_config()` in this priority order:

1. Environment variables (highest)
2. Config file: `~/.config/summarize-text/config`
3. Built-in defaults (lowest)

AI provider auto-detection: if no provider is explicitly selected, the library checks for available API keys and local Ollama in order: OpenAI → Claude → Ollama.

## Symlink Resolution

All scripts resolve symlinks to find the actual script location, allowing them to be installed via symlink (e.g. Homebrew) while still locating the shared library relative to the real script path.
