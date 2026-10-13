## 1.7.3 — Persistent in-app KIM1025 assets

The installable mod ZIP is now a small code-and-animation update. The 216 portrait, widescreen and ultrawide battle backgrounds live in an independently versioned KIM1025 artwork pack, downloaded once into the persistent mod cache. Future code updates retain this cache and do not require another 400+ MB download.

Open KIM ASSETS in the main KIM asset downloader. DOWNLOAD ALL installs missing original KIM packs, then KIM1025 assets. DOWNLOAD KIM1025 installs only the new artwork pack. Users with original KIM assets already installed are prompted for KIM1025 assets after updating. B defers the prompt; the download remains available in KIM ASSETS. Existing packaged artwork can migrate locally when upgrading in place; a clean small mod installation downloads the artwork.

Install `kim1025-1.7.7.zip`, replace the complete old `mods/kim1025` folder, keep the downloaded asset cache and restart. The unchanged artwork pack is pinned to release v1.7.3; retain that release and its asset ZIP for existing and future clients.

Each downloaded artwork file is SHA-256 checked before installation. Completion is recorded only after extraction and metadata/index writes succeed. Original KIM and KIM1025 packs use separate cache namespaces and separate removal indexes. Cancelling an asset download defers missing packs, and retry resumes the failing pack without restarting installed original packs. The existing portable and mobile download paths are reused.

Validation: all 19 regression suites pass; the selector, upgrade prompt, download queue, verification, cancellation and persistent cache checks are retained.
