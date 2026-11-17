"""Terreno de Roblox aproximado: rellena una cuadrícula de vóxeles de 4 studs con las órdenes FillBlock /
FillBall / FillCylinder (en orden, como Roblox) y saca mallas suaves con marching cubes.
Devuelve (verts, faces, colores) en coordenadas de Roblox para el suelo y para el agua."""
import numpy as np
from skimage.measure import marching_cubes

VOX = 4.0


def _rot(cf):
    return np.array(cf[3:12], dtype=float).reshape(3, 3), np.array(cf[0:3], dtype=float)


def build(fills, palette, bounds=((-620, 620), (-40, 240), (-620, 620))):
    (x0, x1), (y0, y1), (z0, z1) = bounds
    nx, ny, nz = int((x1 - x0) / VOX), int((y1 - y0) / VOX), int((z1 - z0) / VOX)
    solid = np.zeros((nx, ny, nz), np.float32)
    water = np.zeros((nx, ny, nz), np.float32)
    mat = np.zeros((nx, ny, nz), np.int16)
    names = ["Air"]
    xs = x0 + (np.arange(nx) + 0.5) * VOX
    ys = y0 + (np.arange(ny) + 0.5) * VOX
    zs = z0 + (np.arange(nz) + 0.5) * VOX

    def box_idx(lo, hi):
        i0 = max(0, int((lo[0] - x0) // VOX) - 1); i1 = min(nx, int((hi[0] - x0) // VOX) + 2)
        j0 = max(0, int((lo[1] - y0) // VOX) - 1); j1 = min(ny, int((hi[1] - y0) // VOX) + 2)
        k0 = max(0, int((lo[2] - z0) // VOX) - 1); k1 = min(nz, int((hi[2] - z0) // VOX) + 2)
        return i0, i1, j0, j1, k0, k1

    for f in fills:
        kind, m = f["k"], f["mat"]
        if m not in names:
            names.append(m)
        mid = names.index(m)
        if kind == "ball":
            c, r = np.array(f["center"]), f["radius"]
            lo, hi = c - r - 4, c + r + 4
        else:
            R, p = _rot(f["cf"])
            if kind == "cyl":
                half = np.array([f["radius"], f["height"] / 2, f["radius"]])
            else:
                half = np.array(f["size"]) / 2
            ext = np.abs(R) @ half
            lo, hi = p - ext - 4, p + ext + 4
        i0, i1, j0, j1, k0, k1 = box_idx(lo, hi)
        if i0 >= i1 or j0 >= j1 or k0 >= k1:
            continue
        X, Y, Zz = np.meshgrid(xs[i0:i1], ys[j0:j1], zs[k0:k1], indexing="ij")
        if kind == "ball":
            sd = r - np.sqrt((X - c[0]) ** 2 + (Y - c[1]) ** 2 + (Zz - c[2]) ** 2)
        else:
            P = np.stack([X - p[0], Y - p[1], Zz - p[2]], -1) @ R  # a coordenadas locales
            if kind == "cyl":
                sd = np.minimum(f["radius"] - np.sqrt(P[..., 0] ** 2 + P[..., 2] ** 2), f["height"] / 2 - np.abs(P[..., 1]))
            else:
                sd = np.min(half - np.abs(P), axis=-1)
        occ = np.clip(0.5 + sd / VOX, 0, 1)
        sl = (slice(i0, i1), slice(j0, j1), slice(k0, k1))
        if m == "Air":
            solid[sl] = np.minimum(solid[sl], 1 - occ)
            water[sl] = np.minimum(water[sl], 1 - occ)
        elif m == "Water":
            water[sl] = np.maximum(water[sl], occ)
            solid[sl] = np.where(occ >= 0.5, np.minimum(solid[sl], 1 - occ), solid[sl])
        else:
            solid[sl] = np.maximum(solid[sl], occ)
            water[sl] = np.where(occ >= 0.5, 0, water[sl])
            mat[sl] = np.where(occ > 0.25, mid, mat[sl])

    out = {}
    for name, grid in (("suelo", solid), ("agua", water)):
        if grid.max() < 0.5:
            continue
        v, faces, _, _ = marching_cubes(np.pad(grid, 1), 0.5)
        v = v - 1
        world = np.stack([x0 + (v[:, 0] + 0.5) * VOX, y0 + (v[:, 1] + 0.5) * VOX, z0 + (v[:, 2] + 0.5) * VOX], -1)
        cols = None
        if name == "suelo":
            # Material: el del vóxel sólido más cercano por debajo / alrededor.
            ii = np.clip(np.round(v).astype(int), 0, np.array(grid.shape) - 1)
            ids = mat[ii[:, 0], ii[:, 1], ii[:, 2]]
            down = np.clip(ii - [0, 1, 0], 0, None)
            ids = np.where(ids == 0, mat[down[:, 0], down[:, 1], down[:, 2]], ids)
            table = np.array([palette.get(n, (120, 120, 120)) or (120, 120, 120) for n in names], float) / 255
            cols = table[ids]
            # un poco de variación para que no se vea plano
            noise = (np.sin(world[:, 0] * 0.37) * np.cos(world[:, 2] * 0.29) * 0.04)[:, None]
            cols = np.clip(cols * (1 + noise), 0, 1)
        out[name] = (world, faces, cols)
    return out
