<!-- Version: 1.0 | Last updated: 2026-03-19 -->

# Testing

## Framework

Tests use [bats-core](https://github.com/bats-core/bats-core) for the main test suite, plus custom bash test scripts for configuration and integration testing.

## Directory Structure

```
tests/
  regression/          ← run by `make test`
    test_scripts.bats  ← main bats test suite
    test_config.sh     ← configuration system tests
    test_integration.sh ← integration/file operation tests
    fixtures/          ← sample files for testing
      sample.txt
      sample.md
      sample.pdf
      sample.docx
      sample.png
  one_off/             ← run by `make test-one-off`; never by `make test`
    .gitkeep
  NEXT_IDS.txt         ← test ID allocation counter
```

## Running Tests

```bash
make test              # Run all regression tests
make test-one-off      # Run all one-off tests
make test-one-off ISSUE=42  # Run one-off tests for a specific issue
```

## Test Categories

### Bats Tests (`test_scripts.bats`)

The main test suite covering:
- Script executability
- Help output correctness
- Library function availability and defaults
- Symlink support
- File type handling (`prepare_file_content`)
- Pre-prompt correctness per script

### Configuration Tests (`test_config.sh`)

Tests for the configuration system:
- Config directory creation
- Environment variable detection
- Config file creation and sourcing
- Variable override precedence

### Integration Tests (`test_integration.sh`)

Basic integration tests:
- Required file existence
- Script permissions
- Config directory handling
- Example config file presence

## Test IDs

All new tests must carry a unique ID (see `tests/NEXT_IDS.txt`):

| Prefix | Type | Location |
|--------|------|----------|
| `RT-NNN` | Regression | `tests/regression/` |
| `OT-NNN` | One-off | `tests/one_off/` |

Legacy tests without IDs are not retrofitted — they receive IDs when next modified.

## Adding Tests

1. Determine if the test is regression or one-off
2. Allocate an ID from `tests/NEXT_IDS.txt`
3. Place the test in the appropriate directory
4. Follow AAA (Arrange-Act-Assert) structure
5. Use descriptive test names: `test_<unit>_<scenario>_<expected_result>`
