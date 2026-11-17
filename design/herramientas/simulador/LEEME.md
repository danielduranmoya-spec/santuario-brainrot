# Simulador del mapa (sin Studio)

Ejecuta el servidor real del juego (`src/`) en una simulación mínima de Roblox y vuelca lo que construye
(piezas, terreno, luces) para dibujarlo en Blender. Sirvió para comprobar y fotografiar la Isla Santuario.

```bash
# luau: https://github.com/luau-lang/luau/releases (binario "luau" junto a estos archivos)
python3 simular.py ../../.. mapa.json                 # arranca el servidor y vuelca el mapa
pip install bpy scikit-image
FIGURAS=../figuras/out python3 render_mapa.py mapa.json captura isla plazaalta zonas llegada
```

No es Roblox: los colores, la luz y la física no son idénticos, pero la distribución sí. El terreno se
dibuja en vóxeles de 4 studs y se suaviza como el de Roblox.
