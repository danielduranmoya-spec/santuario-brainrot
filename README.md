# Santuario de Bichos Raros

Primer juego de Roblox del proyecto. Atrapa bichos absurdos con una red, llévalos a tu santuario y deja que generen monedas.

- Nuevo en el proyecto: [`docs/ONBOARDING.md`](docs/ONBOARDING.md)
- Diseño: [`design/GDD.md`](design/GDD.md)
- Mapa (Isla Santuario): [`design/Mapa.md`](design/Mapa.md)
- Bichos 3D en estilo figura (y cómo importarlos en Studio): [`design/Bichos3D.md`](design/Bichos3D.md)
- Balance: [`src/shared/Config/`](src/shared/Config/)
- Instrucciones para Claude: [`CLAUDE.md`](CLAUDE.md)

## Puesta en marcha (Windows)

1. **Instala Roblox Studio** y abre una plantilla "Baseplate". Guárdala como `SantuarioDeBichosRaros.rbxl` fuera de Git o en esta carpeta (está ignorada).
2. **Instala Rokit** (gestor de herramientas): https://github.com/rojo-rbx/rokit — en esta carpeta ejecuta `rokit install`. Instala Rojo 7.4.4.
3. **Instala el plugin de Rojo en Studio:** `rojo plugin install`.
4. **Sincroniza:** `rojo serve` en esta carpeta y, en Studio, pestaña Plugins › Rojo › Connect. Lo que edites en `src/` aparece en Studio.
5. **Conecta Claude:** en Studio activa "Enable Studio as MCP server" (Assistant › ajustes) y conecta Claude Code con Quick connect. Abre Claude Code en esta carpeta.
6. **Sube a GitHub:** crea un repositorio vacío y ejecuta `git remote add origin <url>` y `git push -u origin main`.

Si al principio Rojo te resulta demasiado, puedes empezar con Script Sync de Studio y pasar a Rojo más adelante (ver la guía del proyecto).

## Hoja de ruta del MVP (semanas 7 a 12)

- [ ] Semanas 7–8: bucle principal con piezas grises (aparecen bichos, red, santuario, monedas)
- [ ] Semanas 9–10: mejoras, guardado de datos, tienda
- [ ] Semana 11: arte low-poly, sonido, efectos
- [ ] Semana 12: miniaturas (3 versiones), pruebas en móvil, errores

## Pendientes antes del lanzamiento (resueltos en código)

- Legendario de servidor cada 8 min, Lluvia de Bichos de los sábados con bicho exclusivo, robo amable con cebo y valla, códigos de recompensa, oferta de Roblox Premium, analítica del embudo y ritmo de la economía ([`design/Economia.md`](design/Economia.md)).
- Mutaciones de color y tamaño, máquinas de fusión Agrandadora y Titánica, eventos de mutación cada 20 min (también con Robux) y pase Red Titánica ([`design/Mutaciones.md`](design/Mutaciones.md)). El ciclo de día y noche se ha quitado.
- Tres estilos de botón para elegir en [`src/shared/Config/UiStyle.luau`](src/shared/Config/UiStyle.luau): "Caramelo", "Pegatina" y "Neon", para todos o botón a botón.

### Comandos de prueba en Studio (barra de comandos, con el juego en marcha en modo servidor)

```lua
local SS = game:GetService("ServerStorage")
local yo = game.Players:GetPlayers()[1]
SS.DebugDarMonedas:Invoke(yo, 50000)   -- monedas
SS.DebugEventoMutacion:Invoke("GrietaVacio")  -- evento de mutación ya (FiebreOro, LluviaCristales, SobrecargaNeon, AuroraArcoiris, FugaRadioactiva)
SS.DebugLegendario:Invoke()            -- legendario en 15 s
SS.DebugLluvia:Invoke(true)            -- Lluvia de Bichos ya (false = termina, nil = horario normal)
SS.DebugCrearBicho:Invoke(yo, "caracol_turbo", "Vacio", "Enorme")  -- color y tamaño opcionales
```

Para probar el cebo hacen falta dos jugadores: pestaña Prueba > Clientes y servidores > 2 jugadores > Iniciar. Prueba el código BICHOS para conseguir un cebo.
