================================================================
                Loco AI - Installation Guide
                     LocoDev (c) 2026
================================================================

Loco AI is an AI assistant for Unreal Engine 5. You describe
gameplay in plain English in a chat panel; it builds the
Blueprint, components, variables, and wires directly in your
project.

Free plugin. BYOK ("bring your own key") or use your existing
Claude Pro / ChatGPT Plus subscription via the bundled CLI
adapters.

Full documentation: https://ai.locodev.dev/docs

By installing this plugin you accept the terms at
https://ai.locodev.dev/terms.

================================================================
 REQUIREMENTS
================================================================

- Unreal Engine 5.5, 5.6, or 5.7 (Win64). Use the zip that
  matches your engine version - LocoHelperAI_v<ver>_UE<engine>.zip.
  The compiled DLL is bound to a specific UE version, so a 5.5
  zip will not load in a 5.6 project.

- A Loco AI account. Sign up free at https://ai.locodev.dev.
  Sign-in happens through your browser the first time you open
  the chat panel - there is no password form inside the editor.

- One AI backend (pick whichever you already have or prefer):

   [A] Anthropic Direct - https://console.anthropic.com
       Best output quality for Blueprint work in our testing.

   [B] OpenAI Direct - https://platform.openai.com/api-keys
       Solid all-rounder. GPT-4o, GPT-4.1, GPT-5.

   [C] Google Gemini - https://aistudio.google.com/apikey
       Long-context, free tier available.

   [D] Groq - https://console.groq.com/keys
       Free tier with no credit card; fastest first-token
       latency. Great for iterating quickly.

   [E] OpenRouter / DeepSeek - per-token, no markup from us.

   [F] Claude Code CLI - if you already pay for Claude Pro or
       Max, install the CLI and Loco AI uses your subscription.
         Install:  npm install -g @anthropic-ai/claude-code
         Login:    claude login

   [G] OpenAI Codex CLI - same idea for ChatGPT Plus / Pro.
         Install:  npm install -g @openai/codex
         Login:    codex login

   [H] Ollama (local, offline) - https://ollama.com
       Run a model on your own machine, no API key needed.
       Quality depends on the model you load.

   [I] Custom API (any endpoint compatible with the OpenAI
       Chat Completions schema). Configure URL + key in
       Settings > AI > Custom API.

================================================================
 INSTALLATION
================================================================

1. Unzip this archive.

2. Copy the "LocoHelperAI" folder into the Plugins folder of
   your Unreal project:

      <YourProject>\Plugins\LocoHelperAI\

   Create the Plugins folder if it doesn't exist yet.

3. Close the Unreal Editor if it is running.

4. Open your .uproject. Unreal will ask whether to enable the
   plugin and may need to recompile its module - click YES.

5. Click the "Loco AI" icon on the editor toolbar.

6. Click Sign in. Your browser opens at ai.locodev.dev. Sign in
   (or sign up first), then come back to the editor - the chat
   panel will detect the handshake automatically.

7. Connect a backend in Settings > AI. Paste your provider key
   (or pick a CLI / Ollama / Custom). You're ready.

================================================================
 BASIC USAGE
================================================================

Type what you want in plain English. Examples:

   "Make BP_Coin a pickup. When the player overlaps it, add 1
    to a Coins counter on BP_ThirdPersonCharacter, play a
    sound, and destroy itself."

   "Add a damage system to BP_Enemy: 50 max health, dies when
    it hits 0, prints 'Enemy down!' and destroys itself."

   "Create BP_EnemySpawner. Spawn BP_Enemy every 3 seconds
    within 1000 units of itself."

The plugin wires everything: components, variables, exec chain,
data pins, even compile verification when you touch multiple
Blueprints.

Eight built-in templates ship in this version:

  - Pickup            (overlap -> effect -> destroy)
  - Damage system     (Event AnyDamage -> health -> death)
  - Raycast / interaction trace (input -> trace -> action)
  - Enemy             (contact damage + death drop)
  - Spawner           (timer-based actor spawner in a radius)
  - HUD widget tree   (health bar / score / ammo)
  - Pause menu        (input-mode swap + pause toggle, one call)
  - UI input mode     (game-paused + cursor swap helper)

Plus low-level graph authoring when your prompt doesn't match
a template. See https://ai.locodev.dev/docs/templates for the
full list and example prompts.

================================================================
 ELEVEN TOOLS
================================================================

Behind the scenes the AI has eleven tools available:

  read_blueprint                  - inspect variables /
                                    components / graphs / nodes
  edit_blueprint                  - create + modify Blueprint
                                    assets, add components,
                                    configure properties
  edit_graph                      - add / wire / delete graph
                                    nodes; apply templates
  execute_python                  - run editor Python automation
  explore                         - scan Content Browser +
                                    filesystem
  read_logs                       - read recent editor log lines
  code_search                     - grep symbols across UE +
                                    project source
  health_check                    - compile-verify every
                                    Blueprint touched this turn
  take_viewport_screenshot        - LevelEditor / PIE capture
  take_blueprint_graph_screenshot - graph diagram capture
  session_summary                 - condensed chat summary

Tool calls are gated by your Permission Mode (Auto Accept /
Ask Before Edit / Read Only) and by the Allow advanced Python
toggle in Settings > Tools.

================================================================
 MODEL ROUTING & SESSIONS
================================================================

- Auto Model Routing (off by default): the plugin classifies
  each prompt as Cheap / Standard / Strong and surfaces the
  recommended tier. Turn it on in Settings > Model Router for
  per-turn cost optimization.

- Auto Session Forking: when Auto Routing picks a different
  tier than the prior turn, the plugin transparently forks the
  Claude CLI session so the new tier runs at its native model
  (resume-safe; the prior session is preserved).

- Context Budget: an advisory soft cap on optional context the
  plugin attaches per turn. Auto / Low Cost / Balanced /
  Maximum / Custom. See the Ctx popover for the breakdown of
  new vs cached vs cache-write tokens.

================================================================
 MEMORY + CUSTOM RULES
================================================================

- Memory tab: short personal notes the AI keeps in mind across
  all chats in your account. Up to ~2000 chars total; each
  individual note is capped at 500 chars. Stored in your
  account, not in the project file.

- Custom Rules: per-project guidance the AI must follow on
  every turn. Two layers:

    Built-in rules (13, enabled by default) - opinionated
    defaults that catch common Blueprint mistakes: physics
    magnitude sanity, widget font defaults, audio asset
    references, trigger-box collision setup, actor completeness
    checks, blueprint inheritance, BP name literality, invisible
    trigger volumes, paired overlap events, no-auto-resume,
    editor-camera-no-touch, save-candidate suggestions. Toggle
    individually in Settings > Custom Rules.

    Your rules (optional) - add your own per-project guidance
    on top (e.g. "always use AIMoveTo, never AddMovementInput",
    "all NPCs must inherit from BP_BaseNPC"). Each is a small
    JSON blob with its own on/off toggle, stored in your
    project's settings file.

================================================================
 LIVE DASHBOARD (opt-in)
================================================================

ai.locodev.dev/dashboard/live lets you watch an active Loco AI
session from your phone or another machine. Two opt-in toggles
in Settings > Live Dashboard:

  Publish session presence  - heartbeat your project name,
  engine, plugin version, and "last seen" timestamp. No
  prompts, code, or content ever leave the machine.

  Accept remote commands    - lets the dashboard send you a
  small whitelist of safe commands (health_check,
  take_screenshot, read_logs, get_project_status, create_task).
  All commands are queued by default. Auto-submit is a separate
  Local-Dev-Only toggle.

  Remote-task permission floor (sub-setting, shown when remote
  commands are enabled): when a remote task auto-submits, the
  AI runs at no looser than this permission. Defaults to Read
  Only. Auto Accept requires an explicit in-app confirm dialog.

Both gates default OFF and the relay never auto-runs anything
that would let a remote / compromised account execute code on
your machine.

================================================================
 CLAUDE CODE BRIDGE (opt-in)
================================================================

If you use the standalone Claude Code workspace tool, you can
let it call the same Blueprint tools by enabling
Settings > Bridge > "Expose MCP to external callers".

The plugin mints a process-lifetime token, writes it to
<Project>\Saved\LocoAI\external-mcp-config.json, and accepts
authenticated requests on 127.0.0.1:19315/loco. Off by default;
token-gated; 127.0.0.1-only; never reachable from the LAN.

================================================================
 PLAN LIMITS
================================================================

Free plan:
  - All 11 tools, all 8 gameplay templates, every resolver
    heuristic. No prompt gate, no feature wall on core
    authoring.
  - Bring your own AI provider key (Anthropic, OpenAI, Gemini,
    Groq, OpenRouter, DeepSeek, Claude / Codex CLI, Ollama, or
    Custom API). The plugin doesn't charge per prompt; your AI
    provider does.
  - Default theme.
  - Read-only access to the community prompt library.

Standard ($10/mo):
  - Unlimited Loco AI generations (no monthly cap).
  - All 4 themes (Default, Light, OLED Black, Midnight Blue).
  - Unlimited custom rules per project.
  - Submit prompts to the community library.
  - Unlimited prompt polishes.
  - Best-effort email support.

Premium ($20/mo) — everything in Standard, plus:
  - Custom theme palette picker (pick your own 4 colors).
  - Premium prompt library (curated collections + advanced
    templates: combat, parkour, dialogue) not in the free catalog.
  - Priority Discord support: same-day reply from the dev.
  - Early access to new features (betas + experimental nodes).
  - Curated SFX library and procedural audio generation.
  - Persistent project memory beyond the free cap.

Compare plans: https://ai.locodev.dev/pricing

================================================================
 PRIVACY
================================================================

Your prompts and project files do NOT pass through us by
default. They go directly from your machine to the AI provider
you chose. We never see your provider tokens and we don't
charge a markup.

What we DO store, on our Supabase backend:

  - Your account: email, hashed password, plan, current
    month's prompt count.

  - Anonymous usage telemetry (on by default): tool names that
    ran, success / failure, plugin + engine version, crash
    stack traces. NO prompt text, NO AI responses, NO asset
    names. Turn off in Settings > Privacy > Anonymous
    telemetry.

  - Detailed diagnostics (off by default, new in v0.15.5):
    richer plumbing-level events (router decisions, compile
    results, memory-fetch timeouts, AI hallucinated node
    names, audit findings, token/cost ledger). Includes
    Blueprint names + /Game/... asset paths. Does NOT include
    prompt text, AI response text, account email, API keys,
    or OS user-folder paths. Consent dialog on first launch
    after updating to v0.15.5. Togglable any time. Full
    disclosure: https://ai.locodev.dev/privacy/telemetry

  - OPTIONAL prompt sharing (off by default): if you tick
    Settings > Privacy > Share prompt examples, your prompt +
    the AI's response text are uploaded too, alongside the
    anonymous telemetry. Helps us reproduce bugs faster.
    Togglable any time; we never collect this without your
    explicit opt-in.

  - Bug reports (per-report consent): Settings > Help > Report
    a bug opens a form to submit a description plus optional
    bundles (log tail, recent chat turns, viewport screenshot).
    Preview pane shows exact redacted payload before send.

Full privacy policy:  https://ai.locodev.dev/privacy
Privacy questions:    privacy@locodev.dev

================================================================
 SUPPORT
================================================================

  Discord:    https://discord.gg/ZB7SMbbxQz   (English)
              https://discord.gg/px7MtACkza   (Portuguese)
  Support:    support@locodev.dev
  Security:   security@locodev.dev   (responsible disclosure)
  Legal:      legal@locodev.dev
  Privacy:    privacy@locodev.dev
  Docs:       https://ai.locodev.dev/docs
  Bug fix:    Most reports get a fix within 24 hours.

If something doesn't work:

  1. Confirm your AI backend is connected and your provider
     account has credit / quota.
  2. Restart the Unreal Editor.
  3. Settings > Reset to defaults (clears local theme and
     custom-rule overrides without touching your account).
  4. Ping Discord with: plugin version (visible at the bottom
     of the sidebar in the chat panel), Unreal Engine version,
     what you typed, what happened.

================================================================
 LEGAL (SHORT VERSION)
================================================================

The Plugin is yours to use under a free license. The output
the Plugin generates for you is yours - ship it commercially,
no royalties, no permission needed.

You may NOT redistribute the Plugin itself, reverse-engineer
its binaries, or resell it as part of another product.

Full terms at https://ai.locodev.dev/terms.

================================================================
                       LocoDev (c) 2026
================================================================
