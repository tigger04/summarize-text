#!/usr/bin/env bash
# summarize-text library - shared functions for text summarization tools

# Check for bash v3.2+
if [ "${BASH_VERSINFO[0]}" -lt 3 ] || ([ "${BASH_VERSINFO[0]}" -eq 3 ] && [ "${BASH_VERSINFO[1]}" -lt 2 ]); then
   echo "This script requires bash 3.2 or higher." >&2
   echo "Current version: ${BASH_VERSION}" >&2
   exit 1
fi

# Default configuration
active_function=openai
ollama_model=mistral
openai_model=gpt-5
source=STDIN
source_identifier=""
output_mode=STDOUT

# Simple info function for logging
hline() {
   echo "️🔷️ $*" >&2
}

# Ollama API handler
ollama() {
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
claude() {
   # shellcheck source=/dev/null
   source ~/.ssh/.claude-api-key.sh

   hline "Summarizing text with Claude using API"
   
   if [ -z "$CLAUDE_API_KEY" ]; then
      echo "‼️ CLAUDE_API_KEY environment variable not set" >&2
      exit 1
   fi

   result=$(curl https://api.anthropic.com/v1/messages \
      -s \
      -H "x-api-key: $CLAUDE_API_KEY" \
      -H "anthropic-version: 2023-06-01" \
      -H "Content-Type: application/json" \
      -d "$(jq -n --arg prompt "$prompt" \
         '{
            model: "claude-opus-4-20250514",
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
      construct_prompt < <(prepare_file_content "$source_identifier")
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
