# KIM1025 1.7.42 — Unmodified native attack rendering

Remove the remaining animation-player wrapper and native OAM scratch-canvas replay. Remove the catch retargeting module. During a move, native picture effects, palette fades, shakes, flashes and resting catch animations, KIM yields battle drawing, picture/HUD wrappers, background filtering and final-canvas composition to the engine. Idle HD presentation resumes only after those effects finish. Attack frames use the native battlefield rather than the HD reconstruction. This applies to both attacker directions and old saved options cannot enable the removed players.

Built from GitHub's latest 1.7.41. 1025Dex 1.2.54 remains unchanged; its species artwork is retained. Johnto remains untouched.

Validation: 224 real GPU frames of Tackle, Growl and Tail Whip, both player and enemy, match native output pixel-for-pixel using the running game's actual AnimPlayer, picture effects and cartridge animation/graphics data. No KIM scratch/background-effect calls run on those frames. Native player/effect methods remain identical at startup. Existing source compilation, 165-move argument forwarding, sprite alignment, Pokédex and Gen 3 regressions pass under LuaJIT/Lua 5.3. KIM and Menu Customizer start together across eleven games under LuaJIT. Party-ball GPU captures remain native. Live gameplay was not restarted automatically.

Install with Menu Customizer 3.2.122. Fully exit and reopen the game to unload previous wrappers; returning to the title screen does not unload Lua patches.

# KIM1025 1.7.41 — Restore both party Poké Ball rows

Restore native player and enemy party Poké Balls in the Gen 1 battle HUD. The HUD capture still erased their cells expecting a removed Poké Ball Colorfix layer to redraw them, leaving only the row brackets. Remove the obsolete cell erasure, separate canvas and empty-layer composition; preserve the native party tiles alongside the HUD.

Built from GitHub's latest 1.7.40 source and release. Preserve the native move-animation cleanup, catch positioning, HUD placement, trainer choices, backgrounds and Menu Customizer integration. Johnto remains untouched.

Validation: reproduce erased ball pixels on 1.7.40 with the real GPU and cartridge ball atlas; the fixed HUD matches every pixel of native rendering across ten desktop/mobile cases. Cover both parties, healthy/status/fainted/empty slots, trainer/link/wild battles, slide-in frames, adjacent HP cells and graphics/battle-state restoration. Existing native move forwarding, whole-source compilation, sprite alignment, Pokédex and Gen 3 tests pass under LuaJIT and Lua 5.3.

Restart the game after updating to reload the HUD capture.

# KIM1025 1.7.40 — Native move animations and effects

Remove the bundled KRBA/Essentials animation installer, desktop/mobile replacement players, all 165 animation definitions, move PNGs and move SFX. Remove the MOVE ANIMATIONS setting, custom battler transforms, wide/3D effect planes and animation-layer clipping. Old saved preferences cannot reinstall the provider.

Preserve native Poké Ball catch targeting, Pokémon sprite providers, trainer choices, HD backgrounds and Pokédex presentation. Move execution, timing and effect drawing stay with the engine and any independently installed animation provider.

Built from GitHub's latest KIM1025 1.7.39 source and release. Validated under LuaJIT and Lua 5.3 with native move forwarding on both sides, Windows/macOS/Android/iOS startup across all three generations, source compilation and alignment/Pokédex/Gen 3 regressions. No live battle reproduction was performed.

Replace the installed KIM1025 folder and restart the game to unload the old patched player. Use native battle animations in the game's own settings. Johnto and Johnto in Motion were excluded at the user's request.

# kim1025 1.7.39

Fix species sprite lookup for accented and non-ASCII display names. Normalize complete UTF-8 characters before ASCII lookup; preserve Nidoran gender suffixes, handle Latin accents, combining marks and curly punctuation, and recognize older corrupted encodings.

1025Dex: repair the corrupted accent-folding table so Flabebe artwork is found for Flabébé/FLABÉBÉ instead of silently dropping e characters. Preserve unambiguous collapsed-key matching for species such as Farfetch'd, Mr. Mime, Mime Jr., Type: Null and Ho-Oh. KIM1025: use the same normalization in native sprite names and its exported Dex sheet provider.

Validation: production resolver checks for 14 accent/gender/punctuation variants plus all 1371 canonical species/form mappings under LuaJIT and Lua 5.3; whole-source compilation of both mods. Restart to load the update.

# KIM1025 1.7.38

Own Gen 1 Pokedex entry presentation in KIM1025, with Menu Customizer supplying optional shared styling.

- Migrate wrapped/paginated descriptions, inset text, Height/Weight labels, U.S. customary measurements and framed entry/stats/information pages into KIM.
- Refresh the selected species/form portrait consistently for the main entry and stats pages.
- Prepare the stats orientation in a separate scratch canvas, without intercepting graphics.draw or mutating the source image; restore the screen's original sprite after drawing.
- Preserve 1025Dex description/stats/form navigation and use native font/frames when Menu Customizer is absent.

Install alongside Menu Customizer 3.2.62 to remove its old competing entry hooks. Restart the game after installing both.

Validation: 50 focused pagination/navigation/unit checks under both LuaJIT and Lua 5.3, plus 28 GPU entry-rendering checks including asymmetric sprite pixels and restoration of the source image. No live gameplay session was restarted.

# KIM1025 1.7.37

Provide KIM HD artwork as a selectable sprite source for 1025Dex 1.2.44.

- Export decoded HD animation sheets through getDexSpriteSheet without exposing filesystem paths. Preserve palettes, sides, supported forms, frame order and timing.
- Respect 1025Dex's independent player/enemy sprite selections when both updated mods are active. KIM standalone behavior remains the same.

Validation: 121 real PNG/GPU atlas and production-baker checks; conditional option and provider-ownership fixtures; existing focused entry, Gen 3 update and eleven-game startup regressions.

Install 1025Dex 1.2.44 to select KIM through its settings. Restart the game after installing.

Source: [kim1025](kim1025). Full source archive: [KIM1025-source.zip](KIM1025-source.zip).

# KIM1025 1.7.36

Built from GitHub's latest 1.7.35 release. Centre visible HD artwork in Gen 3 script-picture previews, including the starter confirmation box. Use cached union alpha bounds across the animation instead of centring the transparent atlas cell. Keep the animation anchor stable and retain existing battle sprite alignment.

Validation: real GPU tests of the production HD preview, atlas bounds caching, cached Dex preview fallback and battle baselines; focused entry and Gen 3 update fixtures; startup with Menu Customizer across all eleven games. Restart the game after installing.

Source: [kim1025](kim1025). Full source archive: [KIM1025-source.zip](KIM1025-source.zip).

# KIM1025 1.7.35

Allow Menu Customizer 3.2.28 to draw Pokémon names directly at the final HUD resolution, eliminating uneven font pixels introduced by the old 1.5-pixel name capture.

- Pass only supported names to Menu Customizer and draw them once after the native HUD and party icons. Use the existing HUD band coordinates, size, opacity and DPI geometry.
- The level, HP, party balls, sprite anchors, battle frames and background geometry keep their existing paths. Without the new Menu Customizer presenter, use the original full HUD capture.
- Restore the cooperative name queue after each capture, including failures. Gen 2/3 and other renderers retain their existing HUD behavior.

Validation: 887,570 production HUD/name graphics checks with native Emerald reference glyphs, repeated-letter equality, native HP comparisons and DPI/error/fallback coverage; all KIM compilation/regression suites; all 11 game startup/settings routes with Menu Customizer; existing battle composition checks. Live ROM gameplay was not exercised.

Install Menu Customizer 3.2.28 alongside this release and restart.

## Previous release notes

# KIM1025 1.7.34

Avoid a duplicate battle frame when Menu Customizer owns Gen 3 panels.

- Skip KIM's auxiliary full-width dialogue backing when Menu Customizer 3.2.22 supplies the complete native foreground panel layout. The native foreground, trainer, Pokémon, effects and healthboxes still render normally.
- Retain the original backing fallback when Menu Customizer is missing or disabled, including both mod lookup calling conventions.
- Preserve aspect-specific HD arenas and all sprite anchors.

Use Menu Customizer 3.2.22 alongside this release for the Emerald panel ownership fix, menu backgrounds, expanded palettes and retro transitions. Restart after updating.

Validation: production ownership guard and standalone fallback tests, all KIM suites and compilation, 11-game startup integration and actual split-panel rendering checks. Live ROM gameplay was not exercised.

## Previous release notes

# KIM1025 1.7.33

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

## 1.7.32 — Ruby/Sapphire presentation

Fix HD battle surround and KIM settings in Ruby/Sapphire.

- Extend the HD backdrop to the full active viewport rather than clipping it to the fitted 240x160 rectangle, removing the white/gray surround. Native foreground sprites, battle effects and UI retain their existing placement.
- Integrate KIM's settings with the actual RS Options page and retain its game/session context when opening from Start.
- Keep modal-menu ownership, older-engine fallbacks, trainer sizing and Gen 1/2 presentation.

Update Menu Customizer to 3.2.17 alongside this release for selector colours, transparent Options replay and complete native RS healthbox names. Restart after updating. Downloaded artwork remains usable.

Validation: real HD artwork covers normal, 1080p, ultrawide and portrait viewport edges; actual Ruby/Sapphire Options settings open and persist; all KIM suites, Lua compilation and eleven-game startup checks pass. Live ROM gameplay was not exercised.

## 1.7.33

Restore aspect-specific HD battle backgrounds and close the native Gen 3 trainer gap.

- Select portrait, widescreen or ultrawide extended artwork before the original background, including after resizing. Use its embedded source-frame metadata so existing mound anchors remain authoritative.
- Remove transparent bottom rows from each native player trainer frame and meet the dialogue border. Preserve horizontal placement and throw animation offsets; leave Pokémon, healthboxes and effects unchanged.
- Retain original-art fallback and full-viewport coverage.

Install Menu Customizer 3.2.18 for a Battle Text Color picker with black as the default. Restart the game after updating. Existing downloaded art packs remain usable.

Validation: KIM regression suites and compilation, 11-game startup integration, real aspect-art selection and viewport coverage at normal/1080p/5120x1440 sizes, all cached male/female trainer frames for Ruby, Sapphire, Emerald, FireRed and LeafGreen. Live ROM gameplay was not exercised.
