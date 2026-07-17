#!/usr/bin/env bash
# ABOUTME: Library for text summarization tools with AI model support
# ABOUTME: Provides OpenAI, Claude, and Ollama integration with flexible configuration

set -euo pipefail
IFS=$'\n\t'

# Check for bash v3.2+
if [ "${BASH_VERSINFO[0]}" -lt 3 ] || { [ "${BASH_VERSINFO[0]}" -eq 3 ] && [ "${BASH_VERSINFO[1]}" -lt 2 ]; }; then
	echo "This script requires bash 3.2 or higher." >&2
	echo "Current version: ${BASH_VERSION}" >&2
	exit 1
fi

# Load configuration
load_config() {
	local config_file="$HOME/.config/summarize-text/config"

	# Set defaults
	active_function=""
	ollama_model="mistral"
	openai_model="gpt-4o-mini"
	claude_model="claude-3-5-sonnet-20241022"
	source=STDIN
	source_identifier=""
	output_mode=STDOUT

	# Load from config file if exists
	if [[ -f "$config_file" ]]; then
		# shellcheck source=/dev/null  # SC1090: user config file, path varies
		source "$config_file"
	fi

	# Override with environment variables if set
	if [[ -n "${OPENAI_API_KEY:-}" || -n "${openai_api_key_command:-}" ]]; then
		openai_available=true
	else
		openai_available=false
	fi

	if [[ -n "${CLAUDE_API_KEY:-}" || -n "${claude_api_key_command:-}" ]]; then
		claude_available=true
	else
		claude_available=false
	fi
	[[ -n "${OLLAMA_API_URL:-}" ]] && ollama_available=true || ollama_available=false

	# Check if ollama is running locally
	if [[ -z "${OLLAMA_API_URL:-}" ]] && command -v ollama >/dev/null 2>&1; then
		if ollama list >/dev/null 2>&1; then
			ollama_available=true
		fi
	fi

	# Auto-detect default if not set
	if [[ -z "$active_function" ]]; then
		if [[ "$openai_available" == true ]]; then
			active_function="openai"
		elif [[ "$claude_available" == true ]]; then
			active_function="claude"
		elif [[ "$ollama_available" == true ]]; then
			active_function="ollama"
		else
			# Defer error to execution time so --help still works
			active_function=""
		fi
	fi

	# Override default from config or env
	if [[ -n "${DEFAULT_AI:-}" ]]; then
		active_function="${DEFAULT_AI}"
	fi
}

# Initialize configuration
load_config

# Resolve a provider key from a configured secrets-manager command.
load_api_key_command() {
	local provider_name="$1"
	local environment_name="$2"
	local key_command="$3"
	local key_value

	if [[ -z "$key_command" ]]; then
		return 0
	fi

	if ! key_value=$(/bin/sh -c "$key_command"); then
		echo "❌ $provider_name API key command failed." >&2
		return 0
	fi

	if [[ -z "$key_value" ]]; then
		echo "❌ $provider_name API key command returned no key." >&2
		return 0
	fi

	export "$environment_name=$key_value"
}

# Simple info function for logging
hline() {
	echo "️🔷️ $*" >&2
}

info() {
	echo "ℹ️ $*" >&2
}

# Ollama API handler
ollama() {
	# Check if using remote or local ollama
	if [[ -n "${OLLAMA_API_URL:-}" ]]; then
		# Use remote Ollama API
		result=$(curl "${OLLAMA_API_URL}/api/generate" \
			-s \
			-d "$(jq -n --arg model "$ollama_model" --arg prompt "$prompt" \
				'{model: $model, prompt: $prompt, stream: false}')" | jq -r '.response')
		output_result "$result"
		return
	fi

	# Use local ollama
	if ! command -v ollama >/dev/null 2>&1; then
		echo "❌ Ollama not found locally and OLLAMA_API_URL not set." >&2
		echo "Install Ollama or set OLLAMA_API_URL in ~/.config/summarize-text/config" >&2
		exit 1
	fi

	# Check if the model is available
	if ! ollama list | grep -q "^$ollama_model:"; then
		echo "⚠️ Model '$ollama_model' not found locally." >&2
		echo "Available models:" >&2
		ollama list >&2
		echo >&2
		read -p "Download '$ollama_model'? (y/N): " -n 1 -r >&2
		echo >&2
		if [[ "$REPLY" == [yY] ]]; then
			hline "Downloading model: $ollama_model"
			ollama pull "$ollama_model" || {
				echo "❌ Failed to download model '$ollama_model'." >&2
				exit 1
			}
		else
			echo "❌ Cannot proceed without the model. Exiting." >&2
			exit 1
		fi
	fi

	result=$(ollama run "$ollama_model" "$prompt")
	output_result "$result"
}

# OpenAI API handler
openai() {
	# Check if API key is available
	if [[ -z "${OPENAI_API_KEY:-}" ]]; then
		load_api_key_command "OpenAI" "OPENAI_API_KEY" "${openai_api_key_command:-}"
	fi

	if [[ -z "${OPENAI_API_KEY:-}" ]]; then
		# Try loading from legacy location
		if [[ -f ~/.ssh/.openai-api-key.sh ]]; then
			# shellcheck source=/dev/null
			source ~/.ssh/.openai-api-key.sh
		fi
	fi

	if [[ -z "${OPENAI_API_KEY:-}" ]]; then
		echo "❌ OpenAI API key not found. Please set OPENAI_API_KEY environment variable." >&2
		echo "Or add it to ~/.config/summarize-text/config as: export OPENAI_API_KEY='your-key'" >&2
		exit 1
	fi

	result=$(curl https://api.openai.com/v1/chat/completions \
		-s \
		-H "Authorization: Bearer $OPENAI_API_KEY" \
		-H "Content-Type: application/json" \
		-d "$(jq -n --arg prompt "$prompt" --arg model "$openai_model" \
			'{
            model: $model,
            messages: [
              {
                role: "user",
                content: $prompt
               }
            ]
      }')" | jq -r '.choices[0].message.content')
	output_result "$result"
}

# Claude API handler
claude() {
	# Check if API key is available
	if [[ -z "${CLAUDE_API_KEY:-}" ]]; then
		load_api_key_command "Claude" "CLAUDE_API_KEY" "${claude_api_key_command:-}"
	fi

	if [[ -z "${CLAUDE_API_KEY:-}" ]]; then
		# Try loading from legacy location
		if [[ -f ~/.ssh/.claude-api-key.sh ]]; then
			# shellcheck source=/dev/null
			source ~/.ssh/.claude-api-key.sh
		fi
	fi

	if [[ -z "${CLAUDE_API_KEY:-}" ]]; then
		echo "❌ Claude API key not found. Please set CLAUDE_API_KEY environment variable." >&2
		echo "Or add it to ~/.config/summarize-text/config as: export CLAUDE_API_KEY='your-key'" >&2
		exit 1
	fi

	hline "Summarizing text with Claude using API"

	result=$(curl https://api.anthropic.com/v1/messages \
		-s \
		-H "x-api-key: $CLAUDE_API_KEY" \
		-H "anthropic-version: 2023-06-01" \
		-H "Content-Type: application/json" \
		-d "$(jq -n --arg prompt "$prompt" --arg model "$claude_model" \
			'{
            model: $model,
            max_tokens: 4096,
            messages: [
              {
                role: "user",
                content: $prompt
               }
            ]
      }')" | jq -r '.content[0].text')
	output_result "$result"
}

# Construct prompt from input
construct_prompt() {
	prompt="$pre_prompt"$'\n\n'"--------"$'\n'
	while IFS= read -r line; do
		prompt+=$'\n'"$line"
	done
}

# Get clipboard content
get_clipboard_content() {
	if command -v pbpaste >/dev/null 2>&1; then
		# macOS
		pbpaste
	elif command -v xclip >/dev/null 2>&1; then
		# Linux with xclip
		xclip -selection clipboard -o
	elif command -v xsel >/dev/null 2>&1; then
		# Linux with xsel
		xsel --clipboard --output
	else
		echo "‼️ No clipboard utility found (pbpaste, xclip, or xsel)" >&2
		exit 1
	fi
}

# Get selection content (with delay for copy operation)
get_selection_content() {
	sleep 0.3
	get_clipboard_content
}

# Output result to various destinations
output_result() {
	local result="$1"

	case "$output_mode" in
	STDOUT)
		echo "$result"
		;;
	NOTIFICATION)
		if command -v notify >/dev/null 2>&1; then
			notify "$result"
		elif command -v osascript >/dev/null 2>&1; then
			# macOS fallback using osascript - escape quotes and limit length
			local notification_text
			notification_text="${result//\"/\\\"}"
			# Truncate if too long for notifications
			if [ ${#notification_text} -gt 200 ]; then
				notification_text="${notification_text:0:197}..."
			fi
			osascript -e "display notification \"$notification_text\" with title \"Text Summary\""
		else
			echo "‼️ ~/bin/notify not found and no notification fallback available" >&2
			echo "$result"
		fi
		;;
	DIALOG)
		if command -v dialog >/dev/null 2>&1; then
			dialog "$result"
		elif command -v osascript >/dev/null 2>&1; then
			# macOS fallback using osascript
			osascript -e "display dialog \"$result\" with title \"Text Summary\""
		else
			echo "‼️ ~/bin/dialog not found and no dialog fallback available" >&2
			echo "$result"
		fi
		;;
	TYPE)
		if command -v mactype >/dev/null 2>&1; then
			echo "$result" | mactype
		else
			echo "⚠️ ~/bin/mactype not found - outputting to stdout instead" >&2
			echo "$result"
		fi
		;;
	PASTE)
		if command -v pbcopy >/dev/null 2>&1; then
			# macOS - copy to clipboard
			echo "$result" | pbcopy
			echo "📋 Result copied to clipboard" >&2
		elif [[ "$OSTYPE" == "darwin"* ]]; then
			# macOS - attempt to paste using skhd
			echo "$result" | pbcopy
			echo "⚠️ skhd paste not implemented - result copied to clipboard instead" >&2
		elif command -v xclip >/dev/null 2>&1; then
			# Linux with xclip
			echo "$result" | xclip -selection clipboard
			echo "📋 Result copied to clipboard" >&2
		elif command -v xsel >/dev/null 2>&1; then
			# Linux with xsel
			echo "$result" | xsel --clipboard --input
			echo "📋 Result copied to clipboard" >&2
		else
			echo "‼️ No clipboard utility found - outputting to stdout" >&2
			echo "$result"
		fi
		;;
	*)
		echo "$result"
		;;
	esac
}

# Fetch content from URL
fetch_url_content() {
	local url="$1"
	if command -v curl >/dev/null 2>&1; then
		curl -s -L "$url" || {
			echo "❌ Failed to fetch URL: $url" >&2
			exit 1
		}
	elif command -v wget >/dev/null 2>&1; then
		wget -q -O - "$url" || {
			echo "❌ Failed to fetch URL: $url" >&2
			exit 1
		}
	else
		echo "‼️ Neither curl nor wget found" >&2
		exit 1
	fi
}

# Prepare file content - handle various file types with validation
prepare_file_content() {
	local filepath="$1"

	# Check if file exists
	if [[ ! -f "$filepath" ]]; then
		echo "‼️ File not found: $filepath" >&2
		exit 1
	fi

	# Detect MIME type
	local mime_type
	mime_type=$(file --mime-type -b "$filepath" 2>/dev/null)

	# Handle text files directly (including markdown, json, xml, etc.)
	if [[ "$mime_type" =~ ^text/ ]] || [[ "$mime_type" == "application/json" ]] || [[ "$mime_type" == "application/xml" ]] || [[ "$mime_type" == "inode/x-empty" ]]; then
		cat "$filepath"
		return 0
	fi

	# Handle PDF files with pdftotext
	if [[ "$mime_type" == "application/pdf" ]]; then
		if ! command -v pdftotext >/dev/null 2>&1; then
			echo "‼️ pdftotext not found. Install poppler-utils to process PDF files." >&2
			echo "   macOS: brew install poppler" >&2
			echo "   Linux: sudo apt install poppler-utils" >&2
			exit 1
		fi
		pdftotext "$filepath" - 2>/dev/null || {
			echo "‼️ Failed to extract text from PDF: $filepath" >&2
			exit 1
		}
		return 0
	fi

	# Try pandoc for other binary files (docx, odt, rtf, etc.)
	if command -v pandoc >/dev/null 2>&1; then
		if pandoc "$filepath" -t plain -o - 2>/dev/null; then
			return 0
		fi
	fi

	# Unsupported file type
	echo "‼️ Unsupported file type: $mime_type" >&2
	echo "File: $filepath" >&2
	echo "Supported types:" >&2
	echo "  - Text files (txt, md, json, xml, etc.)" >&2
	echo "  - PDF files (requires pdftotext from poppler-utils)" >&2
	echo "  - Document files (docx, odt, rtf, etc. - requires pandoc)" >&2
	exit 1
}

# Parse common command-line arguments
parse_common_arguments() {
	while [ $# -gt 0 ]; do
		case $1 in
		# AI Model options
		-l* | --ollama*)
			active_function=ollama
			if [[ $1 =~ =(.*)$ ]]; then
				ollama_model="${BASH_REMATCH[1]}"
			elif [[ "${1:2:1}" != "" && "${1:0:2}" == "-l" ]]; then
				# Handle -lmodel format
				ollama_model="${1:2}"
			fi
			;;
		-o* | --openai*)
			active_function=openai
			if [[ $1 =~ =(.*)$ ]]; then
				openai_model="${BASH_REMATCH[1]}"
			elif [[ "${1:2:1}" != "" && "${1:0:2}" == "-o" ]]; then
				# Handle -omodel format
				openai_model="${1:2}"
			fi
			;;
		--claude*)
			active_function=claude
			if [[ $1 =~ =(.*)$ ]]; then
				claude_model="${BASH_REMATCH[1]}"
			fi
			;;
		--preprompt* | --prompt*)
			if [[ $1 =~ =(.*)$ ]]; then
				pre_prompt="${BASH_REMATCH[1]}"
			else
				shift
				pre_prompt="$1"
			fi
			;;
		# Input modes
		-c | --clipboard)
			source=CLIPBOARD
			;;
		-s | --selection)
			source=SELECTION
			;;
		# Output modes
		-n | --notification)
			output_mode=NOTIFICATION
			;;
		-d | --dialog)
			output_mode=DIALOG
			;;
		-t | --type)
			output_mode=TYPE
			;;
		-p | --paste)
			output_mode=PASTE
			;;
		# Explicit stdin
		-)
			source=STDIN
			;;
		# URL input
		http://* | https://*)
			source=URL
			source_identifier="$1"
			;;
		# File input (default case)
		*)
			if [[ -f "$1" ]]; then
				source=FILE
				source_identifier="$1"
			else
				echo "‼️ Unknown argument or file not found: $1" >&2
				display_help_text_and_die
			fi
			;;
		esac
		shift
	done
}

# Dispatch to the active AI function via case statement
# Avoids executing $active_function as a command (prohibited pattern)
run_ai_function() {
	case "$active_function" in
	openai)
		openai
		;;
	claude)
		claude
		;;
	ollama)
		ollama
		;;
	*)
		echo "‼️ Unknown AI function: $active_function" >&2
		exit 1
		;;
	esac
}

# Validate that an AI service is available before processing
validate_ai_available() {
	if [[ -z "$active_function" ]]; then
		echo "⚠️ No AI service available. Please set OPENAI_API_KEY, CLAUDE_API_KEY, or ensure Ollama is running." >&2
		echo "You can also create a config file at ~/.config/summarize-text/config" >&2
		exit 1
	fi
}

# Execute processing based on source
execute_processing() {
	validate_ai_available
	case "$source" in
	STDIN)
		construct_prompt
		;;
	URL)
		hline "Fetching URL: $source_identifier"
		fetch_url_content "$source_identifier" | construct_prompt
		;;
	FILE)
		construct_prompt < <(prepare_file_content "$source_identifier")
		;;
	CLIPBOARD)
		construct_prompt < <(get_clipboard_content)
		;;
	SELECTION)
		construct_prompt < <(get_selection_content)
		;;
	*)
		echo "‼️ Unknown source: $source" >&2
		exit 1
		;;
	esac
}
