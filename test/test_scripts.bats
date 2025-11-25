#!/usr/bin/env bats

# Test suite for summarize-text tools

setup() {
   # Get the project root directory
   PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
   export PATH="$PROJECT_ROOT:$PATH"
}

# Test library bash version check
@test "library requires bash 5.0+" {
   # Test with current bash (should be 5+)
   run bash -c "source '$PROJECT_ROOT/summarize-text-lib.sh' 2>&1"
   [ "$status" -eq 0 ]
}

# Test summarize-text exists and is executable
@test "summarize-text is executable" {
   [ -x "$PROJECT_ROOT/summarize-text" ]
}

# Test polish-text exists and is executable
@test "polish-text is executable" {
   [ -x "$PROJECT_ROOT/polish-text" ]
}

# Test smart-filename exists and is executable
@test "smart-filename is executable" {
   [ -x "$PROJECT_ROOT/smart-filename" ]
}

# Test summarize-text help
@test "summarize-text --help works" {
   run "$PROJECT_ROOT/summarize-text" --help
   [ "$status" -eq 1 ]  # Help exits with 1
   [[ "$output" =~ "USAGE" ]]
   [[ "$output" =~ "Summarize" ]]
}

# Test polish-text help
@test "polish-text --help works" {
   run "$PROJECT_ROOT/polish-text" --help
   [ "$status" -eq 1 ]  # Help exits with 1
   [[ "$output" =~ "USAGE" ]]
   [[ "$output" =~ "Polish" ]]
}

# Test smart-filename help
@test "smart-filename --help works" {
   run "$PROJECT_ROOT/smart-filename" --help
   [ "$status" -eq 1 ]  # Help exits with 1
   [[ "$output" =~ "USAGE" ]]
   [[ "$output" =~ "smart filename" ]]
}

# Test that library functions are sourced correctly
@test "library functions are available after sourcing" {
   run bash -c "source '$PROJECT_ROOT/summarize-text-lib.sh' && declare -f info"
   [ "$status" -eq 0 ]
   [[ "$output" =~ "info" ]]
}

# Test library has correct default values
@test "library sets correct default openai_model" {
   run bash -c "source '$PROJECT_ROOT/summarize-text-lib.sh' && echo \$openai_model"
   [ "$status" -eq 0 ]
   [ "$output" = "gpt-4" ]
}

# Test that scripts are no longer symlinks
@test "polish-text is not a symlink" {
   [ ! -L "$PROJECT_ROOT/polish-text" ]
}

@test "smart-filename is not a symlink" {
   [ ! -L "$PROJECT_ROOT/smart-filename" ]
}

# Test that each script has unique pre_prompt
@test "summarize-text has correct pre_prompt" {
   run grep "pre_prompt=" "$PROJECT_ROOT/summarize-text"
   [ "$status" -eq 0 ]
   [[ "$output" =~ "Briefly summarize" ]]
}

@test "polish-text has correct pre_prompt" {
   run grep "pre_prompt=" "$PROJECT_ROOT/polish-text"
   [ "$status" -eq 0 ]
   [[ "$output" =~ "sharpen and improve" ]]
}

@test "smart-filename has correct pre_prompt" {
   run grep "pre_prompt=" "$PROJECT_ROOT/smart-filename"
   [ "$status" -eq 0 ]
   [[ "$output" =~ "Generate a concise" ]]
}

# Test smart-filename has -y flag support
@test "smart-filename help mentions -y flag" {
   run "$PROJECT_ROOT/smart-filename" --help
   [[ "$output" =~ "-y" ]] || [[ "$output" =~ "--yes" ]]
}

# Test symlink support
@test "summarize-text works via symlink" {
   # Create temporary directory and symlink
   TEMP_DIR=$(mktemp -d)
   ln -s "$PROJECT_ROOT/summarize-text" "$TEMP_DIR/summarize-test-link"

   # Test that help works via symlink
   run "$TEMP_DIR/summarize-test-link" --help
   [ "$status" -eq 1 ]  # Help exits with 1
   [[ "$output" =~ "USAGE" ]]

   # Cleanup
   rm -rf "$TEMP_DIR"
}

@test "polish-text works via symlink" {
   # Create temporary directory and symlink
   TEMP_DIR=$(mktemp -d)
   ln -s "$PROJECT_ROOT/polish-text" "$TEMP_DIR/polish-test-link"

   # Test that help works via symlink
   run "$TEMP_DIR/polish-test-link" --help
   [ "$status" -eq 1 ]  # Help exits with 1
   [[ "$output" =~ "USAGE" ]]

   # Cleanup
   rm -rf "$TEMP_DIR"
}

@test "smart-filename works via symlink" {
   # Create temporary directory and symlink
   TEMP_DIR=$(mktemp -d)
   ln -s "$PROJECT_ROOT/smart-filename" "$TEMP_DIR/smart-test-link"

   # Test that help works via symlink
   run "$TEMP_DIR/smart-test-link" --help
   [ "$status" -eq 1 ]  # Help exits with 1
   [[ "$output" =~ "USAGE" ]]

   # Cleanup
   rm -rf "$TEMP_DIR"
}
