# KIM1025 1.7.31

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

## Asset menu location

Open KIM1025, then KIM ASSETS. The game options page no longer has a separate KIM ASSETS entry. Existing downloads, cached artwork, and the missing-assets boot prompt are retained.

## Matching battle panel size

The Gen 1 move-selection panel now fills exactly the same lower area as the battle command menu and dialogue box. Its frame expands to the shared bounds while move names, PP and type labels keep proportional glyphs. Long move names fit their cells. Sprite positions, background artwork, menu navigation and asset cache behavior are retained. Restart the game after updating.

## Polished move-selection panel

Four individually spaced move cards replace the heavy double frame. A persistent mint selection highlight and dark accent stripe make the current move clear even at low background opacity. A compact type-colored PP meter and detail rail improve readability while retaining the shared battle/dialogue bounds. Restart after updating.

## Gen 3 move-menu styling

Restores the matching imported Emerald border (or native border for the native style), with a classic two-column move grid and separate PP/type frame. Move names are 20 percent larger with heavier pixel strokes. Names that exceed their cell width wrap onto two lines, preferably at a word boundary. Panel bounds and customizer opacity remain unchanged. Restart after updating.

## Emerald move-menu alignment

Uses Emerald layout proportions: two thirds for the move grid and one third for PP/type. Move columns are closer together with consistent row baselines, including wrapped names. PP aligns with the upper move row, and the type block aligns with the lower row. Matching borders, bold text, wrapping and full panel bounds are retained.

## Battle styling moved to Menu Customizer

The recent move-menu visual changes now belong to Menu Customizer 3.2.0, which includes Battle UI Customizer. KIM delegates its fullscreen move screen to that renderer when enabled. Without it, KIM returns to its pre-redesign 1.7.21 move-menu fallback. Sprite, background and asset behavior is unchanged. Update both mods and restart.

## Auto player battle size

Select **KIM1025 > PLAYER POKEMON SIZE > AUTO** for desktop HD and Native Fit battles in Red/Blue/Yellow. Auto uses all available space above the player mound and below the enemy name/HP band, stopping only at screen edges or the player status panel. There are no window-percentage size caps. It sizes the complete visible animation union, rather than transparent picture-box padding. It measures transparent atlas padding independently of the feet and retains the mound anchor, idle animation and send-out growth. The lower dialog/command UI renders after the sprite, so its feet can remain on the mound behind that panel. Manual sizes, trainers, opponents and mobile positioning are unchanged.

Use 1025Dex 1.2.41 for stable animation-union bounds and intentional hover padding. Existing downloads are reused. Auto is opt-in; restart after updating both mods.

## 1.7.28 — Auto fills the available space

The previous Auto was capped at 36% of window width and 38% of height. Those limits are removed. The fit now fills the actual gap from the mound to the enemy name/HP band with only a two-pixel rounding margin, unless sprite width reaches a screen edge or player status panel first. Padded ROM/static fallback pictures are measured by their opaque pixels and centred by visible bounds; empty margins never reduce their size. Mound anchors, manual sizes, trainer/enemy controls, mobile placement and animation transforms are retained.

Restart after updating. Keep PLAYER POKEMON SIZE on AUTO. 1025Dex 1.2.41 remains compatible and needs no update.

## 1.7.29 — Emerald battle text

Keep Emerald battle fonts crisp with Menu Customizer 3.2.15.

- Draw commands and dialogue at their final display size instead of shrinking them into the 160px Game Boy canvas first.
- Remove the old source text copy when Menu Customizer owns the final text pass.
- Preserve all original Emerald HUD glyph pixels with a doubled capture surface while keeping the existing HUD and party-ball positions.
- Retain the native text path when the new presenter is unavailable and retain existing sprite, mound and mobile positioning.

Update Menu Customizer to 3.2.15 alongside this release. Restart after updating. Downloaded artwork remains usable.

Validation: production routing/capture regression checks, actual Windows LOVE pixel comparisons at desktop, ultrawide and portrait sizes, composed border/font comparisons, all KIM suites and eleven-game startup checks with Menu Customizer. Live game window capture timed out; gameplay was not verified.

## 1.7.30 — trainer size cap and dialogue anchor

Fix oversized trainers in maximized ultrawide windows and the gap above battle dialogue.

- Fit the desktop trainer against both window width and height instead of width alone. The default Red trainer at 5120x1440 has about 512px of visible height instead of 1024px.
- Keep the size setting, with a visible-height safety cap so the trainer stays on-screen.
- Align the visible trainer bottom with the final dialogue frame, including transparent sprite padding and the border's clear top row.
- Preserve horizontal mound positioning, send-out slide timing, mobile calibration and native/external UI fallbacks.

Restart after updating. Menu Customizer 3.2.15 remains compatible; no asset download is needed.

Validation: production trainer placement and cap checks in Lua 5.3/LuaJIT; real Windows LOVE renders using Ash and Red static artwork and all five atlas frames, visible-pixel measurements and the selected dialogue border at normal, 1080p and 5120x1440 sizes; all KIM regression suites and eleven-game startup checks with Menu Customizer. Live ROM gameplay was not exercised.

## 1.7.31 — enlarged HUD names

Keep larger Pokemon names crisp and unclipped with Menu Customizer 3.2.16.

Add four logical rows above the high-resolution battle HUD capture for enlarged name glyphs. Compensate the HUD crops and gauge shader coordinates so levels, HP bars and party balls keep their existing positions. Retain final-resolution battle text, the trainer cap and gap fix.

Update Menu Customizer to 3.2.16 and restart. Downloaded artwork remains usable.

Validation: original level-font pixel comparison, actual Windows LOVE high-resolution HUD and final text checks, trainer artwork checks, all KIM regression suites and eleven-game startup checks. Live ROM gameplay was not exercised.
