# Rendimiento en móvil

## Qué se ha medido
Las piezas de cada bicho se cuentan con `design/herramientas/vista_previa_bichos.py` (lee
`CritterArt.luau`), sin abrir Studio.

| | Media | Mínimo | Máximo |
|---|---|---|---|
| Piezas por bicho | 49 | 32 (Gaviota Pirata) | 67 (Dragón de Algodón) |
| De ellas, adornos pequeños (`fine`) | 12 | | |
| Piezas animadas (alas, colas, párpados...) | 11 | 2 | 30 |

A esto se suman, en cada bicho, la raíz, el aro de rareza, la etiqueta y, según la rareza y la
mutación, una o dos luces y uno o dos emisores de partículas (chispas de rareza desde Raro, y
partículas de mutación desde Oro).

**Servidor lleno (estimado):** 6 jugadores y la bóveda más lejana abierta es la 5, así que hay
bichos en 6 bóvedas (6 por bóveda) y unos 10 en cada santuario, en total unos 96 bichos y
**4.800 piezas** solo en bichos.

## Qué se ha cambiado
| Problema | Cambio | Efecto |
|---|---|---|
| El nivel de detalle era el mismo en todos los dispositivos (`Art.critterDetail` en el servidor) | `client/Performance`: los móviles y tablets quitan de su pantalla los adornos pequeños (atributo `Fine`) | -25 % de piezas en el móvil (de 49 a 37 por bicho) y el ordenador lo sigue viendo todo |
| La animación movía las ~50 piezas de cada bicho cercano a 30 fps (unas 22.000 escrituras por segundo con 15 bichos cerca) | En bajo detalle solo se mueven las piezas animadas, a 20 fps y a 45 studs | Unas 3.300 escrituras por segundo con 15 bichos cerca (-85 %) |
| Partículas y luces siempre encendidas, también a 300 studs | Se apagan a más de 55 studs (móvil) o 110 (ordenador), y en el móvil salen la mitad | Menos dibujado de transparencias, que es lo que más cuesta en un móvil |
| Cada captura volvía a crear todos los bichos del santuario (y los mandaba por la red a todos) | `Plots.render` solo rehace los pedestales que cambian | Con 10 bichos en el santuario, cada captura crea ~50 piezas en vez de ~500 |

Todos los números están en `Config/Art.performance`.

## Qué falta medir en un móvil de verdad
En Studio: **Test > Device** (por ejemplo, iPhone SE) y **View > Stats** / **MicroProfiler**
(Ctrl+F6). Mira el FPS en la plaza con 6 santuarios llenos y en la bóveda 5. Si baja de 30:
1. Pon `Art.critterDetail = 1`, que quita los adornos también en el servidor.
2. Baja `Gameplay.Field.crittersPerVault` de 6 a 5.
3. Activa `Workspace.StreamingEnabled` en el place. Los santuarios, muros y puertas ya están
   marcados como persistentes para que funcione bien.
