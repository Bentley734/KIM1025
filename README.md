# KIM1025 1.7.20

KIM1025 now keeps four features:

- Animated Pokédex sprites.
- Location-aware HD battle backgrounds, including portrait, widescreen and ultrawide artwork.
- Player trainer sprite choices and animated trainer intros in Red/Blue/Yellow.
- The 165 Gen 1 Kanto Rework / Essentials move animations.

Red/Blue/Yellow has four settings and KIM ASSETS on one page. Gold/Silver/Crystal retains its animated Pokédex support. FireRed/LeafGreen/Ruby/Sapphire/Emerald retains animated Pokédex previews and supported HD backgrounds. Trainer selection and the replacement move-animation pack remain Gen 1 features, as in previous releases.

Modern UI, title-screen changes, party/summary/evolution/starter portraits, menu icons, KIM battle Pokémon replacements, custom shadows, shiny encounter effects/odds, and Pokéball recoloring have been removed. Native gameplay and other mods own those features. Old saved flags cannot turn the removed features back on. 1025Dex owns battle Pokémon; KIM only replays its current pictures where HD background alignment requires it. Its native picture layer still runs every frame.

The existing iOS/Android portrait and landscape framing, Retina framebuffer sizing, graphics-stack safeguards, world orientation, screen-position handling, trainer ground anchors and move/catch alignment remain. Existing size/framing calibrations are retained internally without the old settings pages.

## Install

Close the game, replace the previous `mods/kim1025` folder with the `kim1025` folder in `kim1025-1.7.20.zip`, and restart. Replace the whole folder so removed files do not linger. Keep the downloaded asset cache. 1025Dex and WildFollowers can remain enabled.

Open KIM ASSETS to download missing original KIM assets and KIM1025 background artwork. The downloader keeps its visible selector arrow, DOWNLOAD ALL queue, upgrade prompt, separate DOWNLOAD KIM1025 option, verification, retry and cancellation. The artwork pack is still version 1.0.0; this update does not require downloading it again.

## Desktop Native Fit correction

1.7.20 fixes the remaining player Pokemon oversizing and mound drift in desktop Native Fit. The scene requests a trimmed, bottom-anchored 1025Dex image and draws it at the painted mound's exact transform, instead of replaying the native UI layer at its larger zoom. The fixed trainer presentation is retained. Mobile calibrations are retained.

## Validation

All 21 regression suites pass and all 47 Lua files compile. The current 1025Dex 1.2.34 hook passes 231 checks, including the desktop Native Fit and natural-frame contract. The production Native Fit player branch renders with real Nidoking artwork and the cached grass arena in Windows LOVE at 1040x700, 1920x1080 and 5120x1440; 6 size and mound-anchor GPU checks pass. These are renderer tests; full ROM gameplay capture remains unverified.

## Desktop sprite size controls

Open KIM1025 options to change TRAINER SIZE, PLAYER POKEMON SIZE or ENEMY POKEMON SIZE. Each ranges from 50% to 200% in 10% steps and defaults to 100%. Trainer 100% equals the former 200%; player 100% equals the former 130%. New trainer/player keys prevent old percentages being interpreted against the new baselines. Enemy percentages now affect the Native Fit mound-anchored renderer using trimmed natural provider frames. Settings persist and take effect on battle redraw. Mobile calibration is unchanged.

1.7.20 validation: all 21 regression suites and 47 Lua compilation checks pass, including 492 scale/anchor/mobile assertions, 139 compositor checks and 235 live provider checks against current 1025Dex 1.2.34. Windows LOVE passes 42 Native Fit geometry and scaling GPU checks at 1040x700, 1920x1080 and 5120x1440. Full ROM gameplay was not captured.
