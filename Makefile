#!/usr/bin/make -f
# ABOUTME: Build configuration for summarize-text project
# ABOUTME: Provides test targets and development installation

.PHONY: test install uninstall clean help

# Default target
help:
	@echo "Available targets:"
	@echo "  test      - Run all tests"
	@echo "  install   - Development install to /usr/local/bin (requires sudo)"
	@echo "  uninstall - Remove installed files (requires sudo)"
	@echo "  clean     - Clean up test artifacts"
	@echo "  help      - Show this help"
	@echo ""
	@echo "For production installation, use Homebrew:"
	@echo "  brew tap tigger04/tap"
	@echo "  brew install summarize-text"

# Run tests
test:
	@echo "Running configuration tests..."
	@./test/test_config.sh
	@echo "Running integration tests..."
	@./test/test_integration.sh
	@echo "All tests passed!"

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

# Clean test artifacts
clean:
	rm -rf test/tmp/
	rm -f test/*.log

# Create test directories if they don't exist
test/tmp:
	mkdir -p test/tmp