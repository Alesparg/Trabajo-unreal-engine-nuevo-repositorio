@echo off
setlocal EnableExtensions
REM ============================================================================
REM  Wingman - Repair / Clear Cache   (INTERACTIVE)
REM ----------------------------------------------------------------------------
REM  Nothing is deleted until you pick a level (1-3) AND type Y to confirm.
REM
REM  WHY: fixes the "stuck / Repair connection" bug - Wingman answers a plain
REM  "Hello" but any request that needs a TOOL comes back blank. A common cause
REM  is a stale MCP config file left on disk after Codex/Claude changed its
REM  config schema in an update.
REM
REM  FASTEST UNBLOCK without deleting anything: sign in to Wingman in the editor
REM  (the stuck gate only triggers when you are signed out).
REM
REM  NEVER DELETED at any level: your API / integration keys (OpenAI/Groq/Meshy/
REM  ElevenLabs/etc.), your Codex/Claude CLI logins, or your Wingman settings.
REM  Level 3 optionally also signs you OUT of Wingman itself (your ai.locodev.dev
REM  session) - listed explicitly, never silent.
REM ============================================================================

REM --- Locate your Unreal project (needed for the Saved\ and Intermediate\ steps).
REM     Order: (a) a .uproject dragged onto this file, (b) this plugin sitting in
REM     <YourProject>\Plugins\Wingman\, (c) the folder you ran this from.
set "PROJDIR="
if /I "%~x1"==".uproject" set "PROJDIR=%~dp1"
if not defined PROJDIR if exist "%~dp0..\..\*.uproject" for %%F in ("%~dp0..\..\*.uproject") do set "PROJDIR=%%~dpF"
if not defined PROJDIR if exist "%CD%\*.uproject" set "PROJDIR=%CD%\"

REM --- Read the plugin version from the .uplugin next to this .bat (best effort).
set "PLUGVER=unknown"
if exist "%~dp0Wingman.uplugin" for /f "tokens=2 delims=:, " %%a in ('findstr /C:"VersionName" "%~dp0Wingman.uplugin"') do set "PLUGVER=%%~a"

:menu
echo(
echo   ==========================================
echo     Wingman - Repair / Clear Cache   v%PLUGVER%
echo   ==========================================
echo   Close Unreal Editor first, or files in use are skipped.
echo   Nothing is deleted until you choose a level and confirm.
if defined PROJDIR echo   Project: %PROJDIR%
if not defined PROJDIR echo   Project: NOT found - only Level 1 temp cleanup is available.
echo   ------------------------------------------------------------
echo   [1] MINIMAL   fixes the stuck-turn bug - no data loss
echo         - %TEMP%\loco-mcp
echo         - %LOCALAPPDATA%\Temp\loco-mcp
echo         - ^<Project^>\Saved\LocoAI\external-mcp-config.json   MCP token, re-minted
echo(
echo   [2] STANDARD  level 1 + stale editor caches - no user data lost
echo         - everything in level 1
echo         - ^<Project^>\Intermediate\CachedAssetRegistry*.bin    Content Browser cache
echo         - ^<Project^>\Saved\Temp\LocoAI\Downloads              temp download scratch
echo(
echo   [3] DEEP      level 2 + CHAT HISTORY + WINGMAN SIGN-OUT
echo         - everything in level 2
echo         - ^<Project^>\Saved\LocoHelperAI\sessions.json         chat history
echo         - ^<Project^>\Saved\LocoHelperAI_AuthAccess.bin        signs you out of Wingman
echo         - ^<Project^>\Saved\LocoHelperAI_AuthRefresh.bin       signs you out of Wingman
echo   ------------------------------------------------------------
echo   [D] Diagnostics   show a quick health check, delete nothing
echo   [B] Debug report  save Codex/Claude + MCP details to a file for support
echo   [T] Tips          how to fix the stuck-turn bug
echo   [Q] Quit
echo   ------------------------------------------------------------
set "LVL="
set /P "LVL=  Enter 1, 2, 3, D, B, T, or Q: "

if /I "%LVL%"=="Q" goto :quit
if /I "%LVL%"=="D" goto :doDiag
if /I "%LVL%"=="B" goto :doDebug
if /I "%LVL%"=="T" goto :doTips
if "%LVL%"=="1" goto :confirm
if "%LVL%"=="2" goto :confirm
if "%LVL%"=="3" goto :confirm
echo(
echo   Please type 1, 2, 3, D, B, T, or Q.
goto :menu

:doDiag
call :Diagnostics
echo(
pause
goto :menu

:doDebug
call :DebugReport
echo(
pause
goto :menu

:doTips
call :Tips
echo(
pause
goto :menu

:confirm
echo(
echo   LEVEL %LVL% will delete exactly these:
echo(
call :ListLevel %LVL%
echo(
set "OK=N"
set /P "OK=  Proceed with LEVEL %LVL%? [y/N]: "
if /I not "%OK%"=="Y" goto :cancel
echo(
call :Bar
echo(

REM ---- Level 1 (temp MCP configs are project-independent) --------------------
call :KillDir  "%TEMP%\loco-mcp"
call :KillDir  "%LOCALAPPDATA%\Temp\loco-mcp"
if defined PROJDIR call :KillFile "%PROJDIR%Saved\LocoAI\external-mcp-config.json"

REM ---- Level 2 --------------------------------------------------------------
if %LVL% GEQ 2 if defined PROJDIR call :KillFile "%PROJDIR%Intermediate\CachedAssetRegistry*.bin"
if %LVL% GEQ 2 if defined PROJDIR call :KillDir  "%PROJDIR%Saved\Temp\LocoAI\Downloads"

REM ---- Level 3 (sessions.json lives in a DIFFERENT subfolder than the MCP
REM      token above - Saved\LocoHelperAI\, not Saved\LocoAI\. The auth files
REM      are loose directly under Saved\, not in any subfolder.) -------------
if %LVL% GEQ 3 if defined PROJDIR call :KillFile "%PROJDIR%Saved\LocoHelperAI\sessions.json"
if %LVL% GEQ 3 if defined PROJDIR call :KillFile "%PROJDIR%Saved\LocoHelperAI_AuthAccess.bin"
if %LVL% GEQ 3 if defined PROJDIR call :KillFile "%PROJDIR%Saved\LocoHelperAI_AuthRefresh.bin"

echo(
echo   Done, level %LVL%. Start Unreal, open Wingman, and try a tool request again.
if %LVL% LSS 3 echo   Your API keys, CLI logins, and settings were left untouched.
if %LVL% GEQ 3 echo   Your API keys and Codex/Claude CLI logins were left untouched.
if %LVL% GEQ 3 echo   You WILL be signed out of Wingman - sign back in when Unreal opens.
echo   Still stuck? Try the [T] Tips option, or https://ai.locodev.dev/contact
echo(
pause
goto :menu

REM ===========================================================================
REM  Subroutines
REM ===========================================================================

:ListLevel
REM  %1 = level number. Prints the exact paths that level will remove.
echo     [L1] %TEMP%\loco-mcp
echo     [L1] %LOCALAPPDATA%\Temp\loco-mcp
if defined PROJDIR echo     [L1] %PROJDIR%Saved\LocoAI\external-mcp-config.json
if %1 GEQ 2 if defined PROJDIR echo     [L2] %PROJDIR%Intermediate\CachedAssetRegistry*.bin
if %1 GEQ 2 if defined PROJDIR echo     [L2] %PROJDIR%Saved\Temp\LocoAI\Downloads
if %1 GEQ 3 if defined PROJDIR echo     [L3] %PROJDIR%Saved\LocoHelperAI\sessions.json
if %1 GEQ 3 if defined PROJDIR echo     [L3] %PROJDIR%Saved\LocoHelperAI_AuthAccess.bin   - signs you OUT of Wingman
if %1 GEQ 3 if defined PROJDIR echo     [L3] %PROJDIR%Saved\LocoHelperAI_AuthRefresh.bin  - signs you OUT of Wingman
if not defined PROJDIR echo     [note] No project found - only the two temp paths above will be cleared.
goto :eof

:KillDir
if exist "%~1" ( rmdir /S /Q "%~1" & echo   removed  %~1 ) else ( echo   skip     %~1 [not present] )
goto :eof

:KillFile
if exist "%~1" ( del /Q "%~1" & echo   removed  %~1 ) else ( echo   skip     %~1 [not present] )
goto :eof

:Bar
REM  A short "working" progress bar so the tool feels responsive.
<nul set /p "=  Working ["
for /L %%i in (1,1,20) do ( <nul set /p "=#" & call :Nap )
echo ] done
goto :eof

:Nap
REM  ~60 ms pause (ping an unreachable test address; works offline).
ping -n 1 -w 60 192.0.2.1 >nul 2>&1
goto :eof

:Diagnostics
echo(
echo   ------------------------- Diagnostics -------------------------
echo   Nothing below is changed - this is read only.
echo   Plugin version:  %PLUGVER%
if defined PROJDIR echo   Project:         %PROJDIR%
if not defined PROJDIR echo   Project:         NOT found - drag your .uproject onto this .bat
if exist "%TEMP%\loco-mcp" echo   Temp MCP config: PRESENT  - Level 1 will clear it
if not exist "%TEMP%\loco-mcp" echo   Temp MCP config: none
if defined PROJDIR if exist "%PROJDIR%Saved\LocoAI\external-mcp-config.json" echo   MCP token file:  PRESENT  - Level 1 will clear it
if defined PROJDIR if not exist "%PROJDIR%Saved\LocoAI\external-mcp-config.json" echo   MCP token file:  none
if defined PROJDIR if exist "%PROJDIR%Saved\LocoHelperAI_AuthAccess.bin" echo   Wingman sign-in: found  - you ARE signed in to Wingman (Level 3 signs out)
if defined PROJDIR if not exist "%PROJDIR%Saved\LocoHelperAI_AuthAccess.bin" echo   Wingman sign-in: none
if exist "%USERPROFILE%\.codex\auth.json" echo   Codex login:     found  - you ARE logged in to Codex
if not exist "%USERPROFILE%\.codex\auth.json" echo   Codex login:     NOT found  - Codex is not logged in
if exist "%USERPROFILE%\.claude" echo   Claude folder:   found
if not exist "%USERPROFILE%\.claude" echo   Claude folder:   NOT found
where codex >nul 2>&1
set "EC=%errorlevel%"
if "%EC%"=="0" echo   codex CLI:       on PATH
if not "%EC%"=="0" echo   codex CLI:       not on PATH
where claude >nul 2>&1
set "EC=%errorlevel%"
if "%EC%"=="0" echo   claude CLI:      on PATH
if not "%EC%"=="0" echo   claude CLI:      not on PATH
echo   ---------------------------------------------------------------
echo   Reading this: if tool requests come back blank but you ARE
echo   logged in, run Level 1 to clear a stale MCP config.
goto :eof

:DebugReport
REM  Writes a shareable report with the Codex/Claude + MCP details support needs.
REM  Contains NO API keys, NO login tokens, and NO chat content.
setlocal
set "RPT=%USERPROFILE%\Desktop\Wingman-Debug-Report.txt"
if not exist "%USERPROFILE%\Desktop\" set "RPT=%USERPROFILE%\Wingman-Debug-Report.txt"
echo(
echo   Building debug report - collecting Codex/Claude + MCP info ...
call :Bar
REM  Scan the temp MCP config for the header schema - the stuck-turn smoking gun.
set "FOUNDOLD="
set "FOUNDNEW="
set "TMPCFG=0"
if exist "%TEMP%\loco-mcp" for %%f in ("%TEMP%\loco-mcp\*") do call :ScanCfg "%%f"
> "%RPT%" echo Wingman Debug Report
>>"%RPT%" echo Generated : %DATE% %TIME%
>>"%RPT%" echo Plugin    : v%PLUGVER%
>>"%RPT%" ver
>>"%RPT%" echo Project   : %PROJDIR%
>>"%RPT%" echo ----------------------------------------
>>"%RPT%" echo == Codex CLI ==
where codex >nul 2>&1
set "CODEXEC=%errorlevel%"
if "%CODEXEC%"=="0" echo codex: on PATH >>"%RPT%"
if "%CODEXEC%"=="0" codex --version >>"%RPT%" 2>&1
if not "%CODEXEC%"=="0" echo codex: NOT on PATH >>"%RPT%"
if exist "%USERPROFILE%\.codex\auth.json" echo codex login: present - auth.json, contents NOT included >>"%RPT%"
if not exist "%USERPROFILE%\.codex\auth.json" echo codex login: NOT found >>"%RPT%"
if exist "%USERPROFILE%\.codex\config.toml" echo codex config.toml: present >>"%RPT%"
>>"%RPT%" echo ----------------------------------------
>>"%RPT%" echo == Claude CLI ==
where claude >nul 2>&1
set "CLAUDEEC=%errorlevel%"
if "%CLAUDEEC%"=="0" echo claude: on PATH >>"%RPT%"
if "%CLAUDEEC%"=="0" claude --version >>"%RPT%" 2>&1
if not "%CLAUDEEC%"=="0" echo claude: NOT on PATH >>"%RPT%"
if exist "%USERPROFILE%\.claude" echo claude dir: present >>"%RPT%"
>>"%RPT%" echo ----------------------------------------
>>"%RPT%" echo == Wingman MCP config schema, the stuck-turn check ==
if "%TMPCFG%"=="0" echo No temp MCP config present. Open Wingman + send ONE request, then re-run Debug report. >>"%RPT%"
if defined FOUNDNEW echo MCP header schema: current http_headers - OK >>"%RPT%"
if defined FOUNDOLD echo MCP header schema: OLD headers-subtable - STALE. On recent Codex this causes the stuck-turn bug. Update to v0.17.2 or run Level 1. >>"%RPT%"
>>"%RPT%" echo ----------------------------------------
>>"%RPT%" echo == MCP discovery / external exposure ==
if defined PROJDIR if exist "%PROJDIR%Saved\LocoAI\external-mcp-config.json" echo Discovery file present - external MCP exposure ON, token NOT included >>"%RPT%"
if defined PROJDIR if not exist "%PROJDIR%Saved\LocoAI\external-mcp-config.json" echo Discovery file absent - external exposure OFF, this is normal >>"%RPT%"
if not defined PROJDIR echo Project not found - discovery + log scan skipped >>"%RPT%"
>>"%RPT%" echo ----------------------------------------
>>"%RPT%" echo == Recent Wingman/MCP log lines, sanitized, no tokens ==
REM  "CodexCli" alone catches CodexCliSpawnStarted, CodexCliExit (the real exit
REM  code + error category), and CodexCliSpawnFailed - the actual evidence of
REM  WHERE a tool-turn died, not just that the gate blocked it.
if defined PROJDIR if exist "%PROJDIR%Saved\Logs\*.log" findstr /I /C:"McpRequestBlocked" /C:"ExternalMcpAuthFailed" /C:"not_signed_in" /C:"Sign in to Wingman" /C:"ExternalMcpRateLimited" /C:"CodexCli" /C:"http_headers" /C:"loco_helper_ai" "%PROJDIR%Saved\Logs\*.log" >>"%RPT%" 2>&1
>>"%RPT%" echo ----------------------------------------
>>"%RPT%" echo This report contains no API keys, no login tokens, and no chat content.
echo(
echo   Report saved to:
echo     %RPT%
echo(
echo   Key findings:
if defined FOUNDOLD echo     - MCP schema is STALE, old headers-subtable. Run Level 1 or update to v0.17.2.
if defined FOUNDNEW echo     - MCP schema is current, http_headers.
if "%TMPCFG%"=="0" echo     - No temp MCP config yet. Send one Wingman request, then re-run Debug report.
echo     - Send that .txt to https://ai.locodev.dev/contact for help.
endlocal
goto :eof

:ScanCfg
set "TMPCFG=1"
findstr /I /C:"http_headers" "%~1" >nul 2>&1 && set "FOUNDNEW=1"
findstr /I /C:".headers]" "%~1" >nul 2>&1 && set "FOUNDOLD=1"
goto :eof

:Tips
echo(
echo   ----------------------------- Tips ----------------------------
echo   * FASTEST unblock, no delete: in Unreal, sign in to Wingman.
echo     The stuck gate only triggers when signed out - signing in
echo     lets tool requests through right away.
echo   * After a Codex or Claude UPDATE, if tool requests go blank,
echo     run Level 1 - an update can leave a stale MCP config behind.
echo   * Order to try: Level 1 first. Still stuck? Level 2. Use
echo     Level 3 last - it deletes your chats AND signs you out of Wingman.
echo   * "Uninstalling" via Wingman Manager only removes the plugin BINARY.
echo     Your chats and sign-in live in the PROJECT'S Saved folder, not the
echo     engine plugin folder, so they survive an uninstall/reinstall. Use
echo     Level 3 in THIS tool if you want those cleared too.
echo   * Always CLOSE Unreal before clearing, or open files are skipped.
echo   * Your API keys, CLI logins, and settings are NEVER deleted here.
echo   * Use [D] Diagnostics to see what is on disk before deleting.
echo   * Still stuck? Support: https://ai.locodev.dev/contact
echo   ---------------------------------------------------------------
goto :eof

:cancel
echo(
echo   Cancelled. Nothing was deleted.
goto :menu

:quit
echo(
echo   Quit. No changes made.
echo(
pause
endlocal
