#!/usr/bin/make -f
# ABOUTME: Build configuration for summarize-text project
# ABOUTME: Provides test, release, sync, and installation targets

VERSION := $(shell cat VERSION 2>/dev/null || echo "0.0.0")
TAP_REPO := tigger04/homebrew-tap
FORMULA := Formula/summarize-text.rb

.PHONY: test test-one-off install uninstall clean help release sync

# Default target
help:
	@echo "Available targets:"
	@echo "  test          - Run regression tests"
	@echo "  test-one-off  - Run one-off tests (ISSUE=N for specific issue)"
	@echo "  install       - Development install to /usr/local/bin (requires sudo)"
	@echo "  uninstall     - Remove installed files (requires sudo)"
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

# Development install (requires sudo)
install: summarize-text
	@echo "Installing to /usr/local/bin (requires sudo)..."
	@echo "Creating directories..."
	@sudo install -d /usr/local/bin
	@sudo install -d /usr/local/share/summarize-text
	@echo "Installing files..."
	@sudo install -m 755 summarize-text /usr/local/bin/
	@sudo install -m 644 summarize-text-lib.sh /usr/local/share/summarize-text/
	@echo "Installation complete: /usr/local/bin/summarize-text"

# Uninstall (requires sudo)
uninstall:
	@echo "Uninstalling from /usr/local (requires sudo)..."
	@sudo rm -f /usr/local/bin/summarize-text
	@sudo rm -rf /usr/local/share/summarize-text
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
