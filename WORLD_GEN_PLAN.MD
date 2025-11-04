# World Generation Plan

## Deterministic streaming world backbone
To support an "infinite" space that reconstructs itself when revisited, we need to replace the current one-shot foe spawning in `WorldScene` with chunk-oriented world data that is generated on demand and cached by seeded coordinates. `WorldScene` already orchestrates per-frame systems, making it the natural host for chunk streaming hooks, while the existing spawn system only tracks foe groups relative to the player without any terrain context.

**Key tasks – Implement deterministic chunked world streaming**
1. Create `modules/world/chunk_manager.lua` that hashes `(chunkX, chunkY)` with a global world seed to produce reproducible noise seeds; expose APIs to `ensureChunkLoaded(world, chunkX, chunkY)` and `iterateActiveChunks(world)` using player position and a configurable radius.
2. Extend `WorldScene.new` to accept a `worldSeed` and initialize the chunk manager, storing a `world.generatedChunks` table keyed by chunk coordinates; hook chunk streaming into `WorldScene:update` before spawn/culling so downstream systems see consistent data.
3. Cache chunk contents (terrain tiles, biome id, generated entities) in serialized tables inside `world.generatedChunks`, so backtracking reuses the same tables and `spawnSystem` no longer randomizes per visit.

## Biome rules and transitions
We need a structured way to declare biome characteristics (terrain palette, foliage/structure tables, foe pools). Right now only generic foe types exist, so biomes must own their spawn lists and crossfade logic for transitions (forest → desert).

**Key tasks – Author biome definition schemas**
1. Add `data/biomes.lua` describing each biome (id, noise threshold ranges, tile colors, prop tables, foe type weights, structure weights).
2. Build a `modules/world/biome_resolver.lua` that samples coherent noise (e.g., OpenSimplex) using chunk/world coordinates plus the global seed, returning biome ids and transition blending factors for edge smoothing.
3. Update chunk generation flow to stamp biome id on each chunk, storing transition strength so the renderer can fade grass-to-sand and systems know which spawn tables to use.

## Procedural population per biome
Each biome should populate foes, foliage, and structures deterministically. Current spawn logic only scatters foes around the player without terrain awareness.

**Key tasks – Populate biome-specific content deterministically**
1. Refactor `systems/ai/spawn.lua` into a biome-aware service (e.g., `modules/world/spawn_resolver.lua`) that reads chunk biome metadata and seeds RNG with chunk coordinates before instantiating foes from biome-configured tables.
2. Introduce lightweight structure factories under `entities/structures/` (houses, trees, desert rocks) that output component bundles, all rendered with simple Love2D primitives until art arrives.
3. During chunk generation, roll structures/props once, store entity descriptors in the chunk cache, and have a new `systems/world/chunk_activation.lua` add/remove entities as the player enters/exits chunk visibility.
4. Track defeated foes/looted structures by writing state flags back into the cached chunk table so revisiting preserves cleared areas.

## Rendering placeholders and biome blending
The current world renderer only draws a uniform grid; we need layered drawing per biome (ground tint, props, structures) and smooth visual blending between forest and desert chunks.

**Key tasks – Render biome terrain and props with engine primitives**
1. Replace the grid background with a tile/patch renderer that samples chunk biome data and draws colored quads or triangles representing grass, dirt, or sand palettes.
2. Add a transition pass that interpolates colors between adjacent biome tiles using the stored blending factors from the biome resolver.
3. Introduce draw helpers for placeholder trees (stacked circles/rectangles), houses (rectangles + roofs), and desert rocks (polygons), keyed off structure components so swapping to art assets later is straightforward.
4. Maintain a render order (ground → props → entities → overlays) inside `render_world` to keep silhouettes readable without sprite art.

## Minimap and navigation feedback
A minimap will reinforce exploration across an infinite procedural space and help communicate biome boundaries.

**Key tasks – Build chunk-driven minimap overlay**
1. Add a `ui_minimap.lua` system that samples nearby chunk metadata and renders a scaled, top-down view (colored dots for biomes, icons for structures/foes) in screen space using Love2D primitives.
2. Implement fog-of-war by tracking visited chunk coordinates in `world.visitedChunks` and only drawing discovered areas.
3. Integrate the minimap draw call after existing UI systems in `WorldScene.systems.draw`, and expose toggles/zoom controls via input handling to avoid clutter.

## Persistence hooks and world seed management
To ensure deterministic regeneration across sessions we must manage seeds and saved state deliberately.

**Key tasks – Persist world seed and chunk state**
1. Update `main.lua` bootstrap to create or load a `worldSeed` (e.g., from save files or a fixed constant) and pass it into `WorldScene.new`.
2. Design a serialization format (JSON or Love filesystem data) for `world.generatedChunks` that writes pruned chunk state (biome id, structures, defeated foe flags) when exiting to the main menu; load it on startup to avoid regenerating cleared areas.
3. Provide developer hooks (debug overlay or console command) to reset the world seed for testing and to visualize chunk boundaries during tuning.
