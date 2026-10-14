# KIM1025 1.7.43 — Keep HD battles during native moves; remove white palette boxes

Remove 1.7.42's whole-battle animation fallback: HD scenery, Pokémon placement and the custom HUD stay active during attacks and native feedback. Restore native OAM drawing into the transparent overlay without reinstating KRBA, move assets/SFX or the catch animation-player wrapper.

Fix the specific opaque-box path. Gen 1's shaking palette-zone pass paints opaque background paper for each region. While drawing over KIM's HD scene, omit only those palette-pass paper fills on the native source canvas. Preserve zone recoloring, offsets, foreground graphics and native flash rectangles. Scope interception to that draw and restore instance methods/graphics functions on success or failure.

Based on latest GitHub 1.7.42; analyzed the user's six-second recording and the running executable's Lua source. A real GPU fixture reproduces the opaque-region pixels with pre-fallback 1.7.41. The fixed code passes 270 native feedback frames across all six player/enemy damaging/status feedback types while HD ownership remains active. All 224 player/enemy Tackle, Growl and Tail Whip picture/OAM frames match transparent native foreground output. Ten native party-ball capture cases pass. Existing compile, native method/argument, sprite alignment, Pokédex and Gen 3 tests pass under LuaJIT and Lua 5.3; KIM/Menu startup passes all eleven games under LuaJIT. The complete running gameplay session was not restarted automatically.

Use with Menu Customizer 3.2.123 and fully exit/reopen the game. Johnto remains untouched. 1025Dex stays at 1.2.54.

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

## 1.7.35

Allow Menu Customizer 3.2.28 to draw Pokémon names directly at the final HUD resolution, eliminating uneven font pixels introduced by the old 1.5-pixel name capture.

- Pass only supported names to Menu Customizer and draw them once after the native HUD and party icons. Use the existing HUD band coordinates, size, opacity and DPI geometry.
- The level, HP, party balls, sprite anchors, battle frames and background geometry keep their existing paths. Without the new Menu Customizer presenter, use the original full HUD capture.
- Restore the cooperative name queue after each capture, including failures. Gen 2/3 and other renderers retain their existing HUD behavior.

Validation: 887,570 production HUD/name graphics checks with native Emerald reference glyphs, repeated-letter equality, native HP comparisons and DPI/error/fallback coverage; all KIM compilation/regression suites; all 11 game startup/settings routes with Menu Customizer; existing battle composition checks. Live ROM gameplay was not exercised.

Install Menu Customizer 3.2.28 alongside this release and restart.

## 1.7.34

Avoid a duplicate battle frame when Menu Customizer owns Gen 3 panels.

- Skip KIM's auxiliary full-width dialogue backing when Menu Customizer 3.2.22 supplies the complete native foreground panel layout. The native foreground, trainer, Pokémon, effects and healthboxes still render normally.
- Retain the original backing fallback when Menu Customizer is missing or disabled, including both mod lookup calling conventions.
- Preserve aspect-specific HD arenas and all sprite anchors.

Use Menu Customizer 3.2.22 alongside this release for the Emerald panel ownership fix, menu backgrounds, expanded palettes and retro transitions. Restart after updating.

Validation: production ownership guard and standalone fallback tests, all KIM suites and compilation, 11-game startup integration and actual split-panel rendering checks. Live ROM gameplay was not exercised.

## 1.7.33

Restore aspect-specific HD battle backgrounds and close the native Gen 3 trainer gap.

- Select portrait, widescreen or ultrawide extended artwork before the original background, including after resizing. Use its embedded source-frame metadata so existing mound anchors remain authoritative.
- Remove transparent bottom rows from each native player trainer frame and meet the dialogue border. Preserve horizontal placement and throw animation offsets; leave Pokémon, healthboxes and effects unchanged.
- Retain original-art fallback and full-viewport coverage.

Install Menu Customizer 3.2.18 for a Battle Text Color picker with black as the default. Restart the game after updating. Existing downloaded art packs remain usable.

Validation: KIM regression suites and compilation, 11-game startup integration, real aspect-art selection and viewport coverage at normal/1080p/5120x1440 sizes, all cached male/female trainer frames for Ruby, Sapphire, Emerald, FireRed and LeafGreen. Live ROM gameplay was not exercised.

# 1.7.32

Fix HD battle surround and KIM settings in Ruby/Sapphire.

- Extend the HD backdrop to the full active viewport rather than clipping it to the fitted 240x160 rectangle, removing the white/gray surround. Native foreground sprites, battle effects and UI retain their existing placement.
- Integrate KIM's settings with the actual RS Options page and retain its game/session context when opening from Start.
- Keep modal-menu ownership, older-engine fallbacks, trainer sizing and Gen 1/2 presentation.

Update Menu Customizer to 3.2.17 alongside this release for selector colours, transparent Options replay and complete native RS healthbox names. Restart after updating. Downloaded artwork remains usable.

Validation: real HD artwork covers normal, 1080p, ultrawide and portrait viewport edges; actual Ruby/Sapphire Options settings open and persist; all KIM suites, Lua compilation and eleven-game startup checks pass. Live ROM gameplay was not exercised.

# 1.7.31

Keep larger Pokemon names crisp and unclipped with Menu Customizer 3.2.16.

Add four logical rows above the high-resolution battle HUD capture for enlarged name glyphs. Compensate the HUD crops and gauge shader coordinates so levels, HP bars and party balls keep their existing positions. Retain final-resolution battle text, the trainer cap and gap fix.

Update Menu Customizer to 3.2.16 and restart. Downloaded artwork remains usable.

Validation: original level-font pixel comparison, actual Windows LOVE high-resolution HUD and final text checks, trainer artwork checks, all KIM regression suites and eleven-game startup checks. Live ROM gameplay was not exercised.

# 1.7.30

Fix oversized trainers in maximized ultrawide windows and the gap above battle dialogue.

- Fit the desktop trainer against both window width and height instead of width alone. The default Red trainer at 5120x1440 has about 512px of visible height instead of 1024px.
- Keep the size setting, with a visible-height safety cap so the trainer stays on-screen.
- Align the visible trainer bottom with the final dialogue frame, including transparent sprite padding and the border's clear top row.
- Preserve horizontal mound positioning, send-out slide timing, mobile calibration and native/external UI fallbacks.

Restart after updating. Menu Customizer 3.2.15 remains compatible; no asset download is needed.

Validation: production trainer placement and cap checks in Lua 5.3/LuaJIT; real Windows LOVE renders using Ash and Red static artwork and all five atlas frames, visible-pixel measurements and the selected dialogue border at normal, 1080p and 5120x1440 sizes; all KIM regression suites and eleven-game startup checks with Menu Customizer. Live ROM gameplay was not exercised.

# 1.7.29

Keep Emerald battle fonts crisp with Menu Customizer 3.2.15.

- Draw commands and dialogue at their final display size instead of shrinking them into the 160px Game Boy canvas first.
- Remove the old source text copy when Menu Customizer owns the final text pass.
- Preserve all original Emerald HUD glyph pixels with a doubled capture surface while keeping the existing HUD and party-ball positions.
- Retain the native text path when the new presenter is unavailable and retain existing sprite, mound and mobile positioning.

Update Menu Customizer to 3.2.15 alongside this release. Restart after updating. Downloaded artwork remains usable.

Validation: production routing/capture regression checks, actual Windows LOVE pixel comparisons at desktop, ultrawide and portrait sizes, composed border/font comparisons, all KIM suites and eleven-game startup checks with Menu Customizer. Live game window capture timed out; gameplay was not verified.

# 1.7.28

- Remove Auto's 36%-width / 38%-height caps; use the full available mound-to-HP space.
- Always keep the player below the enemy name/HP band with a two-pixel rounding margin.
- Measure opaque ROM/static fallback pixels, including asymmetric padding, instead of image boxes.
- Add maximal-fill regressions: increasing any fitted sample by 0.1% must hit a boundary.
- Preserve 1025Dex 1.2.41, manual sizes, mound anchors, other battlers and animation transforms.

# 1.7.27

- Add AUTO to PLAYER POKEMON SIZE for desktop HD / Native Fit battles.
- Fit complete animation bounds around status/name panels at the existing mound.
- Measure KIM atlas feet once; consume 1025Dex natural-frame union and hover metadata.
- Retain manual sizes, trainer/enemy controls, mobile positioning and move transforms.

# 1.7.26

- Move ownership of the recent move-menu redesign to merged Menu Customizer 3.2.0.
- Restore the pre-redesign 1.7.21 fallback and add a thin renderer delegation bridge.
- Preserve sprites, backgrounds, assets and battle input routing.

# 1.7.25

- Match Emerald move-grid/detail-pane proportions and column spacing.
- Align single-line and wrapped move names on shared row baselines.
- Align PP with the upper row and the type block with the lower row.

# 1.7.24

- Restore matching Emerald/native menu borders and the classic Gen 3 move-grid plus PP/type layout.
- Enlarge move names by 20 percent and strengthen pixel-font strokes.
- Wrap long names onto two lines instead of reducing the whole name to fit.

# 1.7.23

- Replace the heavy double frame with four move cards and a compact detail rail.
- Add a persistent selected-move highlight and a type-colored remaining-PP meter.
- Preserve shared panel bounds, proportional glyphs and customizer opacity.

# 1.7.22

- Fill the shared command/dialog rectangle with the move-selection panel instead of fitting a smaller, bottom-aligned canvas.
- Keep glyphs proportional while enlarging the frame; fit long move names within their cells.
- Validate 21 regression suites, 47 Lua compilation checks and 72 real LOVE GPU bounds/glyph checks at desktop, ultrawide and portrait sizes.

# 1.7.21

- Remove the standalone KIM ASSETS entry from the game options menu across Gen 1/2/3. Open the existing downloader through KIM1025 > KIM ASSETS.
- Preserve downloader cache, progress, boot prompts and back navigation.
- Validation: all 21 regression suites pass, including 966 download hub checks and 339 Gen3 menu checks; all 47 Lua files compile.

# 1.7.20

- Rebase trainer 100% to the former 200% size and player 100% to the former 130% size. Both default to 100%, with further increases to 200%.
- Use new trainer/player setting keys so saved percentages from the old baselines are not misinterpreted.
- Replay Native Fit enemies using natural 1025Dex frames at the painted mound, making the enemy size control effective and removing sprite-box padding from ground alignment.
- Preserve animation provider updates, intro visibility and mobile calibration.

# 1.7.19

- Add desktop TRAINER SIZE, PLAYER POKEMON SIZE and ENEMY POKEMON SIZE menu controls (50–200%, 10% steps).
- Default trainer/player to 130% of the corrected presentation; keep enemy at 100%.
- Preserve player mound and trainer dialogue anchors while resizing.
- Retain mobile calibration and live 1025Dex artwork.

# 1.7.18

Fix desktop Native Fit player Pokemon oversizing and mound alignment. Replay the trimmed 1025Dex frame at the actual authored mound anchor instead of through the UI scale. Trainer presentation is unchanged.

# 1.7.17

Reduce the desktop HD trainer scale and stop retired KIM player-size settings from enlarging 1025Dex battle pictures. Preserve trainer dialogue anchoring, provider animation, native-fit replay and mobile calibrations.

# 1.7.16

Render full Native Fit player Pokemon beneath translucent battle menus.

# 1.7.15

Lower portrait trainer only; retain accepted landscape and desktop geometry.

# 1.7.14

Enlarge desktop trainer and pin its bottom to the dialogue top.

# 1.7.13

Fix trainer ownership in Native Fit, platform alignment and footer geometry; lower iOS trainer baselines.

# 1.7.12

Fix desktop trainer oversizing and iOS portrait/landscape trainer placement.

# 1.7.11

Use native Vanilla move frames and preserve Emerald red border thickness on both panels.

# 1.7.10

Fix landscape/desktop move rendering; suppress duplicate source menus; reuse Battle UI Customizer Emerald frames and opacity.

# 1.7.9

Dedicated two-column Gen 1 move panel; readable PP and type without crop/distortion; square physical glyph scaling and grid navigation. Native Gen 3 menus preserved.

# 1.7.8

Removed bundled 3D stage integrations, PokÃ©mon stage providers, automatic KRBA stage registration, and 3D dependencies. Preserved the four selected features and flat-renderer iOS/alignment fixes.

# KIM1025 1.7.7 â€” focused features

Keep animated PokÃ©dex sprites, HD battle backgrounds, trainer choices and the 165 Gen 1 move animations. Remove the other bundled features and reduce settings to one short native page.

Preserve the iOS/Android layout, orientation, Retina scaling, touch boundaries, trainer grounding and move/catch alignment fixes. Saved alignment preferences remain usable internally. Native/1025Dex PokÃ©mon providers remain authoritative; the Gen 1 native picture layer is no longer skipped when both PokÃ©mon are replayed over HD art.

Replace the complete previous mod folder, keep the downloaded cache, and restart. Background pack 1.0.0 is unchanged, so already downloaded artwork is reused.

Validation: 19 suites, 55 Lua compilation checks, 225 additional checks against the installed 1025Dex hook, 26 provider GPU checks and 9 trainer GPU checks. Full ROM and physical iPhone gameplay remain unverified.

## 1.7.6 â€” Live 1025Dex battle sprites and settings submenus

KIM's fullscreen Gen 1 battle scene now calls the active battle.mon_pic provider for each player and enemy frame. This allows 1025Dex to supply its own artwork and animation clock even while KIM suppresses the duplicate native sprite layer. The provider's pending signal hides the sprite until its custom sheet is ready, instead of flashing vanilla art. Available KIM metadata no longer displaces a claimed 1025Dex sprite. Native picImage resolution also retains the external provider's live image. Existing 1025Dex animation options and intentional pauses are preserved.

Settings now use Pokemon, Battle, Interface, Title Screen and Advanced submenus, including smaller Battle and Interface pages. Existing saved values are preserved; KIM Assets remains on the main page.

Install kim1025-1.7.6.zip (about 9 MB), replace mods/kim1025, keep 1025Dex and WildFollowers enabled, preserve downloaded asset caches, and fully restart Gen1Recomp. No artwork redownload is required for this code change.

Validation: all 20 automated suites pass and 92 Lua files compile. The installed 1025Dex 1.2.34 live scene hook and actual animation clock pass 233 provider/suppression checks, including front/back animation resuming after EE pauses. The regression fails against v1.7.5. The installed Mac LOVE graphics runtime passes 26 GPU checks with the actual Dex hook/clock. Full ROM gameplay and physical iOS testing remain unverified.

## 1.7.5 â€” Gen 1 battle sprite conflict with 1025Dex

Fixes a second sprite provider drawing over KIM's continuously animated Pokemon. 1025Dex can replace KIM's transparent native-slot sprite inside its own pics-layer wrapper. KIM now resolves the final native picImage boundary: it suppresses that covering copy in the HD scene, and supplies the current KIM frame in native battle presentation. The guard applies to both player and enemy, independent of mod load order. It yields when KIM battle sprites are disabled or their source is unavailable, and preserves trainer and send-out ownership.

Install `kim1025-1.7.5.zip` (about 9 MB), replace `mods/kim1025`, keep the downloaded asset cache, and fully restart the game. 1025Dex and WildFollowers can remain enabled. The asset pack stays at version 1.0.0 and does not need downloading again.

Validation: 18 runnable suites passed and 88 Lua files compiled. The new regression checks both load orders and repeated player/enemy loops (108 checks), also passing against the installed 1025Dex 1.2.34 Gen 1 wrapper. The installed Mac LOVE runtime passed 52 GPU checks, including 24 live player/enemy frame checks composited through that actual Dex wrapper. Full ROM and physical phone gameplay remain unverified.

## 1.7.4 â€” Downloader selector and Gen 1 battle animation

The KIM ASSETS downloader now draws a visible selection arrow beside the selected download or removal option, independent of the game's font.

Red/Blue/Yellow battle constructors receive HD Pokemon art as soon as its assets are available. Native battle draws use an immutable image for each animation frame so image-processing caches cannot freeze a reused canvas; the fullscreen HD pass uses the same frame-safe presentation. Animation continues across repeated loops. Missing assets retain vanilla fallback, and ANIMATION OFF still holds the first frame.

Install `kim1025-1.7.4.zip` (about 9 MB), replace the installed `mods/kim1025` folder, keep the downloaded asset cache, and restart. The existing KIM1025 artwork pack remains version 1.0.0, served from release v1.7.3; installed artwork does not need another download.

Validation: 17 runnable regression suites passed; 86 Lua files compiled. Includes 930 downloader checks and 73 battle constructor/animation checks. The installed Mac LOVE runtime passed 28 GPU checks for selector positioning and repeated animation through an image-processing cache. Full ROM and physical phone gameplay remain unverified.

## 1.7.3 â€” Persistent in-app KIM1025 assets

The installable mod ZIP is now about 9 MB. The 216 portrait, widescreen and ultrawide battle backgrounds live in an independently versioned KIM1025 artwork pack, downloaded once into the persistent mod cache. Future code updates retain this cache and do not require another 400+ MB download.

Open KIM ASSETS in the main KIM asset downloader. DOWNLOAD ALL installs missing original KIM packs, then KIM1025 assets. DOWNLOAD KIM1025 installs only the new artwork pack. Users with original KIM assets already installed are prompted for KIM1025 assets after updating. B defers the prompt; the download remains available in KIM ASSETS. Existing packaged artwork can migrate locally when upgrading in place; a clean small mod installation downloads the artwork.

Install `kim1025-1.7.3.zip`, close the game, replace `mods/kim1025` with its extracted `kim1025` folder, retain the downloaded asset cache, and restart. Accept the in-app download prompt. `KIM1025-assets-v1.0.0.zip` is an artwork pack used by the downloader, not an installable mod ZIP. Pack version 1.0.0 remains independent of code version 1.7.3. Keep release v1.7.3 and its asset ZIP available for future clients.

Each downloaded artwork file is SHA-256 checked before installation. Completion is recorded only after extraction and metadata/index writes succeed. Original KIM and KIM1025 packs use separate cache namespaces and separate removal indexes. Cancelling an asset download defers missing packs, and retry resumes the failing pack without restarting installed original packs. The existing portable and mobile download paths are reused.

Validation: all 17 runnable headless suites pass and 86 Lua files compile, including 426 hub-flow checks and 90 production ZIP/cache checks. Full-pack validation in the installed Mac LÃ–VE runtime passed 12 checks, verified all 216 real artwork hashes, and decoded portrait, widescreen and ultrawide art. Full ROM and physical phone gameplay remain unverified.

# KIM1025 1.7.2

Fixes small or misplaced player trainers in mobile HD battle intros. Trainers now draw once, at the authored player platform, at a readable size that scales with the arena rather than the native UI. ROM/default trainer art and BATTLE SPRITES OFF use the same alignment. Native slide timing, animation, desktop presentation, Safari/demo scenes, and external stage ownership are preserved.

Includes the v1.7.1 player Pokemon animation fix and all supporting libraries, data, and packaged artwork.

Install the complete KIM1025-v1.7.2.zip: close the game, replace mods/kim1025 with its extracted kim1025 folder, retain the external downloaded asset cache, and restart. Avoid a nested kim1025/kim1025 folder. The small hotfix is an overlay: merge into an existing full installation and keep assets.

Validation: 15 runnable headless suites pass, including 82 trainer-intro checks; 83 Lua files compile. The previous build reproduces the trainer scale failure. The installed Mac game's LÃ–VE runtime rendered the production trainer code and actual art in an isolated test scene at 1320x2868 and 660x1434; 9 GPU checks pass and visible trainer contact is within one pixel of the platform anchor. This was a renderer fixture, not a full ROM gameplay test or physical iPhone test.

---

## 1.7.1

- Fix Gen 1/2 native battle sprite canvases inheriting the player-slot clip rectangle, which could prevent new animation frames from reaching cached sprites.
- Fix the Gen 2 virtual battle sprite path decoder and define its renderer before the refresh callback uses it.
- Give cooperating battle scenes immutable HD canvases per frame so image preprocessing caches do not freeze player or enemy animation.
- Add 44 headless regression checks for player frame advancement, Gen 2 bridge resolution, scene caching, preserved clipping, and animation/sprite toggles.

## 1.7.0

- Gen 3 Start Menu â†’ KIM1025 opens the complete native settings page. UI SETTINGS and BATTLE SETTINGS expose the complete schema, including player/enemy size. OPTIONS also retains KIM1025 and ASSETS access; OPTIONS â†’ MODS â†’ KIM1025 uses the expanded registered schema.
- Gen 3 HD backgrounds can use KIM1025's packaged complete arenas when the external PNG pack is absent. Embedded platform coordinates are respected. HD BATTLE BACKGROUNDS OFF restores the native field. Hoenn environments without suitable art retain their native scenes.
- Adds upstream Gen 3 Modern menus, dialogue, naming, Trainer Card, storage, Summary, PokÃ©dex and lower battle panels, readability fixes and controller navigation improvements.
- Adds cooperative 1025Dex routing: supported #001â€“386 HD art uses KIM, expanded species retain the Dex art provider. Missing HD files fall back safely. Turning BATTLE SPRITES off restores the provider.
- Adds upstream Unown/Deoxys form metadata, layered asset upgrades, Gen 2 Summary and Battle Art compatibility, and responsive UI fixes.
- Preserves the kim1025 mod ID, existing settings/cache ownership, custom portrait/widescreen/ultrawide arenas, Gen 1 sizing controls and mobile/iOS corrections. General UI font scale now follows upstream's 200% cap.

## 1.6.31

- Add 72 location-specific complete 32:9 arenas with blended scenery and preserved original mound coordinates.
- Automatically select ultrawide images at viewport ratios of 3:1 or wider.
- Prevent inherited native-menu scissor clipping from leaving side bars.
- Add 3840Ã—1080, 5120Ã—1440 and 7680Ã—2160 coverage and alignment regressions.

## 1.6.30

- Replace layered portrait/widescreen backdrops with 144 complete, location-specific HD arenas.
- Composite the original mound regions at fixed coordinates, preserving existing PokÃ©mon alignment.
- Remove the backdrop blend shader and retain a single active arena texture.
- Validate all 72 scenes, platform renderer paths, image decoding and existing generation bridges.

## 1.6.26

- Fix the Gen 1 fullscreen enemy draw calculation to read ENEMY PKMN SIZE, including native/1025Dex art when KIM sprites are disabled.
- Correct outdoor power-plant exterior, Mt. Moon and Silph Co extension family mappings.
- Draw extensions in mobile landscape as well as portrait.
- Align native/Dex sprites to the HD arena in landscape and remove the desktop player vertical compensation on mobile.
- Verify actual Gen 1 draw scales at 50%, 100%, 150% and 200% with both art providers and orientations.

## 1.6.25

- Register PLAYER PKMN SIZE and ENEMY PKMN SIZE in the standalone FireRed/LeafGreen bridge, which returns before the Gen 1 option schema is loaded.
- Add the enemy-size row to all Modern UI category maps so the saved value is exposed and read correctly on desktop and mobile.

## 1.6.24

- Fix ENEMY PKMN SIZE being bypassed by the fullscreen/native handoff scale seam.
- Apply the enemy multiplier before native source sprites are suppressed, so the setting remains effective across KIM fullscreen and fallback battle paths.

## 1.6.23

- Add ENEMY PKMN SIZE with the same 50%â€“200% range and 5% steps as PLAYER PKMN SIZE.
- Apply the enemy multiplier consistently to fullscreen KIM battles, FR/LG battle rendering, cooperative staged scenes and Battle Art 3D presentations.
- Keep the calibrated 100% enemy presentation unchanged.

## 1.6.22

- Fix portrait extension mismatches by deriving the extension from the exact backdrop selected for the original battle image.
- Prevent field battles from receiving unrelated industrial/interior scenery when the router state changes between lookups.

## 1.6.21

- Add generated portrait extension layers for every current HD battle-background family.
- Keep the original landscape art as an unchanged middle band so platforms, sprites and HUD anchors do not move.
- Tint only the extension for night, sunrise and sunset variants; preserve the original variant artwork exactly.

## 1.6.20

- Keep portrait AUTO backgrounds at full battlefield width when KIM battle sprites are disabled.
- Apply portrait platform alignment and duplicate-source suppression to the active native/1025Dex sprite provider with KIM sprites OFF.
- Preserve explicit NATIVE FIT, desktop/landscape AUTO behavior, and the iOS orientation fix.

## 1.6.19

- Align mobile portrait fallback battlers with the authored HD platforms instead of the centered native battle slots.
- Keep one visible fallback sprite and preserve its active provider, including 1025Dex art.
- Remove the desktop-only player ground compensation from portrait scenes; retain the iOS orientation fix.

## 1.6.18

- Fix the KIM-owned flat HD battle scene on iOS: compose this top-origin canvas upright instead of applying the voxel pipeline's vertical mirror.
- Keep orientation local to the marked flat canvas during final composition; preserve other providers, animations and overlay coordinates.

## 1.6.17

- Fix upside-down iOS Battle Art scenes by deferring world orientation to current gen1recomp.
- Restrict the legacy correction to Battle Art's actual canvas and refresh moving scenes every frame.

# Changelog

## Compat v1.6.15 â€” Fix duplicate battles in narrow desktop windows

- Use the single flat battle presenter in portrait desktop windows as well as native mobile.
- Replay native trainers, Pokemon, effects and HUD from the canvas used by that presenter.
- Keep landscape desktop presentation and existing mobile positioning.

## Compat v1.6.14 â€” Halve iOS enemy offset

- Reduce iOS horizontal trim from sixteen to eight native game pixels.
- Preserve the sprite visibility fix and other platform positioning.

## Compat v1.6.13 â€” Restore sprite visibility

- Remove the animation-state copying hook that broke live visibility updates.
- Apply horizontal trim only while native front-picture pixels are drawn.
- Restore temporary providers/graphics interception after success or error.
- Test mutable presentation state, hidden-to-visible transitions and actual draw coordinates.

## Compat v1.6.12 â€” Apply horizontal trim in the actual draw path

- Replace the ineffective exported sprite-centre hook with a copied presentation offset.
- Preserve cached animation state and avoid double-shifting KIM cards.
- Add a regression exercising the actual native sprite draw, not only its exported helper.

## Compat v1.6.11 â€” Increase iOS enemy horizontal trim

- Move iOS HD-background enemies another eight native game pixels right.
- Preserve other platforms and all vertical placement.

## Compat v1.6.10 â€” iOS enemy horizontal trim

- Add four extra native pixels right on iOS HD battle backgrounds only.
- Preserve desktop/Android placement, enemy height and player alignment.
- Exercise the compositor on Linux, Windows, Android and iOS platform fixtures.

## Compat v1.6.9 â€” Enemy mound placement

- Nudge HD-background enemies four native pixels right and three up.
- Retain Dex ground correction, hover/elevation, animation and player placement.

## Compat v1.6.8 â€” OPTION / ASSETS

- Move asset management from Start/title menus to OPTION and rename the row ASSETS.
- Native Gen3 uses an A-only action with B returning to the existing OPTION layer.
- Preserve downloads, maintenance, sprite compatibility and background filling.

## Compat v1.6.7 â€” HD background viewport coverage

- Ensure FR/LG HD battle backgrounds cover every edge of the fitted battle viewport at any screen size or orientation. Expand whole image axes only where needed and clamp framing to available overscan.
- Preserve native battler, HUD, particle and menu coordinates and 1025Dex ownership.
- 239 sprite/compositor checks and 326 asset-manager checks pass.

## Compat v1.6.6 â€” Merge upstream 1.6.2

- Merge all upstream 1.6.2 asset-management, portable/mobile download, Party/Summary,
  Gen2 menu and iOS Battle Art changes.
- Preserve 1025Dex picture/icon ownership, shiny animation and enemy ground alignment.
- Retain explicit readable native text colours and protected graphics state in
  the new native asset-manager host.

## Upstream v1.6.2

- Added HD Asset Manager removal/re-download support for the persistent external HD PokÃ©mon/background cache. Removed assets can be downloaded again immediately or later; KIM does not force a new download after removal.
- Added Gen1Recomp portable-mode Asset Manager support using the engine's binary-safe downloader and native temporary-file handoff while keeping final assets in portable-aware `mod.cache`.
- Added a native FireRed/LeafGreen **KIM ASSETS** Start Menu entry for downloading, removing, and re-downloading the shared HD pack.
- Fixed Android/iOS FR/LG asset downloads by reopening the engine-owned temporary ZIP through Gen1Recomp's native save-directory helper before extraction.
- Corrected FR/LG installed-pack controls to **A = REMOVE / B = CLOSE**, with a second **A** confirmation before deletion.
- Fixed Gold/Silver/Crystal mobile lookup of downloaded National Dex #152â€“251 HD assets so the external pack is actually used after a successful download.
- Fixed FR/LG in-battle Party/Summary presentation so KIM's battle compositor no longer overwrites final-resolution HD menu PokÃ©mon/icons while a full-screen Game3 menu owns the frame.
- Added a KIM-side FR/LG provider-cycle guard for GameShark when **BATTLE SPRITES = OFF**, preventing recursive native-sprite delegation without changing GameShark.
- Fixed the Gen 2 Modern Start Menu at larger UI scales/densities so the selected native row always remains visible, including **MODS** and **QUIT**.
- Reworked the iOS/LÃ–VE 12 Battle Art orientation bridge at the final world handoff. The correction follows Battle Art's live 3D world directly, uses Battle Art-compatible canvas handling, and leaves KIM HUD/UI/touch layers unflipped.

## v1.6.5 â€” Enemy ground alignment with 1025Dex

- Compensate Dex small-picture lift and native front-picture padding while KIM HD backgrounds are active.
- Preserve enemy hover, doubles layout, transforms, animation and native bounce.
- Keep player placement, ghost/substitute and non-HD battles unchanged.

## v1.6.4 â€” Visible Gen3 asset installer

- Draw asset-manager text through Gen3 Window.printPx with explicit dark colours.
- Use a native 240x160 window and isolate shader/scissor/blend state while drawing.
- Defer Gen3 party/PC/Pokedex icon providers and the HD icon replay overlay to 1025Dex.
- Preserve native stack controls, asset downloads and 1025Dex sprite compatibility.

## v1.6.3 â€” Gen3 asset manager

- Open the KIM HD asset installer through the native Gen3 singleton screen stack.
- Route update, input, draw and close through the correct Gen3 layer methods.
- Give the KIM ASSETS row a stable id and handle selection on older Gen3 menus.
- Retain the 1025Dex sprite compatibility from v1.6.2.

## Compat v1.6.2 â€” 1025Dex compatibility

- Detect 1025Dex v1.2.5 sprite ownership on Gen3 startup and reload.
- Preserve Dex animated front/back sprites, shiny palettes and height metadata.
- Skip competing HD battler/menu preview overlays while Dex owns pictures.
- Retain KIM HD backgrounds, native foreground/VFX/HUD and standalone sprite behavior.

## v1.6.1

- Hardened Gen 1 Android/mobile battle rendering against graphics-state leaks that could accumulate into `Maximum stack depth reached`.
- Decoupled the Gen 1 Modern battle dialog/command layout from virtual TouchControls visibility so controller-equipped Android devices keep the lower battle UI with touch controls hidden.
- Restored the first Oak's Lab rival intro using KIM's packaged `garyfrontplayer` art at the corrected mobile scale and suppressed the duplicate native rival image during the outro.
- Expanded Gen 1 NEW GAME Modern UI coverage while keeping Oak's native intro artwork/timing and source game state ownership intact.
- Added KIM Modern UI presentation for the initial Gen 1 `WHICH PC?` menu while preserving native PC rows, callbacks, Player PC, and Bill's PC behavior.
- Added a narrowly scoped iOS Battle Art world-orientation compatibility bridge for the affected Apple/Metal renderer, based on Battle Art's current world-canvas correction strategy. KIM HUD/UI layers remain unflipped.
- Preserved native presentation when Modern UI or the applicable per-surface setting is disabled.
- Gen 2/Crystal and Gen 3/FireRed-LeafGreen battle paths remain unchanged by the Gen 1 mobile fixes.

## v1.6.0

- Split large HD battle artwork from the normal KIM ZIP and added the in-game HD Asset Manager with persistent caching.
- Moved the large HD battle asset pack to persistent external cache so users download it once on v1.6.0 and reuse it across future KIM updates.
- Expanded Gen 2 Modern UI to the title/main menu and complete NEW GAME setup flow.
- Fixed Gen 2 Modern UI master/per-surface gating and removed the stray MAPA Start Menu row.
- Added presentation-only Dex Radar 1.2.0 compatibility on Gen 1 and Gen 2 without modifying Dex Radar.
- Added Gen 1 BATTLE BG MODE with AUTO / FULLSCREEN / NATIVE FIT framing for HD or vanilla battlers.
- Corrected Gen 1 widened-field trainer placement/size, enemy move-side animation ownership, and lingering KRBA BG/FG planes.
- Improved FR/LG missing-HD fallback and BATTLE SPRITES OFF stability.
- Restored the small local battle-support/trainer assets required by the slim core.

## v1.5.0

- Added Gold / Silver / Crystal and FireRed / LeafGreen support paths.
- Added HD animated PokÃ©mon support through #251 in G/S/C and #386 in FR/LG.
- Added HD PokÃ©mon icons #001â€“386 across all supported games.
- Added `POKEMON ICONS` ON/OFF control.
- Added G/S/C native-battle HD PokÃ©mon integration.
- Added FR/LG HD battles, menu/PokÃ©dex/Summary previews, and HD battle-background support.
- Added final-resolution G/S/C and FR/LG menu rendering.
- Fixed FR/LG mobile duplicate HUD/menu rendering, portrait/landscape placement, `SCREEN POS`, and menu PokÃ©mon alignment.
- Improved HGSS_SPRITES icon ownership and Gen 1 battle isolation.
- Preserved existing Gen 1 Battle Art and PotatoVoxel compatibility.

## v1.4.1

- Added Gen1Recomp 0.3.1 compatibility.
- Added HGSS_SPRITES Gen 1 battle hard block.
- Preserved Battle Art and PotatoVoxel compatibility.

## v1.4.0

- Public Gen 1 HD battle release.
- Added the Gen 1 HD animated PokÃ©mon battle pipeline and HD battle backgrounds.
