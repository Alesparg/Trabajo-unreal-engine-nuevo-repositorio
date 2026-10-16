/**
 * bridge-mock.js
 *
 * In-browser stub of the C++ <-> JS bridge that the plugin's WebUI uses.
 * Loaded BEFORE the rest of the plugin code so window.bridge is defined
 * by the time anything touches it.
 *
 * Strategy:
 *   1. Hand-coded canned responses for the ~20 getters that drive UI state
 *      (plan info, sessions, settings, model, theme, backend, version, etc.).
 *   2. A Proxy fallback for everything else: any unknown bridge.* call
 *      returns a Promise that resolves to a sensible default ('' / false /
 *      undefined depending on the verb prefix) and logs the call so we
 *      can see what the page tried to do.
 *
 * Side effect of the Proxy: we don't have to enumerate every UFUNCTION on
 * ULocoBridge, which is ~80+ methods and growing. New bridge methods added
 * to the C++ side automatically get a no-op stub here.
 */
(function () {
  'use strict';

  // -------- Canned response payloads (match the real RPC shapes) --------

  const FAKE_USER_ID = '00000000-1111-2222-3333-444455556666';
  const FAKE_EMAIL = 'demo@locodev.dev';
  const FAKE_VERSION = '0.13.31';

  const planInfo = {
    plan: 'free',
    status: 'active',
    monthly_count: 23,
    cap: 500,
    polish_count: 7,
    polish_cap: 50,
    custom_rules_max: 10,
    isConnected: true,
    email: FAKE_EMAIL,
    userId: FAKE_USER_ID,
  };

  // Match the loco_get_plan RPC shape (used by the WebUI's tier badge)
  const planRpcResp = JSON.stringify({
    ok: true,
    plan: 'free',
    status: 'active',
    monthly_count: 23,
    cap: 500,
    features: { custom_rules_max: 10, premium_prompts: false, advanced_templates: false },
  });

  const rulesPayload = JSON.stringify({
    builtins: [
      { id: 'audio-ref', name: 'Audio reference', enabled: true,
        body: 'Sound nodes must wire a SoundCue/SoundWave variable, never a literal asset path.' },
      { id: 'trigger-collision', name: 'Trigger box collision', enabled: true,
        body: 'Trigger boxes use Custom profile + set_collision_response_to_all_channels(OVERLAP).' },
      { id: 'actor-completeness', name: 'Actor in world completeness', enabled: true,
        body: 'Created actors get a visible mesh, are spawned near PlayerStart, and saved to disk.' },
      { id: 'bp-inheritance', name: 'Blueprint inheritance trap', enabled: true,
        body: 'Cross-actor state reads must go through Get Player Character + Cast.' },
      { id: 'invisible-trigger', name: 'Invisible trigger volume', enabled: true,
        body: 'Field/zone/volume BPs get NO StaticMeshComponent.' },
      { id: 'paired-overlap', name: 'Paired overlap events', enabled: true,
        body: 'When OnActorBeginOverlap establishes persistent state, also wire OnActorEndOverlap.' },
      { id: 'stop-after-request', name: 'Stop after each request (no auto-resume)', enabled: true,
        body: 'AI completes only what you explicitly asked in the current message.' },
    ],
    custom: [],
  });

  const claudeCliStatus = JSON.stringify({
    installed: false,
    authenticated: false,
    error: 'Claude CLI not detected on this machine. Install from claude.com/cli to enable.',
  });
  const codexCliStatus = JSON.stringify({
    installed: false,
    authenticated: false,
    error: 'Codex CLI not detected. Install from github.com/openai/codex.',
  });

  const updateInfo = JSON.stringify({ has_update: false, current: FAKE_VERSION, latest: FAKE_VERSION });

  // -------- Hand-coded handlers --------
  // CEF binding lowercases UFUNCTION names. So GetPluginVersion → bridge.getpluginversion.

  const handlers = {
    // Identity / auth
    isauthenticated: async () => true,
    getauthemail: async () => FAKE_EMAIL,
    getauthstatus: async () => 'authenticated',
    getauthtokensjson: async () => JSON.stringify({ access_token: 'preview', expires_at: 9999999999 }),
    signout: () => { console.log('[preview] sign out (no-op)'); },
    openloginurl: () => { console.log('[preview] would open login URL in real browser'); },

    // Plugin metadata
    getpluginversion: async () => FAKE_VERSION,
    getplaninfojson: async () => JSON.stringify(planInfo),
    refreshplan: () => Promise.resolve(planRpcResp),

    // Sessions / chat
    getsessions: async () => JSON.stringify([
      { id: 'preview-1', title: 'Make a coin pickup', created_at: Date.now() - 3600000, message_count: 6 },
      { id: 'preview-2', title: 'Add damage system to BP_Enemy', created_at: Date.now() - 86400000, message_count: 12 },
      { id: 'preview-3', title: 'HUD widget with health bar', created_at: Date.now() - 172800000, message_count: 4 },
    ]),
    getsessionmessages: async () => JSON.stringify([]),
    createsession: async () => 'preview-' + Date.now(),
    deletesession: () => {},
    sendprompt: () => { console.log('[preview] sendprompt — no AI call in preview mode'); },
    sendpromptwithimages: () => { console.log('[preview] sendpromptwithimages'); },
    cancelprompt: () => {},

    // Settings
    getsettings: async () => '{}',
    getbackendmode: async () => 'api',
    setbackendmode: () => {},
    getmodel: async () => 'claude-sonnet-4-5',
    setmodel: () => {},
    getbaseurl: async () => 'https://api.anthropic.com/v1/messages',
    setbaseurl: () => {},
    setapikey: () => {},
    setapikeyforhost: async () => {},
    useapikeyforhost: async () => false,
    hasgroqapikey: async () => false,
    setgroqapikey: () => {},
    cleargroqapikey: () => {},
    getselectedtheme: async () => 'default',
    setselectedtheme: () => {},
    getpermissionmode: async () => 'auto',
    setpermissionmode: () => {},
    geteffort: async () => 'medium',
    seteffort: () => {},
    gettools: async () => '[]',

    // Rules
    getrulesjson: async () => rulesPayload,
    setbuiltinruleenabled: () => {},
    validatecustomrule: () => '',
    addcustomrule: () => '',
    updatecustomrule: () => {},
    deletecustomrule: () => {},
    setcustomruleenabled: () => {},

    // CLI status (always not-installed in preview)
    getclaudeclistatus: async () => claudeCliStatus,
    openclaudelogin: () => { console.log('[preview] would open Claude login'); },
    getcodexclistatus: async () => codexCliStatus,
    opencodexlogin: () => { console.log('[preview] would open Codex login'); },

    // Update banner
    getupdateinfojson: async () => updateInfo,

    // Telemetry / privacy
    getsharepromthistory: async () => false,
    setsharepromthistory: () => {},
    getprompthistoryconsentseen: async () => true,
    setprompthistoryconsentseen: () => {},
    getprompthistorysummaryjson: async () => JSON.stringify({ session_count: 0, prompt_count: 0 }),
    backfillprompthistory: () => {},
    deletesharedprompts: () => {},

    // Polish-prompt gate (v0.13.30) — preview always allows
    recordpolishusage: function (cbId) {
      // Mirror the real bridge: push a 'polish_usage_result' event back via window
      // so polishCurrentPrompt's checkPolishUsage() resolves.
      const payload = JSON.stringify({
        allowed: true,
        monthly_count: 8,
        cap: 50,
        plan: 'free',
      });
      // The real bridge calls window.onevent(type, text). Preview just dispatches
      // it the same way.
      setTimeout(() => {
        if (typeof window.onevent === 'function') {
          window.onevent('polish_usage_result', cbId + '|' + payload);
        }
      }, 100);
    },

    // Improve / polish
    improvefeedbacktext: function (kind, text, cbId) {
      // Fake a successful polish after 800ms so the UI shows the loading -> done flow.
      setTimeout(() => {
        if (typeof window.onevent === 'function') {
          const improved = '[Preview polish demo] ' + text + ' (in real plugin, the AI rewrites this with project context)';
          window.onevent('improve_result', cbId + '|' + kind + '|' + improved);
        }
      }, 800);
    },

    // Image picking — just no-op
    pickimagefile: async () => '',
    pasteimagefromclipboard: async () => '',

    // Clipboard
    copytoclipboard: (text) => {
      try { navigator.clipboard?.writeText(text); } catch (e) {}
    },
    pastefromclipboard: async () => '',

    // Developer mode
    isdevelopermode: async () => false,
    setdevelopermode: () => {},
    isdevelopertoggleavailable: async () => false,

    // Misc
    openpluginsettings: () => { console.log('[preview] would open Project Settings'); },
    openinconBrowser: () => {},
    openincontentbrowser: () => {},
    downloadasset: async () => '',
    transcribeaudio: () => {},
    readpluginresourcebase64: async () => '',
    savegeneratedwav: async () => '',
  };

  // -------- Proxy fallback --------

  window.bridge = new Proxy(handlers, {
    get(target, prop) {
      const name = String(prop).toLowerCase();
      if (name in target) return target[name];

      // Unknown method — auto-stub by verb prefix.
      return function autoStub(...args) {
        // console.debug('[preview-bridge] auto-stub:', prop, args);
        if (name.startsWith('is') || name.startsWith('has')) {
          return Promise.resolve(false);
        }
        if (name.startsWith('get')) {
          // Most getters return strings. Make it an async-friendly empty string.
          return Promise.resolve('');
        }
        // Setters / actions return undefined sync.
        return undefined;
      };
    },
    has() { return true; },
  });

  // Helper for the preview banner — visitors can re-invoke this to confirm
  // the mock is active.
  window.__locoPreviewMockActive = true;

  console.log('[Wingman Preview] bridge mock active — version', FAKE_VERSION);
})();
