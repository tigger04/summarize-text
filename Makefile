#!/usr/bin/make -f
# ABOUTME: Build configuration for summarize-text project
# ABOUTME: Provides test, release, sync, and installation targets

VERSION := $(shell cat VERSION 2>/dev/null || echo "0.0.0")
TAP_REPO := tigger04/homebrew-tap
FORMULA := Formula/summarize-text.rb

PREFIX ?= $(HOME)/.local
BIN_DIR := $(PREFIX)/bin
COMMANDS := summarize-text polish-text smart-filename

.PHONY: test test-one-off install uninstall clean help release sync

# Default target
help:
	@echo "Available targets:"
	@echo "  test          - Run regression tests"
	@echo "  test-one-off  - Run one-off tests (ISSUE=N for specific issue)"
	@echo "  install       - Symlink development commands to $(BIN_DIR)"
	@echo "  uninstall     - Remove development command symlinks"
	@echo "  release       - Tag release and update Homebrew formula"
	@echo "                  VERSION=x.y.z to set specific version"
	@echo "                  SKIP_TESTS=1 to bypass test step"
	@echo "  sync          - Git add, commit, pull, push"
	@echo "  clean         - Clean up test artifacts"
	@echo "  help          - Show this help (current version: $(VERSION))"
	@echo ""
	@echo "For production installation, use Homebrew:"
	@echo "  brew tap tigger04/tap"
	@echo "  brew install summarize-text"

# Run regression tests
test:
	@echo "Running tests with bats-core..."
	@bats tests/regression/test_scripts.bats
	@bats tests/regression/test_key_commands.bats
	@echo "Running configuration tests..."
	@./tests/regression/test_config.sh
	@echo "Running integration tests..."
	@./tests/regression/test_integration.sh
	@echo "All tests passed!"

# Run one-off tests
test-one-off:
ifdef ISSUE
	@bats tests/one_off/ --filter "$(ISSUE)"
else
	@bats tests/one_off/
endif

# Release: increment version, tag, update Homebrew formula
release:
ifndef SKIP_TESTS
	@$(MAKE) test
endif
ifdef VERSION
	@echo "$(VERSION)" > VERSION
endif
	$(eval RELEASE_VERSION := $(shell cat VERSION))
	@echo "Releasing v$(RELEASE_VERSION)..."
	@git add VERSION
	@git diff --cached --quiet || git commit -m "release: v$(RELEASE_VERSION)"
	@git tag -a "v$(RELEASE_VERSION)" -m "Release v$(RELEASE_VERSION)"
	@git push origin master
	@git push origin "v$(RELEASE_VERSION)"
	@echo "Updating Homebrew formula..."
	@ARCHIVE_URL="https://github.com/tigger04/summarize-text/archive/refs/tags/v$(RELEASE_VERSION).tar.gz"; \
	TMP_ARCHIVE=$$(mktemp); \
	curl -sL "$$ARCHIVE_URL" -o "$$TMP_ARCHIVE"; \
	SHA=$$(shasum -a 256 "$$TMP_ARCHIVE" | cut -d' ' -f1); \
	rm -f "$$TMP_ARCHIVE"; \
	echo "SHA256: $$SHA"; \
	FORMULA_CONTENT=$$(gh api "repos/$(TAP_REPO)/contents/$(FORMULA)" --jq '.content' | base64 -d); \
	UPDATED=$$(echo "$$FORMULA_CONTENT" | \
		sed "s|url \".*\"|url \"$$ARCHIVE_URL\"|" | \
		sed "s|sha256 \".*\"|sha256 \"$$SHA\"|"); \
	echo "$$UPDATED" | gh api "repos/$(TAP_REPO)/contents/$(FORMULA)" \
		--method PUT \
		--field message="Update summarize-text to v$(RELEASE_VERSION)" \
		--field content=@- \
		--field sha="$$(gh api "repos/$(TAP_REPO)/contents/$(FORMULA)" --jq '.sha')" \
		--input - > /dev/null; \
	echo "Homebrew formula updated to v$(RELEASE_VERSION)"

# Sync: add, commit, pull, push
sync:
	@git add --all
	@git diff --cached --quiet && echo "Nothing to commit" || git commit -m "sync"
	@git pull
	@git push

# Development install
install:
	@echo "Installing development symlinks to $(BIN_DIR)..."
	@install -d "$(BIN_DIR)"
	@for command_name in $(COMMANDS); do \
		target="$(BIN_DIR)/$$command_name"; \
		if [ -e "$$target" ] || [ -L "$$target" ]; then \
			if [ ! -L "$$target" ] || [ "$$(readlink "$$target")" != "$(CURDIR)/$$command_name" ]; then \
				echo "Refusing to replace existing path: $$target" >&2; \
			exit 1; \
			fi; \
		fi; \
		ln -sfn "$(CURDIR)/$$command_name" "$$target"; \
	done
	@echo "Installation complete: $(BIN_DIR)"

# Development uninstall
uninstall:
	@echo "Removing development symlinks from $(BIN_DIR)..."
	@for command_name in $(COMMANDS); do \
		target="$(BIN_DIR)/$$command_name"; \
		if [ -L "$$target" ] && [ "$$(readlink "$$target")" = "$(CURDIR)/$$command_name" ]; then \
			trash -- "$$target"; \
		fi; \
	done
	@echo "Uninstall complete"

# Build the executable (ensures it exists and is executable)
summarize-text:
	@if [ ! -f summarize-text ]; then \
		echo "Error: summarize-text not found in current directory"; \
		exit 1; \
	fi
	@chmod +x summarize-text

# Clean test artifacts and temporary files
clean:
	rm -rf tests/regression/tmp/
	rm -f tests/regression/*.log
	@find . -name "*.bak" -delete
	@find . -name "*~" -delete
