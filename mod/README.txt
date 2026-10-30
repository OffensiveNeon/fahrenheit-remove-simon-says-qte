Fahrenheit: Indigo Prophecy Remastered - Remove Simon Says QTE (Auto-Pass)
by NeonGamingMods                                    version 0.1.1 (beta)

WHAT IT DOES
  Quick Time Events pass on their own, and you never see them.
  - Simon Says QTEs (the colored direction prompts) pass automatically.
    This covers both kinds: the ones that affect mental health
    (e.g. Reconstruction) and the ones where failing costs health and
    can end in a game over (e.g. The Storm).
  - QTE graphics, sounds and captions ("GET READY!", "GREAT!", "LUCKY!",
    "FAILED!") are hidden.
  - Normal action prompts and dialog choices still work as usual.

INSTALL
  1. Close the game.
  2. In Steam: right-click the game > Manage > Browse local files.
  3. Copy the files from this zip into that folder and double-click
     Install.bat.
  Your original exe is backed up the first time you install.

UNINSTALL
  Double-click Uninstall.bat, or use Steam's "Verify integrity of game files".

AFTER A STEAM UPDATE OR VERIFY INTEGRITY
  Run Install.bat again. If an update changes the game, the patcher
  won't touch it.

KNOWN LIMITS (beta)
  - Tested in Reconstruction, Lost Love and The Storm.
  - Meter mini-games (alternating two keys) still have to be played.
  - Mood bars and lives counter still show.
  - Captions are only hidden in English.

REQUIREMENTS
  Steam version of the game. Nothing else to install.

ADVANCED
  Check which patches are applied (PowerShell, in the game folder):
    powershell -ExecutionPolicy Bypass -File patch.ps1 -Action Status

CREDITS
  NeonGamingMods. Made with help from Claude Opus 5.5 (Anthropic).
