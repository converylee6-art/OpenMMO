# Oriana — 3D Pokémon-style Game: Master Plan

Head designer notes. This file is the source of truth for scope, milestones and how we work.

## 1. Ground rules

- **Engine: Godot 4.x** (GDScript). Free, text-based scenes (git-friendly), native glTF import,
  runs headless in CI so the cloud session can validate every commit. You test builds locally.
- **Small chunks.** Every milestone ends in something you can open and play within minutes.
  Nothing lands on `main` without a play-test checklist in the PR.
- **Pre-made models, personal use only.** Third-party Pokémon/trainer models live in
  `assets/third_party/` (gitignored). The game boots with placeholder capsules if they are missing.
  Conversion pipeline: Models Resource rip → Blender (Trinity/SV importer) → `.glb` with baked clips.
- **Data-driven.** Region, species, moves, trainers, encounters are JSON in `data/`. Code reads data;
  designers edit JSON without touching code.
- **Cloud session reality.** Claude works in a cloud container with no GPU/GUI and limited network.
  It can write code, data, shaders, scenes and run headless Godot checks. It cannot see the game run.
  You are the eyes: run the build, send screenshots/notes, and we iterate.
- **Usage limits.** Sessions may be cut off and later picked up on a smaller model. Every task is
  written so a fresh session can continue from `docs/STATUS.md` alone.

## 2. Repository layout

```
project.godot          Godot project (M1)
scenes/                .tscn scenes (world, battle, UI)
scripts/               GDScript, grouped by system
data/
  region/oriana.json   towns, routes, gyms, ferries (done)
  species/             Pokémon stats, types, learnsets
  moves/               move definitions
  trainers/            trainer rosters and AI profiles
  encounters/          per-route encounter tables
assets/
  ours/                anything we make (tracked)
  third_party/         pre-made models/audio (NOT tracked)
docs/
  PLAN.md              this file
  STATUS.md            what is done / in progress / next (updated every push)
  PIPELINE.md          Blender conversion steps for models (M2)
tools/                 CI scripts, data validators
```

## 3. Milestones (each is one PR, each is playable)

| # | Milestone | You can test | Est. sessions |
|---|-----------|--------------|---------------|
| M0 | Plan + region data + repo scaffolding | read docs | this one |
| M1 | Godot project boots. Third-person player on a grey-box Pine Town, camera, run/walk, collision | walk around | 1 |
| M2 | Model pipeline. Load `.glb` trainer + 3 starters with idle/walk clips; placeholder fallback. `docs/PIPELINE.md` | see real models moving | 1 |
| M3 | Overworld streaming. Pine Town → Route 101 → Oak Grove built from `oriana.json`, chunk loading, day/night | walk two routes | 2 |
| M4 | Roaming wild Pokémon. Species spawn from encounter tables, wander/flee/approach AI, touch = encounter | chase a mon | 2 |
| M5 | Battle core. Turn-based 1v1, type chart, damage formula, status, catch mechanic, XP/level-up | win/lose/catch | 2–3 |
| M6 | Party, bag, Pokédex, save/load, Poké Center / Mart | full loop | 2 |
| M7 | Trainers + Gym 1 (Petal City, Grass). Trainer sight-lines, dialogue, scripted battles, badge | beat Gym 1 | 2 |
| M8 | Vertical slice polish: AAA-pass on Pine→Petal (terrain, foliage, water, post-FX, audio, UI) | demo-quality slice | 3 |
| M9+ | Repeat M3/M7/M8 per region leg: Stonekeep → Highwind → Mist Peak → Azure → Verdant → Desert → Emberfall → Sapphire → Cove → Victory Peak | one gym per PR | ~2 each |

Stretch (after league): ferries, surfing, evolution, breeding, online co-op (the repo is called OpenMMO;
multiplayer is deliberately *not* in the first slice).

## 4. What I need from you (owner)

1. **Local setup**: Godot 4.4+ (standard build), Blender 4.x, git. Clone repo, open `project.godot`.
2. **Models**: 1 player trainer, 3 starters, 2 common route mons as `.glb` with idle/walk/run clips,
   placed under `assets/third_party/` per its README. Tell me which clips exist.
3. **Design calls** (reply with changes or "ok"): starters, gym types/badges in `oriana.json`,
   rival name, art direction reference (Sword/Shield look vs. stylised).
4. **Test feedback** after each milestone: a screenshot or a 3-line note is enough.
5. **GitHub**: keep `main` protected; I push to feature branches and open PRs when you ask.

## 5. How a session runs

1. Read `docs/STATUS.md`, pick the next unchecked task.
2. Implement in a feature branch, run `tools/check.sh` (headless Godot import + data validation).
3. Update `STATUS.md`, commit, push.
4. Write the play-test checklist in the PR/commit message.
