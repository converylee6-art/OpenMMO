# Meshy Asset Requests — Oriana Overworld

Generate these in Meshy (Text to 3D, then Texture). Send me the `.glb` files as you finish each batch.
Work top to bottom: Batch 1 is enough to build and test Pine Town + Route 101.

## Global settings (use for every asset)

- **Export:** GLB, PBR textures (albedo, normal, roughness/metallic), 2K textures.
- **Style prefix** (paste at the start of every prompt):
  `stylized Pokémon-style game asset, Scarlet and Violet art direction, clean readable shapes, soft hand-painted PBR textures, slightly saturated colours, no text, no people, single object on white background,`
- **Polycount:** props 3k–10k tris, trees 8k–15k, buildings 20k–40k. Pick the medium quality preset.
- **Orientation:** front of the object facing the camera, standing upright, resting on the ground plane.
- **No interiors.** Buildings are shells; I build interiors separately as simple rooms.
- **Naming:** save as `<batch>_<name>.glb` exactly as listed, e.g. `b1_house_player.glb`.
- **Variants:** where I ask for `x3`, generate the same prompt three times and keep the three best (suffix `_a _b _c`).

## Batch 1 — Pine Town + Route 101 (starting area)

### Buildings
| File | Prompt (after the style prefix) |
|------|--------------------------------|
| `b1_house_player` | small cosy two-storey family cottage, orange clay-tile roof, cream plaster walls, dark wood beams, round attic window, flower boxes under windows, wooden front door |
| `b1_house_neighbor_a` | small one-storey village cottage, orange tile roof, white walls, blue wooden door and shutters, small chimney |
| `b1_house_neighbor_b` | small village cottage, green tile roof, pale yellow walls, stone base, wooden door, climbing ivy on one wall |
| `b1_professor_lab` | wide modern research laboratory building, white walls with large glass windows, flat teal roof with a small satellite dish and skylight dome, double glass doors, small sign post out front |
| `b1_town_gate_route` | wooden village gate arch across a dirt path, two thick timber posts, pitched shingle roof, hanging wooden sign, lantern on each post |

### Nature
| File | Prompt |
|------|--------|
| `b1_pine_tree` x3 | tall stylized pine tree, layered conical dark-green needle clusters, brown bark trunk, slight lean, game-ready |
| `b1_pine_tree_young` x2 | small young pine sapling, bright green needles, thin trunk |
| `b1_bush_round` x2 | round leafy green shrub, dense stylized foliage clusters |
| `b1_bush_berry` | round green shrub with clusters of small red berries |
| `b1_grass_tall_clump` x3 | clump of tall wild grass for Pokémon encounters, stylized blade cards, darker green at the base, lighter at the tips, game foliage |
| `b1_flowers_wild` x2 | small patch of wildflowers, white, yellow and pink blooms on short green stems |
| `b1_rock_small` x3 | small grey mossy boulder, rounded, stylized |
| `b1_rock_large` x2 | large grey boulder with moss patches and lichen, climbable ledge shape |
| `b1_log_fallen` | fallen hollow tree log with moss and a few mushrooms |
| `b1_tree_stump` | wide cut tree stump with visible rings and moss |
| `b1_mushroom_cluster` | cluster of three red-capped mushrooms with white spots |
| `b1_ledge_grass` | one-way jumpable grassy ledge, a low earthen step with grass on top and exposed dirt on the face, 4 metres wide, modular |

### Props
| File | Prompt |
|------|--------|
| `b1_fence_wood_section` | short wooden picket fence section, two posts and three horizontal rails, 2 metres long, modular |
| `b1_fence_wood_post` | single wooden fence post |
| `b1_signpost` | wooden route signpost, single plank sign on a post, blank sign face |
| `b1_lamp_post_village` | short wrought-iron village lamp post with a warm glass lantern |
| `b1_mailbox` | small red metal mailbox on a wooden post |
| `b1_bench_wood` | simple wooden park bench |
| `b1_well_stone` | round stone water well with a wooden roof and bucket on a rope |
| `b1_flower_bed` | rectangular raised flower bed with low wooden border, tulips in rows |
| `b1_barrel_wood` | wooden barrel with iron bands |
| `b1_crate_wood` | wooden shipping crate |
| `b1_item_ball` | red and white Poké Ball, highly readable, perfectly spherical, glossy |
| `b1_route_gate_booth` | small roadside rest-house gatehouse with a tile roof and open doorway on both ends, used to transition between routes |

### Ground textures (Meshy Texture or any PBR generator, seamless, 2K)
`t_grass_meadow`, `t_grass_dark_forest`, `t_dirt_path`, `t_cobblestone_village`, `t_cliff_rock_grey`, `t_sand_beach`, `t_pine_needles_floor`.

## Batch 2 — Oak Grove + Route 102 (forest)
Oak tree x3 (broad canopy, thick trunk), giant ancient hollow oak (landmark), treehouse platform with rope ladder, Pokémon Center (red roof, white walls, glass front, red "P" shape dome), Poké Mart (blue roof, white walls, glass front), log cabin house x2, wooden bridge over stream (6 m), stream rocks, fern clump x2, forest flowers, bird nest, wooden lookout tower, hanging lanterns rope.

## Batch 3 — Petal City + Gym 1 (Grass)
Grass gym as a large Victorian glasshouse conservatory with purple dome, city townhouse x3 (pastel colours, balconies), city fountain with flower sculpture, flower arch trellis, market stall, stone plaza lamp post, paved plaza planter, street café table set, clock tower, city gate arch in stone, cherry blossom tree x2, hedge section modular, topiary ball.

## Batch 4 — Dewford Island, Mossy Harbor, Routes 103–105 (coast)
Fishing hut on stilts, wooden pier sections (modular), moored fishing boat, large ferry boat, lighthouse, palm tree x2, driftwood, beach rocks, tide pool rock, seagull perch post, harbour crane, fish crates, rope coil, buoy, net on rack.

## Later batches (one per region leg, requested when we get there)
Bloomdale farmland · Stonekeep castle and Rock gym · Highwind Pass mountain and cave · Mist Peak snow town · Azure Port harbour city and Water gym · Verdant City treetop and Bug gym · Sunburst Desert ruins · Emberfall volcano and Fire gym · Sapphire City and Electric gym · Crystal Cove beach · Victory Peak league.

## Where to put the files
`assets/ours/meshy/<batch>/<name>.glb` (these are yours to track; they go through Git LFS, which I will set up in the repo).
