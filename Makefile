.PHONY: test clean help

# Default target
help:
	@echo "Available targets:"
	@echo "  make test   - Run all tests using bats-core"
	@echo "  make clean  - Remove temporary files"
	@echo "  make help   - Show this help message"

# Run all tests
test:
	@echo "Running tests with bats-core..."
	@bats test/test_scripts.bats

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@find . -name "*.bak" -delete
	@find . -name "*~" -delete
