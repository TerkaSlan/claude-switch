# claude-switch

Run two Claude Code profiles side-by-side on one machine — e.g. a custom LLM gateway **and** your personal Anthropic (claude.ai) subscription — with a one-word switch.

- `claude` → primary / custom gateway profile (default)
- `claude-ant` → personal Anthropic profile

<video src="demo.mp4" controls width="100%"></video>

> If the inline player above doesn't render in your GitHub view, open [demo.mp4](./demo.mp4) directly.

---

## The problem

Claude Code stores per-installation auth in `~/.claude/` and reads env vars:

| Var | Purpose |
| --- | --- |
| `ANTHROPIC_BASE_URL` | Custom API endpoint (a self-hosted gateway, a proxy, …) |
| `ANTHROPIC_AUTH_TOKEN` / `ANTHROPIC_API_KEY` | Auth header |
| `ANTHROPIC_MODEL`, `ANTHROPIC_DEFAULT_*_MODEL` | Model overrides |

You typically set these in `~/.claude/settings.json` so they don't pollute your shell:

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://llm.example.com/",
    "ANTHROPIC_AUTH_TOKEN": "sk-…",
    "ANTHROPIC_MODEL": "…"
  }
}
```

That works fine for one profile. But when you also want a **personal Anthropic subscription** (OAuth login at claude.ai), you hit two failure modes:

1. **The env vars leak.** The values from the gateway's `settings.json` end up exported into the shell that Claude spawns, so subshells and any future `claude` invocations inherit them. They override the OAuth flow and you get the dreaded:

   > `⚠ claude.ai connectors are disabled because ANTHROPIC_API_KEY or another auth source is set…`

2. **`CLAUDE_CONFIG_DIR` is the obvious answer but it breaks onboarding state.** Setting `CLAUDE_CONFIG_DIR=~/.claude` redirects the *whole* state, including `~/.claude/.claude.json` — which is then a fresh file, and Claude walks you through "first start" again as if you'd never used it.

## The fix

Two shell functions. Both strip every `ANTHROPIC_*` override, then:

- `claude` — runs the default install with **no `CLAUDE_CONFIG_DIR`**. It picks up the existing `~/.claude/settings.json` (your custom gateway) **and** the existing `~/.claude.json` (your real onboarding state). Exactly what you had before.
- `claude-ant` — runs with `CLAUDE_CONFIG_DIR=~/.claude-personal`. That's a fully isolated second profile: its own onboarding, its own OAuth login against claude.ai, its own plugins/history/settings.

```bash
# --- Claude profile switching ---
# Plain `claude`     = primary profile (e.g. a custom LLM gateway), reads
#                      ~/.claude/settings.json and ~/.claude.json as before.
# `claude-ant`       = isolated profile in ~/.claude-personal — authenticate it
#                      once with an Anthropic / claude.ai account.
# Both functions strip inherited ANTHROPIC_* env vars so values exported by a
# parent claude session never leak across profiles.
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
```

Append to `~/.bashrc` (or `~/.zshrc`), then `source ~/.bashrc`.

### Why these particular details matter

- **`env -u VAR …`** unsets a fixed list before exec, instead of starting from `env -i`. You keep PATH/HOME/etc. untouched and only remove the vars that would otherwise override per-profile config.
- **No `CLAUDE_CONFIG_DIR` for the default profile.** Leaving it unset is what makes the default profile keep working exactly as before — same onboarding state, same plugins, same history. Setting it explicitly to `~/.claude` would re-trigger onboarding because the state file Claude looks up changes location.
- **`$(command -v claude)`** resolves to the real binary, not the function itself, avoiding infinite recursion.

### First-time setup of the personal profile

Once, after adding the functions:

```bash
claude-ant
```

Claude will walk you through onboarding (theme, shortcuts) and then trigger OAuth login in your browser. From then on, `claude-ant` launches straight into your Anthropic-subscription session.

## How it works

```
┌─────────────────────────────────────────────────────────┐
│ ~/.claude/                  ~/.claude-personal/         │
│ ├── settings.json           ├── settings.json           │
│ │   └── env.ANTHROPIC_* ──→ │   └── (no env block)      │
│ │       custom gateway      ├── .credentials.json       │
│ ├── .credentials.json   │   │   └── OAuth tokens        │
│ ├── plugins/, skills/   │   ├── plugins/, skills/       │
│ └── …                   │   └── …                       │
│                         │                               │
│ ~/.claude.json  ←─────────┘  (global onboarding state,  │
│   (shared default profile)   not touched by claude-ant) │
└─────────────────────────────────────────────────────────┘

         ┌──── claude ────→ strips ANTHROPIC_* ────┐
shell ───┤                                          ├─→ ~/.claude (default)
         └──── claude-ant ─→ strips ANTHROPIC_* ────┴─→ ~/.claude-personal
                                                       + CLAUDE_CONFIG_DIR
```

Each function:
1. Removes any inherited `ANTHROPIC_*` overrides from the calling shell (and from any parent Claude session that may have exported them).
2. Resolves the real `claude` binary.
3. Either launches with the default config dir (no `CLAUDE_CONFIG_DIR` set) or with the personal one.

No state file is shared between profiles except the global `~/.claude.json` onboarding marker — and that's only read by the default profile.

## Customising

- **Rename `claude-ant`.** Pick a name that matches what the second profile is for (`claude-work`, `claude-aws`, …). The function body doesn't care.
- **More profiles.** Copy the `claude-ant` function and point `CLAUDE_CONFIG_DIR` at a new directory. Each gets a fresh, isolated profile.
- **Different stripping policy.** If you also need to unset other vars (custom proxies, `HTTPS_PROXY`, …), add more `-u` flags.

## Trade-offs / non-goals

- The list of stripped vars is **static**. If a future Claude version introduces a new overriding env var, you'll need to add it to the list.
- The two profiles don't share plugins, skills, hooks, or session history. If you want the same `settings.json` tweaks in both, manage them as two files (or symlink, at your own risk — the README deliberately doesn't).

## Troubleshooting

- **`claude` keeps showing onboarding.** You probably have an explicit `CLAUDE_CONFIG_DIR=~/.claude` somewhere (an old alias, an exported var). Remove it — the whole point is that the default profile *doesn't* set that var.
- **`claude-ant` says connectors are disabled / uses the wrong endpoint.** An `ANTHROPIC_*` var is still leaking in. Run `env | grep ANTHROPIC` in a fresh shell. Whatever's set there, add to the `-u` list.
- **Want to verify which profile you're in?** Inside Claude, run `/status` — it reports the active config dir and the auth source.
