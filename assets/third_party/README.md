# Third-party assets (NOT tracked in git)

Drop pre-made Pokémon / trainer models, animations and audio here.
These are for **personal use only** and must never be pushed to GitHub.
`.gitignore` excludes everything in this folder except this file and any `MANIFEST.md`.

Expected layout (the loader looks for these paths):

```
assets/third_party/
  pokemon/<dex_number>_<name>/model.glb      e.g. pokemon/025_pikachu/model.glb
  trainers/<id>/model.glb                    e.g. trainers/player_m/model.glb
  audio/bgm/<track>.ogg
  audio/sfx/<name>.ogg
  MANIFEST.md                                # where each file came from
```

Preferred format: **glTF 2.0 (.glb)** with embedded textures and animations
(idle / walk / run / attack / hurt / faint). Godot imports these natively.
Anything missing is replaced by a placeholder capsule at runtime, so the game
always boots even with an empty folder.
