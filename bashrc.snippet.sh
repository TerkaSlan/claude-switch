# --- Claude profile switching ---
# Append to ~/.bashrc (or ~/.zshrc). Then: source ~/.bashrc
#
# Plain `claude`  → primary profile (e.g. a custom LLM gateway). Uses the
#                   default ~/.claude directory; deliberately does NOT set
#                   CLAUDE_CONFIG_DIR so the existing onboarding state in
#                   ~/.claude.json is preserved.
# `claude-ant`    → isolated secondary profile in ~/.claude-personal.
#                   Authenticate once with an Anthropic / claude.ai account.
#
# Both functions strip inherited ANTHROPIC_* env vars so values exported by
# a parent claude session (or by accident elsewhere) don't leak across
# profiles. Add more `-u` flags here if you have other overriding vars.

claude() {
  env -u ANTHROPIC_BASE_URL -u ANTHROPIC_AUTH_TOKEN -u ANTHROPIC_API_KEY \
      -u ANTHROPIC_MODEL -u ANTHROPIC_DEFAULT_OPUS_MODEL \
      -u ANTHROPIC_DEFAULT_SONNET_MODEL -u ANTHROPIC_DEFAULT_HAIKU_MODEL \
      "$(command -v claude)" "$@"
}

claude-ant() {
  env -u ANTHROPIC_BASE_URL -u ANTHROPIC_AUTH_TOKEN -u ANTHROPIC_API_KEY \
      -u ANTHROPIC_MODEL -u ANTHROPIC_DEFAULT_OPUS_MODEL \
      -u ANTHROPIC_DEFAULT_SONNET_MODEL -u ANTHROPIC_DEFAULT_HAIKU_MODEL \
      CLAUDE_CONFIG_DIR="$HOME/.claude-personal" "$(command -v claude)" "$@"
}
