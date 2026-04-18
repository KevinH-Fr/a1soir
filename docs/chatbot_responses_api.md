# Chatbot Responses API configuration

This app uses OpenAI `responses` with a persistent conversation id saved per local visitor chat session.

## Visitor-only session model

- The public chatbot is bound to a `visitor_token` stored in Rails session/cookie.
- No `User` association is required for public visitors.
- Conversation history is stored locally in `chat_messages`.

## Required environment variables

- `OPENAI_API_KEY`
- `CHATBOT_ENABLED` (`true`/`false`)

## Prompt source of truth

- Versioned prompt file: `config/prompts/chatbot_system.txt`
- Fallback string in initializer if file is missing.

## Fixed runtime defaults (in repo)

- Model: `gpt-4.1-mini`
- Store mode: `true`
- To change these values, update `config/initializers/openai_chat.rb`.

## Tools and business logic

- Tool definitions and execution live in:
  - `app/services/chatbot/tool_dispatcher.rb`
  - `app/services/chatbot/generate_reply.rb`
- Business logic must stay in Rails services/models, not only in prompt text.
- Service URLs are generated dynamically from Rails route helpers + request host
  (not hardcoded in the prompt). `get_service_links` topics include `concept`
  (`le_concept`) and `autres_activites` (`nos_autres_activites`) in addition to
  rdv, cabine, contact, faq, legal, eshop, boutique.

## Removed legacy variable

- `OPENAI_ASSISTANT_ID` is no longer used.
