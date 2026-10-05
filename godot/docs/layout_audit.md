# World 1 layout audit — 2026-09-30

## Issues found and corrections

| Issue | Cause | Correction and prevention |
| --- | --- | --- |
| Optional raft chain around x=6,560–7,880 had origins 190–320 px apart, with uneven vertical changes and online-only movers. A player could see platforms without a reliable next landing. | Placements were authored by visual spacing, without checking actual horizontal reach, elevation, moving range, or connection state. | Rebuilt it as a continuous optional chain with 150 px origin spacing and rises no greater than 60 px, from the main route back to the main route. Preview each transition with current jump/dash tuning and both connection states. |
| The level ended at x=8,000 with the portal at x=7,770, leaving no room for the requested larger coastal scene. | The camera limit, map length, portal and content layout were treated as separate values. | Extended the world and camera range through `length: 9600`, added three main platforms with 140 px clear gaps, and moved the portal onto the final platform at x=9,370. Keep gameplay objects inside the authored level length. |
| Godot source changes could be missed by the browser build. | The Web export is a static PCK loaded from `dist/index.pck`, separate from editable source files. | Re-exported and replaced the PCK, updated its byte size in `dist/index.html`, validated the package in Godot, and ran `verify-loader.cjs`. Always rebuild and verify the Web PCK after source edits. |
| A new patrol at x=5,900 killed the scripted traversal before the extension test reached its first jump. | The test assumed the original single enemy and did not handle new patrols. | Moved this patrol onto the optional upper route at x=8,220 and made the traversal test dash against every live patrol it encounters. Tests that traverse a route must account for the current enemy collection and verify the portal endpoint. |

## Additional interface and challenge issues

| Issue | Cause | Correction and prevention |
| --- | --- | --- |
| Tutorial notice used fallback typography, a plain navy rectangle and dominant cyan unlike the approved HUD/menu. | The sign renderer had its own one-off styling instead of shared UI tokens. | Matched notice typography and colors to the pixel HUD palette, with a stepped frame and short shadow. Reuse menu/HUD typography, colors and frame language for future notices. |
| New palms were still shorter than Brisin despite scale values above 1. | Source canvas dimensions and arbitrary scale factors were used instead of visible pixel bounds. | Compared rendered nontransparent palm and player heights at final scale; updated the new palms to 107–112 px against Brisin's 100 px. Measure visible bounds for all relative-size requirements. |
| Extra Ruídozinhos were not receiving pulse/respawn behavior, and one placement disrupted the guided traversal. | Runtime retained a single `enemy` reference; test and encounter placement assumed one enemy. | Stored all patrols in an array and broadcast shared events; moved the patrol off the early required route. Keep enemy arrays in sync with combat/reset logic and include encounters in traversal tests. |
| A new patrol under the first optional island caused an unintended stomp bounce during the jump into the gem route and disrupted the main-route test. | Patrol interaction height extended into both the upper route's takeoff/landing lane and nearby main-route jumps. | Moved that patrol to a later flat main island at x=7,700; tests check the first island landing with enemies present and separately verify pulse reaches added patrols. Keep mandatory entry/landing lanes clear or prove the counter mechanic works in play. |
| A patrol assigned to a signal platform could remain active while that platform was absent Offline. | Enemy updates did not share the platform's connection-state visibility. | Made the high-route patrol Online-only and synchronize its visibility/simulation with the platform state. Verify both Offline and Online states for hazards tied to conditional platforms. |
| The UI smoke test initially failed its fresh-game assertion after the route test wrote a completed save. | Godot integration tests shared persistent `user://` progression between runs. | Reran stateful tests with an isolated data directory. Isolate or restore saves before interpreting results from fresh-start tests. |

## Verification

- Parsed and loaded `data/world_01.json` through Godot 4.5.1.
- Ran `tests/integration.tscn` headless at 60 FPS: **25 passed, 0 failed** after all current edits.
- Ran `tests/asset_interactions.tscn`: **21 passed, 0 failed**; the gem route was reached with player input, pulse/reset covered added patrols, and the Online-only patrol followed platform state.
- Ran `tests/ui_integration.tscn` in an isolated user-data directory: **38 passed, 0 failed**.
- The no-teleport traversal crossed the extended main route, defeated patrols encountered there, and activated the portal. It issued seven jumps along the extension.
- Regenerated `dist/index.pck`, updated its byte count in the loader, checked the PCK loads in Godot, and passed `verify-loader.cjs`.
- Palm proportions were verified from rendered alpha bounds. Notice styling was verified by source review; no in-game visual capture or manual browser playthrough was available.
