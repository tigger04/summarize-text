#!/usr/bin/env bats
# ABOUTME: One-off tests for the development installation target
# ABOUTME: Exercises make install and uninstall against an isolated prefix

setup() {
   PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
   PREFIX_DIR="$(mktemp -d)"
   FAKE_BIN="$PREFIX_DIR/fake-bin"
   mkdir -p "$FAKE_BIN"
   printf '%s\n' '#!/usr/bin/env bash' 'exit 99' > "$FAKE_BIN/sudo"
   chmod +x "$FAKE_BIN/sudo"
}

teardown() {
   trash -- "$PREFIX_DIR"
}

@test "OT-14.1 development installation creates command symlinks in an isolated prefix" {
   run env PATH="$FAKE_BIN:$PATH" make -C "$PROJECT_ROOT" install PREFIX="$PREFIX_DIR"
   [ "$status" -eq 0 ]

   for command_name in summarize-text polish-text smart-filename; do
      [ -L "$PREFIX_DIR/bin/$command_name" ]
      [ "$(readlink "$PREFIX_DIR/bin/$command_name")" = "$PROJECT_ROOT/$command_name" ]
   done
}

@test "OT-14.2 installed commands expose help and versions through development symlinks" {
   run env PATH="$FAKE_BIN:$PATH" make -C "$PROJECT_ROOT" install PREFIX="$PREFIX_DIR"
   [ "$status" -eq 0 ]

   for command_name in summarize-text polish-text smart-filename; do
      run "$PREFIX_DIR/bin/$command_name" --version
      [ "$status" -eq 0 ]
      [ "$output" = "$command_name $(cat "$PROJECT_ROOT/VERSION")" ]

      run "$PREFIX_DIR/bin/$command_name" --help
      [ "$status" -eq 0 ]
      [[ "$output" =~ "Usage" ]]
   done
}

@test "OT-14.3 development uninstallation removes only project command symlinks" {
   run env PATH="$FAKE_BIN:$PATH" make -C "$PROJECT_ROOT" install PREFIX="$PREFIX_DIR"
   [ "$status" -eq 0 ]

   run make -C "$PROJECT_ROOT" uninstall PREFIX="$PREFIX_DIR"
   [ "$status" -eq 0 ]
   [ -d "$PREFIX_DIR/bin" ]

   for command_name in summarize-text polish-text smart-filename; do
      [ ! -e "$PREFIX_DIR/bin/$command_name" ]
      [ ! -L "$PREFIX_DIR/bin/$command_name" ]
   done
}
