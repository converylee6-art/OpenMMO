#!/usr/bin/env python3
"""Build Oriana terrain data from the region map image.

Outputs (assets/ours/terrain/):
  heightmap.png   16-bit grey, terrain height (0..1 -> 0..MAX_HEIGHT m)
  colormap.png    RGB biome base colour
  biomemap.png    8-bit biome id (see BIOMES)
  terrain.json    world scale metadata

Usage: python3 tools/mapgen/build_terrain.py <map image> [out dir]
"""
import json, sys, os
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

BIOMES = {0: "sea", 1: "beach", 2: "grass", 3: "forest", 4: "mountain", 5: "snow",
          6: "desert", 7: "volcanic", 8: "town", 9: "cliff"}
W, H = 1024, 560               # pixels
METERS_PER_PX = 4.0            # world is 4096 x 2240 m
MAX_HEIGHT = 420.0             # metres at height 1.0
SEA_LEVEL = 0.06               # fraction of MAX_HEIGHT

def fbm(shape, seed, octaves=6, base=4.0, persistence=0.5):
    rng = np.random.default_rng(seed)
    out = np.zeros(shape, np.float32); amp = 1.0; total = 0.0
    for o in range(octaves):
        res = int(base * 2 ** o)
        small = rng.random((max(2, res * shape[0] // shape[1]), res)).astype(np.float32)
        up = np.array(Image.fromarray(small).resize((shape[1], shape[0]), Image.BICUBIC))
        out += up * amp; total += amp; amp *= persistence
    return out / total

def main():
    src = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else "assets/ours/terrain"
    os.makedirs(out, exist_ok=True)
    im = Image.open(src).convert("RGB").resize((W, H), Image.LANCZOS)
    rgb = np.asarray(im).astype(np.float32) / 255.0
    hsv = np.asarray(im.convert("HSV")).astype(np.float32) / 255.0
    h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]

    # --- classify ---
    yy, xx = np.mgrid[0:H, 0:W]
    fx, fy = xx / W, yy / H
    def region(x0, y0, x1, y1):
        return (fx >= x0) & (fx <= x1) & (fy >= y0) & (fy <= y1)

    sea = (h > 0.52) & (h < 0.70) & (s > 0.35) & (b > 0.45)
    white = (v > 0.80) & (s < 0.18)
    grey = (s < 0.28) & (v > 0.30) & (v < 0.82) & ~white
    yellow = (h > 0.08) & (h < 0.17) & (s > 0.25) & (v > 0.65)
    reddish = ((h < 0.07) | (h > 0.93)) & (s > 0.3) & (v > 0.25) & (v < 0.85)
    dark_green = (h > 0.20) & (h < 0.45) & (v < 0.55)
    sand = (h > 0.09) & (h < 0.19) & (s < 0.45) & (v > 0.70)

    snow = white & region(0.38, 0.0, 0.64, 0.42)
    mountain = grey & (region(0.38, 0.0, 0.64, 0.45) | region(0.84, 0.72, 1.0, 1.0) | region(0.44, 0.55, 0.57, 0.76))
    volcanic = reddish & region(0.82, 0.28, 1.0, 0.64)
    desert = yellow & region(0.68, 0.12, 1.0, 0.78)
    forest = dark_green
    beach = sand & ~desert

    # things on the map that are not terrain: route lines (red), labels (white boxes), UI, town icons
    unknown = (reddish & ~volcanic) | (white & ~snow) | (grey & ~mountain)
    unknown[0:60, 0:300] = True
    unknown[0:90, 940:1024] = True
    unknown[450:560, 0:110] = True

    land = ~sea
    land[0:60, 0:300] = land[60, 0:300][None, :]   # title box: extend row below
    land[0:90, 940:1024] = False
    land[450:560, 0:110] = False
    land = ndi.binary_opening(land, iterations=2)
    land = ndi.binary_closing(land, iterations=6)
    lab, n = ndi.label(land)
    sizes = ndi.sum(land, lab, range(1, n + 1))
    land = np.isin(lab, [i + 1 for i, sz in enumerate(sizes) if sz > 400])
    sea = ~land

    biome = np.full((H, W), 2, np.uint8)
    biome[forest] = 3
    biome[mountain] = 4
    biome[snow] = 5
    biome[desert] = 6
    biome[volcanic] = 7
    biome[beach] = 1
    # fill unknown pixels from nearest known land pixel
    valid = land & ~unknown
    idx = ndi.distance_transform_edt(~valid, return_distances=False, return_indices=True)
    biome = biome[idx[0], idx[1]]
    biome[sea] = 0
    for _ in range(2):
        biome = ndi.generic_filter(biome, lambda a: np.bincount(a.astype(int)).argmax(), size=5, mode="nearest")
    biome[sea] = 0
    coast = ndi.binary_dilation(sea, iterations=3) & land
    biome[coast & ~np.isin(biome, [4, 5, 7])] = 1

    # --- height ---
    dist_sea = ndi.distance_transform_edt(land).astype(np.float32)    # px
    shore = np.clip(dist_sea / 5.0, 0, 1) ** 0.6                     # 0..1 over the first 20 m
    inland = np.clip(dist_sea / 60.0, 0, 1) ** 0.8                   # broad rise toward the interior
    noise_big = fbm((H, W), 1, octaves=5, base=3.0)
    noise_small = fbm((H, W), 2, octaves=7, base=12.0, persistence=0.45)
    base = SEA_LEVEL + 0.012 * shore + 0.07 * inland
    rolling = (0.05 * (noise_big - 0.5) + 0.025 * (noise_small - 0.5)) * shore * (0.3 + 0.7 * inland)
    height = base + rolling
    coastal = inland

    def soft(mask, sigma):
        return ndi.gaussian_filter(mask.astype(np.float32), sigma)

    mtn = soft(np.isin(biome, [4, 5]), 10)
    snw = soft(biome == 5, 14)
    vol = soft(biome == 7, 12)
    dsr = soft(biome == 6, 8)
    frs = soft(biome == 3, 6)
    height += mtn * (0.18 + 0.28 * noise_big + 0.18 * noise_small)
    height += snw * (0.16 + 0.16 * noise_small)
    height += frs * 0.03 * noise_small
    height -= dsr * 0.04 * coastal
    # volcano cone at Emberfall (map 0.92, 0.48) + crater
    cy, cx = int(0.47 * H), int(0.905 * W)
    d = np.hypot(xx - cx, yy - cy)
    cone = np.clip(1 - d / 70.0, 0, 1) ** 1.3
    crater = np.clip(1 - d / 14.0, 0, 1)
    height += cone * 0.5 - crater * 0.22
    # Victory Peak summit (0.92, 0.88)
    cy, cx = int(0.86 * H), int(0.915 * W)
    d = np.hypot(xx - cx, yy - cy)
    height += np.clip(1 - d / 60.0, 0, 1) ** 1.6 * 0.45
    # Highwind Pass / Mist Peak ridge boost (0.50, 0.11..0.33)
    cy, cx = int(0.22 * H), int(0.50 * W)
    d = np.hypot((xx - cx) / 1.0, (yy - cy) / 1.8)
    height += np.clip(1 - d / 90.0, 0, 1) ** 1.2 * 0.18 * (0.6 + 0.8 * noise_small)

    # sea floor
    sea_depth = ndi.distance_transform_edt(sea).astype(np.float32)
    height = np.where(sea, SEA_LEVEL - 0.01 - np.clip(sea_depth / 60.0, 0, 1) * 0.05, height)
    # keep towns reasonably flat: lower frequency smoothing near towns
    towns = [(0.08,0.20),(0.26,0.21),(0.18,0.54),(0.12,0.74),(0.29,0.82),(0.37,0.54),(0.50,0.66),
             (0.50,0.11),(0.63,0.26),(0.78,0.09),(0.92,0.48),(0.74,0.62),(0.69,0.92)]
    smooth = ndi.gaussian_filter(height, 6)
    flat = np.zeros((H, W), np.float32)
    for tx, ty in towns:
        d = np.hypot(xx - tx * W, yy - ty * H)
        flat = np.maximum(flat, np.clip(1 - d / 22.0, 0, 1))
        biome[(d < 10) & land] = 8
    height = height * (1 - flat) + smooth * flat
    height = ndi.gaussian_filter(height, 1.2)
    min_land = SEA_LEVEL + 0.002 + 0.010 * shore
    height = np.where(land, np.maximum(height, min_land), height)
    height = np.clip(height, 0, 1)

    # slope -> cliff biome
    gy, gx = np.gradient(height * MAX_HEIGHT, METERS_PER_PX)
    slope = np.hypot(gx, gy)
    biome[(slope > 1.4) & land & ~np.isin(biome, [5, 7])] = 9

    # --- colour map ---
    pal = {0: (0.10, 0.30, 0.55), 1: (0.86, 0.80, 0.58), 2: (0.40, 0.60, 0.28), 3: (0.22, 0.42, 0.20),
           4: (0.48, 0.46, 0.42), 5: (0.92, 0.94, 0.97), 6: (0.86, 0.72, 0.42), 7: (0.30, 0.22, 0.20),
           8: (0.52, 0.64, 0.36), 9: (0.42, 0.38, 0.34)}
    col = np.zeros((H, W, 3), np.float32)
    for k, c in pal.items():
        col[biome == k] = c
    col = ndi.gaussian_filter(col, (1.5, 1.5, 0))
    col *= (0.9 + 0.2 * noise_small[..., None])

    h16 = (height * 65535).astype(np.uint16)
    Image.fromarray(h16).save(f"{out}/heightmap.png")
    hrg = np.zeros((H, W, 3), np.uint8); hrg[..., 0] = h16 >> 8; hrg[..., 1] = h16 & 255
    Image.fromarray(hrg).save(f"{out}/heightmap_rg.png")
    Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8)).save(f"{out}/colormap.png")
    Image.fromarray(biome).save(f"{out}/biomemap.png")
    json.dump({"width_px": W, "height_px": H, "meters_per_px": METERS_PER_PX, "max_height_m": MAX_HEIGHT,
               "sea_level_m": SEA_LEVEL * MAX_HEIGHT, "biomes": BIOMES}, open(f"{out}/terrain.json", "w"), indent=2)
    counts = {BIOMES[k]: int((biome == k).sum()) for k in BIOMES}
    print("biome px:", counts)
    print("height m: min %.1f max %.1f" % (height.min() * MAX_HEIGHT, height.max() * MAX_HEIGHT))

if __name__ == "__main__":
    main()
