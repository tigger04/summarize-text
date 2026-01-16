#!/usr/bin/make -f
# ABOUTME: Build configuration for summarize-text project
# ABOUTME: Provides test targets and installation helpers

.PHONY: test install uninstall clean help

# Detect Homebrew prefix if available, otherwise use /usr/local
PREFIX ?= $(shell if command -v brew >/dev/null 2>&1; then brew --prefix; else echo /usr/local; fi)

# Default target
help:
	@echo "Available targets:"
	@echo "  test      - Run all tests"
	@echo "  install   - Install to $(PREFIX)/bin"
	@echo "  uninstall - Remove installed files"
	@echo "  clean     - Clean up test artifacts"
	@echo "  help      - Show this help"

# Run tests
test:
	@echo "Running configuration tests..."
	@./test/test_config.sh
	@echo "Running integration tests..."
	@./test/test_integration.sh
	@echo "All tests passed!"

# Install to system
install: summarize-text
	@echo "Installing to $(PREFIX)..."
	@install -d $(PREFIX)/bin
	@install -d $(PREFIX)/share/summarize-text
	@install -m 755 summarize-text $(PREFIX)/bin/
	@install -m 644 summarize-text-lib.sh $(PREFIX)/share/summarize-text/
	@echo "Installation complete: $(PREFIX)/bin/summarize-text"
	@if ! echo "$$PATH" | grep -q "$(PREFIX)/bin"; then \
		echo "WARNING: $(PREFIX)/bin is not in your PATH"; \
	fi

# Uninstall from system
uninstall:
	@echo "Uninstalling from $(PREFIX)..."
	@rm -f $(PREFIX)/bin/summarize-text
	@rm -rf $(PREFIX)/share/summarize-text
	@echo "Uninstall complete"

# Build the executable (ensures it exists and is executable)
summarize-text:
	@if [ ! -f summarize-text ]; then \
		echo "Error: summarize-text not found in current directory"; \
		exit 1; \
	fi
	@chmod +x summarize-text

# Clean test artifacts
clean:
	rm -rf test/tmp/
	rm -f test/*.log

# Create test directories if they don't exist
test/tmp:
	mkdir -p test/tmp