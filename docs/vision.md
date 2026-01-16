# Vision for summarize-text

## Purpose
Summarize-text is a versatile command-line tool that leverages AI to intelligently process text - either summarizing complex content into digestible insights or polishing rough drafts into refined prose.

## Core Philosophy
Text processing should be seamless, accessible from anywhere in your workflow, and adaptable to your preferred AI provider. The tool should feel like a natural extension of your command line, not a separate application.

## Problem We Solve
- Information overload from long articles, documents, and web pages
- Time wasted reading through verbose content to extract key points
- Inconsistent writing quality in drafts and communications
- Friction in accessing AI capabilities from the command line
- Lock-in to specific AI providers

## Design Principles

### 1. Universal Input/Output
Accept text from anywhere:
- Standard input (pipes)
- Files
- URLs
- Clipboard
- Text selection

Output anywhere:
- Standard output
- Clipboard
- Notifications
- Dialog boxes
- Direct typing

### 2. Provider Agnostic
- Support local models (Ollama) for privacy
- Support cloud providers (OpenAI, Claude) for power
- Automatic failover between providers
- Consistent interface regardless of backend

### 3. Dual Mode Operation
- **Summarize Mode**: Condense and extract insights
- **Polish Mode**: Refine and improve writing
- Same tool, different purposes, consistent interface

### 4. Unix Philosophy
- Do one thing well
- Work with pipes and standard streams
- Compose with other tools
- Text in, text out

## Future Direction

### Near Term
- Support for more AI providers
- Customizable summarization styles (technical, executive, educational)
- Language detection and translation
- Batch processing of multiple files
- Integration with popular note-taking apps

### Long Term
- Learning from user feedback to improve summaries
- Custom model fine-tuning based on user preferences
- Structured data extraction (JSON, CSV)
- Voice input/output support
- Real-time collaborative summarization

## Success Metrics
- Can process text from any source without friction
- Summaries capture the essence in 10% of original length
- Polished text is publication-ready
- Works seamlessly in shell scripts and automation
- Provider switching is transparent to the user

## Non-Goals
- Not a full document editor
- Not a translation service (though it can help)
- Not trying to replace human judgment
- Not storing or learning from user data
- Not requiring internet when local models suffice