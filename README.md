# KIM1025 1.7.17

KIM1025 now keeps four features:

- Animated Pokédex sprites.
- Location-aware HD battle backgrounds, including portrait, widescreen and ultrawide artwork.
- Player trainer sprite choices and animated trainer intros in Red/Blue/Yellow.
- The 165 Gen 1 Kanto Rework / Essentials move animations.

Red/Blue/Yellow has four settings and KIM ASSETS on one page. Gold/Silver/Crystal retains its animated Pokédex support. FireRed/LeafGreen/Ruby/Sapphire/Emerald retains animated Pokédex previews and supported HD backgrounds. Trainer selection and the replacement move-animation pack remain Gen 1 features, as in previous releases.

Modern UI, title-screen changes, party/summary/evolution/starter portraits, menu icons, KIM battle Pokémon replacements, custom shadows, shiny encounter effects/odds, and Pokéball recoloring have been removed. Native gameplay and other mods own those features. Old saved flags cannot turn the removed features back on. 1025Dex owns battle Pokémon; KIM only replays its current pictures where HD background alignment requires it. Its native picture layer still runs every frame.

The existing iOS/Android portrait and landscape framing, Retina framebuffer sizing, graphics-stack safeguards, world orientation, screen-position handling, trainer ground anchors and move/catch alignment remain. Existing size/framing calibrations are retained internally without the old settings pages.

## Install

Close the game, replace the previous `mods/kim1025` folder with the `kim1025` folder in `kim1025-1.7.17.zip`, and restart. Replace the whole folder so removed files do not linger. Keep the downloaded asset cache. 1025Dex and WildFollowers can remain enabled.

Open KIM ASSETS to download missing original KIM assets and KIM1025 background artwork. The downloader keeps its visible selector arrow, DOWNLOAD ALL queue, upgrade prompt, separate DOWNLOAD KIM1025 option, verification, retry and cancellation. The artwork pack is still version 1.0.0; this update does not require downloading it again.

## Validation

All 19 regression suites pass and 55 Lua files compile. The complete entry boots in Gen 1/2/3 fixtures for desktop and iOS, including upgrades with removed features enabled in saved settings. Tests cover native/provider ownership, animated frames, downloader/cache behavior, HD scene selection, platform anchors, retina scaling and orientation using Gen1Recomp 0.3.71 source. An additional 225 checks use the installed 1025Dex scene hook and its real animation timing.

The local LÖVE runtime also passes 26 GPU checks with the installed 1025Dex timing and 9 GPU trainer checks at 1320×2868 and 660×1434. These are isolated renderer tests; full ROM gameplay and a physical iPhone run have not been verified.

Battle UI Customizer 1.0.7: the HD Gen 1 move menu uses its selected Emerald frame and panel opacity in portrait, landscape and desktop layouts.

Battle UI Customizer 1.0.7: Vanilla uses native Gen 1 move frames; Emerald keeps its thick red borders. Panel opacity works in all orientations.

Desktop HD battles now use the player provider pixels at the scene scale, ignoring obsolete KIM player-size settings. The desktop trainer is smaller and remains anchored to the dialogue top. Mobile size calibrations are retained.

1.7.17 validation: 21 Lua suites passed, including 120 desktop scaling checks and 225 checks with GitHub 1025Dex 1.2.34. All 47 Lua files compile. Windows LOVE passed 25 GPU checks using real sprite frames at five resolutions, including 5120x1440. Live ROM gameplay capture was unavailable because the Windows capture helper timed out.
