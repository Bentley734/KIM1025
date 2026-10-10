# KIM1025 development preview

## 1.7.6-dev.2 — Live 1025Dex battle sprites and settings submenus

KIM's fullscreen Gen 1 battle scene now calls the active battle.mon_pic provider for each player and enemy frame. This allows 1025Dex to supply its own artwork and animation clock even while KIM suppresses the duplicate native sprite layer. The provider's pending signal hides the sprite until its custom sheet is ready, instead of flashing vanilla art. Available KIM metadata no longer displaces a claimed 1025Dex sprite. Native picImage resolution also retains the external provider's live image. Existing 1025Dex animation options and intentional pauses are preserved.

Settings now use Pokemon, Battle, Interface, Title Screen and Advanced submenus, including smaller Battle and Interface pages. Existing saved values are preserved; KIM Assets remains on the main page.

Install kim1025-1.7.6-dev.2.zip (about 9 MB), replace mods/kim1025, keep 1025Dex and WildFollowers enabled, preserve downloaded asset caches, and fully restart Gen1Recomp. No artwork redownload is required for this code change.

Validation: all 20 automated suites pass and 92 Lua files compile. The installed 1025Dex 1.2.34 live scene hook and actual animation clock pass 233 provider/suppression checks, including front/back animation resuming after EE pauses. The regression fails against v1.7.5. The installed Mac LOVE graphics runtime passes 26 GPU checks with the actual Dex hook/clock. This is a development test build; full ROM gameplay and physical iOS testing remain unverified.

