#!/usr/bin/env bats
# ABOUTME: Regression tests for command-backed provider API keys
# ABOUTME: Exercises key resolution through the public CLI with a fake API client

setup() {
   PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
   TEST_HOME="$(mktemp -d)"
   FAKE_BIN="$TEST_HOME/bin"
   AUTH_CAPTURE="$TEST_HOME/authorization"
   COMMAND_MARKER="$TEST_HOME/command-ran"
   mkdir -p "$FAKE_BIN" "$TEST_HOME/.config/summarize-text"

   printf '%s\n' \
      '#!/usr/bin/env bash' \
      'set -eo pipefail' \
      'authorization=""' \
      'while [ "$#" -gt 0 ]; do' \
      '   if [ "$1" = "-H" ]; then' \
      '      shift' \
      '      case "$1" in' \
      '      Authorization:*) authorization="$1" ;;' \
      '      x-api-key:*) authorization="$1" ;;' \
      '      esac' \
      '   fi' \
      '   shift' \
      'done' \
      'printf "%s" "$authorization" > "$AUTH_CAPTURE"' \
      'printf "%s\n" "{\"choices\":[{\"message\":{\"content\":\"configured key accepted\"}}],\"content\":[{\"text\":\"configured key accepted\"}]}"' \
      > "$FAKE_BIN/curl"
   chmod +x "$FAKE_BIN/curl"
}

teardown() {
   trash -- "$TEST_HOME"
}

@test "RT-15.1 OpenAI command output supplies the CLI API key" {
   printf '%s\n' 'openai_api_key_command="printf command-openai-key"' > "$TEST_HOME/.config/summarize-text/config"

   run env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" AUTH_CAPTURE="$AUTH_CAPTURE" "$PROJECT_ROOT/summarize-text" --openai "$PROJECT_ROOT/tests/regression/fixtures/sample.txt"

   [ "$status" -eq 0 ]
   [[ "$output" =~ "configured key accepted" ]]
   [ "$(cat "$AUTH_CAPTURE")" = "Authorization: Bearer command-openai-key" ]
}

@test "RT-15.2 Claude command output supplies the CLI API key" {
   printf '%s\n' 'claude_api_key_command="printf command-claude-key"' > "$TEST_HOME/.config/summarize-text/config"

   run env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" AUTH_CAPTURE="$AUTH_CAPTURE" "$PROJECT_ROOT/summarize-text" --claude "$PROJECT_ROOT/tests/regression/fixtures/sample.txt"

   [ "$status" -eq 0 ]
   [[ "$output" =~ "configured key accepted" ]]
   [ "$(cat "$AUTH_CAPTURE")" = "x-api-key: command-claude-key" ]
}

@test "RT-15.3 environment API key takes precedence over its command" {
   printf '%s\n' 'openai_api_key_command="touch \"$COMMAND_MARKER\"; printf command-openai-key"' > "$TEST_HOME/.config/summarize-text/config"

   run env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" AUTH_CAPTURE="$AUTH_CAPTURE" COMMAND_MARKER="$COMMAND_MARKER" OPENAI_API_KEY="environment-openai-key" "$PROJECT_ROOT/summarize-text" --openai "$PROJECT_ROOT/tests/regression/fixtures/sample.txt"

   [ "$status" -eq 0 ]
   [ ! -e "$COMMAND_MARKER" ]
   [ "$(cat "$AUTH_CAPTURE")" = "Authorization: Bearer environment-openai-key" ]
}

@test "RT-15.4 failed OpenAI key command reports failure without setting a key" {
   printf '%s\n' 'openai_api_key_command="false"' > "$TEST_HOME/.config/summarize-text/config"

   run env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$PROJECT_ROOT/summarize-text" --openai "$PROJECT_ROOT/tests/regression/fixtures/sample.txt"

   [ "$status" -ne 0 ]
   [[ "$output" =~ "OpenAI API key command failed" ]]
   [[ "$output" =~ "OpenAI API key not found" ]]
}

@test "RT-15.5 empty Claude key command output reports failure without setting a key" {
   printf '%s\n' 'claude_api_key_command="printf \"\""' > "$TEST_HOME/.config/summarize-text/config"

   run env HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" "$PROJECT_ROOT/summarize-text" --claude "$PROJECT_ROOT/tests/regression/fixtures/sample.txt"

   [ "$status" -ne 0 ]
   [[ "$output" =~ "Claude API key command returned no key" ]]
   [[ "$output" =~ "Claude API key not found" ]]
}
