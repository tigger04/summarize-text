#!/usr/bin/env bash
# summarize-text library - shared functions for text summarization tools

# Check for bash v5.0+
if [ "${BASH_VERSINFO[0]}" -lt 5 ]; then
   echo "This script requires bash 5.0 or higher." >&2
   echo "Current version: ${BASH_VERSION}" >&2
   exit 1
fi

# Default configuration
active_function=openai_summarize
ollama_model=mistral
openai_model=gpt-4
source=STDIN
source_identifier=""
output_mode=STDOUT

# Simple info function for logging
info() {
   echo "🔷️🔷️🔷️ $* 🔷️🔷️🔷️" >&2
}

# Ollama API handler
ollama_summarize() {
   if ! command -v ollama >/dev/null 2>&1; then
      echo "‼️ Ollama not found. Is it installed?" >&2
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
      if [[ "${REPLY,,}" == y ]]; then
         info "Downloading model: $ollama_model"
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
openai_summarize() {
   # shellcheck source=/dev/null
   source ~/.ssh/.openai-api-key.sh

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
claude_summarize() {
   command -v claude >/dev/null 2>&1 || exit 1
   # shellcheck source=/dev/null
   source ~/.ssh/.claude-api-key.sh
   result=$(claude "$prompt")
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

# Parse common command-line arguments
parse_common_arguments() {
   while [ $# -gt 0 ]; do
      case $1 in
      # AI Model options
      -l* | --ollama*)
         active_function=ollama_summarize
         if [[ $1 =~ =(.*)$ ]]; then
            ollama_model="${BASH_REMATCH[1]}"
         fi
         ;;
      -o* | --openai*)
         active_function=openai_summarize
         if [[ $1 =~ =(.*)$ ]]; then
            openai_model="${BASH_REMATCH[1]}"
         fi
         ;;
      --claude)
         active_function=claude_summarize
         ;;
      --preprompt*)
         if [[ $1 =~ =(.*)$ ]]; then
            pre_prompt="${BASH_REMATCH[1]}"
         else
            shift
            pre_prompt="$1"
         fi
         ;;
      # Input options
      -c | --clipboard)
         source=CLIPBOARD
         ;;
      -s | --selection)
         source=SELECTION
         ;;
      # Output options
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
      # URL input
      http://* | https://*)
         source=URL
         source_identifier="$1"

         command -v curl >/dev/null 2>&1 && command -v html2text >/dev/null 2>&1 || {
            echo "‼️ curl and html2text are required to fetch and convert HTML content." >&2
            exit 1
         }

         ;;
      # File input (default case)
      *)
         source=FILE
         source_identifier="$1"
         ;;
      esac
      shift
   done
}

# Execute the main processing based on source type
execute_processing() {
   case "$source" in
   STDIN)
      construct_prompt
      ;;
   URL)
      construct_prompt < <(curl -s "$source_identifier" | html2text)
      ;;
   FILE)
      construct_prompt <"$source_identifier"
      ;;
   CLIPBOARD)
      construct_prompt < <(get_clipboard_content)
      ;;
   SELECTION)
      construct_prompt < <(get_selection_content)
      ;;
   *)
      echo "Unknown source type: $source" >&2
      exit 1
      ;;
   esac
}
