# CLAUDE.md — Santuario de Bichos Raros

Juego de Roblox. Contexto para Claude Code. Responde y comenta el código en español.

## Lenguaje y herramientas
- El código es **Luau** (Roblox), nunca Lua 5.x genérico, JavaScript ni Node. No crees servidores Express ni package.json.
- Usa `--!strict` y tipos en los módulos nuevos.
- Rojo sincroniza `src/` con Studio (ver `default.project.json`). `design/` no se sincroniza: es documentación.
- Para probar, usa el servidor MCP de Roblox Studio (playtest, leer la consola). Haz commit después de cada fase verificada.

## Estructura
- `src/server/` → ServerScriptService. Toda la lógica que da monedas, bichos o compras.
- `src/client/` → StarterPlayerScripts. Interfaz e input; solo pide cosas al servidor.
- `src/shared/` → ReplicatedStorage.Shared. Configuración y tipos compartidos.
- `src/shared/Config/*.luau` → **única fuente de verdad del balance** (bichos, mejoras, tienda, eventos). No pongas números mágicos en otros scripts.
- `design/GDD.md` → documento de diseño. Léelo antes de implementar cualquier sistema.

## Reglas (patrones)
- El servidor manda: valida en el servidor tipo, rango y cooldown de todo lo que llegue por RemoteEvent.
- Compras: concede developer products solo en `MarketplaceService.ProcessReceipt`, en el servidor, de forma idempotente.
- Datos: DataStore con `pcall` y reintentos; guarda en `PlayerRemoving`, en `game:BindToClose` y cada 120 s. Cuando crezca, migrar a ProfileStore.
- Interfaz pensada primero para móvil (botones grandes, escala en vez de offset).

## Antipatrones (no hacer)
- Confiar en valores que manda el cliente (monedas, precio, id del bicho capturado).
- `wait()` y `spawn()` obsoletos: usa `task.wait`, `task.spawn`, `task.delay`.
- Copiar nombres, imágenes o mecánicas idénticas de otros juegos (Roblox penaliza los parecidos).
- Modelos gratuitos del Creator Store con scripts sin revisar.
