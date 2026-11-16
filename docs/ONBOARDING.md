# Santuario de Bichos Raros: guía de incorporación

Estado a 16/11/2026. Para quien recibe el proyecto sin conocerlo. Si algo de aquí choca con `src/shared/Config/`, manda el Config.

## Qué es el juego

**Santuario de Bichos Raros** es un juego de Roblox de coleccionar e inactivo (*idle*): atrapas bichos absurdos con una red, los colocas en tu santuario y generan monedas por segundo. Está pensado primero para móvil y para el grupo de Roblox DAJULU GAMES. El código está en Luau y vive en este repositorio.

**Bucle principal (30 segundos):**

1. Aparece un bicho en el campo de tu bóveda, cada pocos segundos.
2. Corres hacia él y pulsas **Atrapar**: sale una barra con una zona verde; si paras dentro, lo capturas. Cuanto más raro, más pequeña la zona y más rápido el cursor.
3. Lo llevas a tu santuario y lo pones en un pedestal: empieza a generar monedas por segundo.
4. Gastas monedas en mejoras (Red, Botas, Santuario, Imán) y en abrir la siguiente bóveda, donde salen bichos más raros.

Encima de ese bucle hay capas de retención: mutaciones de color y tamaño, máquinas de fusión, eventos de servidor, recompensa diaria, índice de bichos, rankings y una tienda con Robux. El diseño original está en `design/GDD.md`; parte de él (zonas, 8 bichos) quedó superado por el catálogo v3 que se describe abajo.

## Montar el entorno

El código se edita en archivos `.luau` del repositorio y **Rojo** lo sincroniza en vivo con Roblox Studio. El mapa no está en Git: casi todo el mundo (bóvedas, santuarios, máquinas) lo crea el código al arrancar.

1. Instala **Roblox Studio** y pide a Daniel acceso al grupo **DAJULU GAMES** (permiso de edición en la experiencia).
2. Instala **Git** y clona el repo: `git clone https://github.com/danielduranmoya-spec/santuario-brainrot`.
3. Instala **Rokit** ([rojo-rbx/rokit](https://github.com/rojo-rbx/rokit)) y, dentro de la carpeta del repo, ejecuta `rokit install`. Instala **Rojo 7.4.4** (fijado en `rokit.toml`).
4. Instala el plugin de Rojo en Studio: `rojo plugin install`.
5. Abre en Studio una plantilla *Baseplate* (o el lugar del grupo) y guárdalo como `SantuarioDeBichosRaros.rbxl` (los `.rbxl` están en `.gitignore`).
6. En la carpeta del repo ejecuta `rojo serve`. En Studio: **Plugins > Rojo > Connect**. Lo que guardes en `src/` aparece en Studio al instante.
7. Pulsa **Play**. En la consola (Output) debe salir `Santuario de Bichos Raros: servidor listo`.
8. Opcional: activa en Studio *Enable Studio as MCP server* para que Claude Code pueda hacer playtests y leer la consola.

**Mapa de Rojo** (`default.project.json`):

| Carpeta del repo | Destino en Studio |
| --- | --- |
| `src/server/` | ServerScriptService.Server |
| `src/client/` | StarterPlayer.StarterPlayerScripts.Client |
| `src/shared/` | ReplicatedStorage.Shared |
| `design/` | No se sincroniza: documentación |

**Comandos de prueba** (barra de comandos de Studio, con el juego en marcha y vista de servidor): `ServerStorage.DebugDarMonedas:Invoke(yo, 50000)`, `DebugEventoMutacion:Invoke("GrietaVacio")`, `DebugLegendario:Invoke()`, `DebugLluvia:Invoke(true)`, `DebugCrearBicho:Invoke(yo, "caracol_turbo", "Vacio", "Enorme")` y `DebugDarBichos` para probar la fusión; `yo = game.Players:GetPlayers()[1]`. El cebo necesita 2 jugadores (Prueba > Clientes y servidores). El código `BICHOS` da un cebo. Más detalle en el `README.md`.

**Sin Studio** se pueden revisar cosas: `python3 design/simulacion_economia.py` simula la economía leyendo los Config, y `python3 design/herramientas/vista_previa_bichos.py` (requiere `pip install lupa`) dibuja los 21 modelos en una página HTML con three.js.

## Estructura del repositorio

Unas 10.400 líneas de Luau en 45 archivos. La regla de oro: **el servidor manda**. Todo lo que da monedas, bichos o compras vive en `src/server/`; el cliente solo dibuja y pide cosas por RemoteEvent. **Todos los números de balance** están en `src/shared/Config/`, nunca en otros scripts.

```
santuario-brainrot/
├─ CLAUDE.md            reglas del proyecto (léelas primero)
├─ README.md            puesta en marcha y comandos de prueba
├─ default.project.json mapa de Rojo
├─ rokit.toml           versión de Rojo
├─ docs/ONBOARDING.md   este documento
├─ design/              documentación de diseño (no se sincroniza)
│  ├─ GDD.md, Rarezas.md, Mutaciones.md, Economia.md, Botones.md, Rendimiento.md
│  ├─ simulacion_economia.py
│  └─ herramientas/ (vista previa de modelos), bichos/, miniaturas/
└─ src/
   ├─ server/  Main.server.luau + Services/   (ServerScriptService)
   ├─ client/  Main.client.luau + módulos       (StarterPlayerScripts)
   └─ shared/  Config/ + matemáticas comunes   (ReplicatedStorage.Shared)
```

**Arranque.** `src/server/Main.server.luau` hace `require` de cada servicio y llama a `Start()` en orden. `Guard` va el primero y `Data` el último: al cargar a cada jugador, `Data` avisa a los demás servicios con `Data.OnLoaded`, en el orden en que se registraron. Si añades un servicio, regístralo ahí.

**Comunicación.** `Services/Remotes.luau` crea todos los RemoteEvents en `ReplicatedStorage.Remotes`. Del servidor al cliente: `StartMinigame`, `CatchResult`, `Notify`, `Effect`, `Announce`, `OpenMachine`, `RareSpawn`. Del cliente al servidor: `AttemptCatch`, `ReleaseCarried`, `BuyUpgrade`, `PromptPurchase`, `RedeemCode`, `BuyFence`, `Fuse`. Cada uno se conecta con `Guard.Connect`, que limita peticiones por segundo; después el servicio valida tipo, rango y estado.

### Servicios del servidor (`src/server/Services/`)

| Servicio | Qué hace |
| --- | --- |
| `Data` | Perfil del jugador en DataStore: carga, guarda cada 120 s, al salir y en BindToClose, con reintentos y reserva de sesión. Sin DataStore (Studio sin publicar) el juego funciona sin guardar. |
| `Guard` | Antitrampas: límite de peticiones, comprobación de distancia, tolerancia por ping y bloqueo de teletransportes. |
| `Economy` | Monedas. El valor real está en el perfil; `leaderstats.Monedas` es solo una copia visible. |
| `CritterSpawner` | Hace aparecer bichos en cada bóveda (rareza, color, tamaño), los pasea y resuelve la captura con el minijuego. El más grande (755 líneas). |
| `CritterArt` / `CritterVisual` | Modelos de los 21 bichos hechos por código con piezas, y su aspecto (aro de rareza, luz, chispas, etiqueta, mutación). |
| `Plots` | Santuarios: parcela de cada jugador en la plaza, pedestales, cofre de monedas. |
| `Vaults` | Campo de bóvedas sin fin, puertas y pago para abrir cada una. |
| `Boundary` | Muros invisibles y techo para que nadie salga del campo. |
| `WorldArt` | Escenario generado por código: plaza, avenida, decorado de cada bóveda. |
| `Upgrades` | Compra de mejoras con monedas (Red, Botas, Santuario, Imán). |
| `Fusion` | Máquinas Agrandadora y Titánica. |
| `MutationEvents` | Evento de mutación cada 20 min (o invocado con Robux). |
| `LiveEvents` | Legendario de servidor cada 8 min y Lluvia de Bichos de los sábados. |
| `Bait` | Robo amable con cebo y valla. |
| `Purchases` | Game passes y developer products; concede productos solo en `ProcessReceipt`, de forma idempotente. |
| `DailyReward` | Racha de 7 días. |
| `Codes` | Códigos de recompensa. |
| `Analytics` | Embudo de los primeros minutos con AnalyticsService. |
| `Leaderboards`, `EventStands`, `Bestiary` | Nuevos en el PR 7 (aún sin fusionar): rankings, stands de eventos e índice. |

### Cliente (`src/client/`)

| Módulo | Qué hace |
| --- | --- |
| `Main.client` | Interfaz principal: monedas, barra de captura, botón ¡AHORA!/SOLTAR, pistas, objetivos del tutorial. |
| `Menus` | Menús de MEJORAS, TIENDA y CÓDIGOS (y ÍNDICE con el PR 7). |
| `LiveHud` | Avisos globales y cuentas atrás de eventos, cebo y valla. |
| `Effects`, `Ambience` | Sonido, partículas, niebla y color según la bóveda o el evento. |
| `CritterAnimator` | Animaciones locales de los bichos (balanceo, parpadeo). |
| `VaultDoors` | Puertas sólidas solo para quien no ha abierto la bóveda. |
| `Performance` | Modo de bajo detalle en móvil. |
| `ButtonStyle` | Aplica el estilo de botón elegido en `Config/UiStyle`. |

### Compartido (`src/shared/`)

`CatchBar`, `MutationMath`, `UpgradeMath` y `VaultMath` contienen cálculos que usan servidor y cliente, para que los dos vean lo mismo. `Format` formatea números (`1.234.567`).

| Config | Qué se ajusta ahí |
| --- | --- |
| `Critters` | Rarezas (zona verde, color), curva de rarezas por bóveda, lista de los 21 bichos. |
| `Progression` | Las 9 bóvedas y sus precios, bóvedas sin fin, mejoras, huecos iniciales. |
| `Gameplay` | Campo, aparición, minijuego, santuarios, tutorial, menús, seguridad, velocidades. |
| `Mutations` | Colores, tamaños, máquinas de fusión, eventos de mutación, aviso de mutación rara. |
| `Events` | Legendario de servidor, Lluvia de Bichos, cebo, recompensa diaria. |
| `Shop` | Pases y productos con sus IDs (ahora todos a 0), ventaja Premium. |
| `Codes` | Códigos: BICHOS, LANZAMIENTO (caduca 31/01/2027), LLUVIA. |
| `Analytics` | Pasos del embudo. |
| `Art`, `Audio`, `UiStyle` | Aspecto visual, rendimiento, sonidos y estilo de botones. |
| `Index` | Premios del índice (llega con el PR 7). |

## Sistemas del juego

Cada sistema tiene su servicio y su archivo de Config. Las tablas completas de probabilidades están en `design/Rarezas.md` y `design/Mutaciones.md`; aquí va lo que hay que saber para orientarse.

### Bichos y rarezas (`Config/Critters`)

21 bichos, 3 por rareza, en 7 rarezas. Cuanto más rara, más estrecha la zona verde del minijuego y más rápido el cursor. Cada bicho tiene `id`, nombre, rareza, monedas por segundo base y la primera bóveda donde sale (`vault`). El Ajolote Chubasquero es exclusivo de la Lluvia de Bichos (`eventOnly`).

| Rareza | Zona verde | Bichos | Monedas/s base |
| --- | --- | --- | --- |
| Común | 35 % | Caracol Turbo, Estrella Ninja, Pulpo Cubo | 1 a 3 |
| Poco común | 25 % | Gaviota Pirata, Erizo Tambor, Camaleón Neón | 5 a 22 |
| Raro | 18 % | Búho Despertador, Planta Beatbox, Salamandra Chispa | 40 a 95 |
| Épico | 12 % | Gólem de Obsidiana, Murciélago de Magma, Ajolote Chubasquero (evento) | 120 a 450 |
| Legendario | 8 % | Lobo de Tormenta, Dragón de Algodón, Garza de Prisma | 2.500 a 4.500 |
| Mítico | 5 % | Leviatán de Espejo, Búho de Cuerda, Coloso de Bronce | 15.000 a 32.000 |
| Secreto | 3 % | Sombra de Péndulo, Zorro de Tinta, Caballero del Eclipse | 100.000 a 250.000 |

Cómo se elige un bicho: primero se sortea la rareza con los porcentajes de la bóveda (`Critters.VaultChances`); después, a partes iguales entre los bichos de esa rareza que ya salen en esa bóveda. La mejora Red suma 2 puntos de zona verde por nivel. Los modelos son piezas de Roblox creadas por código en `CritterArt.luau`, no mallas importadas.

### Bóvedas (`Config/Progression.Vaults`, `Services/Vaults`)

El mapa es una plaza con los 6 santuarios y, delante, un campo largo dividido en bóvedas. Para entrar en una hay que haber abierto la anterior y pagar una vez. Cada bóveda nueva abre una rareza nueva.

| # | Bóveda | Precio | Rareza que estrena |
| --- | --- | --- | --- |
| 1 | Playa Rara | gratis | Común y Poco común |
| 2 | Bosque Ruidoso | 1.000 | Raro |
| 3 | Volcán Tímido | 18.000 | Épico |
| 4 | Nube Pegajosa | 300.000 | Legendario |
| 5 | Pantano de Cristal | 1,2 M | Mítico |
| 6 | Relojería Abandonada | 4,8 M | |
| 7 | Valle de los Titanes | 19 M | |
| 8 | Observatorio Astral | 77 M | Secreto |
| 9 | Santuario del Eclipse | 310 M | (desaparece el Común) |

Desde la bóveda 5, cada una cuesta x4 la anterior y lo que se atrapa en ella genera x3 más (x3 en la 5, x243 en la 9). A partir de la 10 las bóvedas son infinitas y repiten temática (Playa Rara II…), con tope de seguridad en 60.

### Santuario y mejoras (`Services/Plots`, `Services/Upgrades`)

Cada jugador recibe una parcela (hasta 6 por servidor) con pedestales; empieza con 3 huecos. Los bichos colocados llenan un cofre de monedas que se cobra acercándose. Si el santuario está lleno y traes un bicho mejor, sustituye al más flojo, que se vende por 30 s de lo que generaba.

Mejoras (coste = base × crecimiento^(nivel−1)): **Red** (zona verde, 10 niveles), **Botas** (velocidad, 10), **Santuario** (+1 hueco, 12) e **Imán** (radio de cobro, 5).

### Mutaciones (`Config/Mutations`)

Cada bicho salvaje sortea un **color** y un **tamaño** por separado, y los multiplicadores se multiplican. Colores: Normal x1, Oro x2, Diamante x3, Neón x4, Arcoíris x5, Radioactivo x6, Espectral x7, Vacío x8 (0,01 %). Tamaños: Normal x1, Grande x3 (3 %), Enorme x7 (0,5 %). Ejemplo: Radioactivo Enorme = x42. Cuando aparece una mutación rara, sale un aviso (`RareSpawn`).

### Máquinas de fusión (`Services/Fusion`)

En la plaza, a los lados de la avenida. **Agrandadora:** 5 bichos iguales Normales + monedas = 1 Grande. **Titánica:** 4 Grandes iguales + monedas = 1 Enorme. El resultado hereda al azar el color de uno de los que entran y el multiplicador de bóveda más bajo. El coste escala con lo que producen los bichos que entran.

### Eventos (`Services/LiveEvents`, `Services/MutationEvents`, `Config/Events`)

- **Legendario de servidor:** cada 8 min (el primero a los 4) aparece un Lobo de Tormenta en la bóveda 1 con aviso de 15 s. El primero que lo atrapa se lo queda.
- **Lluvia de Bichos:** sábados a las 18:00 de Madrid, 30 min, bichos x3 y 12 % de que salga el Ajolote Chubasquero. La hora está en UTC (`hourUTC = 17`): en verano hay que cambiarla a 16.
- **Eventos de mutación:** cada 20 min, 5 min de duración, suben un color (Fiebre del Oro, Lluvia de Cristales, Sobrecarga Neón, Aurora Arcoíris, Fuga Radioactiva, Grieta del Vacío). También se pueden invocar con Robux.
- **Stands de eventos** (PR 7): tres puestos en la plaza con encargado, cartel con cuenta atrás y un aviso «Hablar» que explica cada evento.

### Social: cebo y valla (`Services/Bait`)

Pones un cebo en la entrada del santuario de otro jugador. Si en 20 s no lo espanta o no tiene valla (1.000 monedas, 10 min), uno de sus bichos se va contigo. Nunca se roban Legendarios, Míticos ni Secretos, nadie pierde más de uno cada 10 min y no se puede robar a quien tiene menos de 3.

### Rankings e índice (PR 7, sin fusionar)

- **Rankings físicos** (`Services/Leaderboards`): tres carteles detrás de los santuarios con el top 10 global de Robux gastados, monedas actuales y capturas totales, con OrderedDataStore cada 60 s. En Studio sin publicar solo muestran a los jugadores del servidor.
- **Índice** (`Services/Bestiary`, `client/Bestiary`, `Config/Index`): botón ÍNDICE; los bichos no descubiertos se ven como silueta negra con «???». Premios únicos por completar cada rareza (de 500 monedas a 500 M) y por llegar a 10, 25, 50, 100, 250, 500 y 1.000 capturas.

### Retención y primeros minutos

- **Recompensa diaria** (`Services/DailyReward`): racha de 7 días, de 100 a 2.500 monedas, y el día 7 un bicho Raro. Si fallas un día, vuelve al día 1.
- **Códigos** (`Config/Codes`): BICHOS, LANZAMIENTO (caduca el 31/01/2027) y LLUVIA. Uno por jugador.
- **Tutorial:** panel de objetivos (tener 3 bichos, abrir la bóveda 2). MEJORAS sale con el primer bicho; TIENDA y CÓDIGOS, tras el primer minuto.
- **Analítica** (`Config/Analytics`): embudo `entra`, `primer_bicho`, `primera_mejora`, `zona_2`, `primera_compra`, visible en Creator Hub > Analíticas > Embudos.

### Tienda y productos de pago (`Config/Shop`, `Services/Purchases`)

| Producto | Tipo | Precio |
| --- | --- | --- |
| x2 Monedas | Pase | 99 R$ |
| Red Dorada (zona verde máxima) | Pase | 149 R$ |
| VIP (+1 hueco, nombre especial) | Pase | 299 R$ |
| Red Titánica (10 % de que el bicho crezca un tamaño) | Pase | 399 R$ |
| Pack de inicio (5 cebos + bicho Raro, una vez) | Producto | 49 R$ |
| Cebo | Producto | 25 R$ |
| Suerte x2, 15 min | Producto | 49 R$ |
| Invocar evento de mutación (6 productos) | Producto | 49 a 399 R$ |

Todos los IDs están a **0**: hay que crearlos en Creator Hub > Monetización tras publicar y copiarlos en `Config/Shop.luau`. Mientras sean 0, la tienda avisa de que no están configurados. Los suscriptores Premium ganan +10 % y la oferta sale al abrir la bóveda 2. Los productos se conceden solo en `ProcessReceipt` y el perfil recuerda las últimas 50 compras para no darlas dos veces.

### Guardado (`Services/Data`)

DataStore `Jugadores_v1` (**cambiar el nombre borra el progreso de todos**). Guarda al salir, al cerrar el servidor y cada 120 s, con hasta 5 reintentos y una reserva de sesión para que dos servidores no se pisen. El perfil guarda monedas, bichos, mejoras, bóveda máxima, cebos, suerte, racha diaria, compras, valla, códigos canjeados y pasos del embudo; el PR 7 añade `robuxSpent` y el índice. Para probar el guardado en Studio hay que publicar y activar *Enable Studio Access to API Services*. La migración a ProfileStore está prevista para cuando el juego crezca.

## Flujo de trabajo

**GitHub es la fuente de verdad del código; Studio, la del mapa.** No edites scripts directamente en Studio: con Rojo conectado, el siguiente guardado desde `src/` los pisa.

1. Parte siempre de `main` actualizada: `git pull`.
2. Crea una rama por tarea: `git checkout -b nombre-corto`.
3. Trabaja con `rojo serve` conectado y prueba con Play en Studio.
4. Haz commit al terminar cada fase probada y sube la rama.
5. Abre un Pull Request contra `main`. Daniel lo revisa y lo fusiona. No hay CI todavía: la prueba es un playtest en Studio.

**Team Create y el grupo DAJULU GAMES.** El juego se va a publicar bajo el grupo de Roblox DAJULU GAMES, no en la cuenta de Daniel. Team Create sirve para editar a la vez lo que no está en Git (el lugar, ajustes de la experiencia, assets subidos). Como casi todo el mundo lo genera el código, los conflictos de mapa deberían ser raros.

**Reglas del proyecto** (`CLAUDE.md`):

- Código en **Luau** con `--!strict` y tipos en módulos nuevos. Comentarios en español.
- **Nunca confíes en el cliente:** valida en el servidor tipo, rango y cooldown de todo lo que llega por RemoteEvent. El cliente nunca manda monedas, precios ni el id del bicho capturado.
- **Nada de números mágicos** fuera de `src/shared/Config/`.
- Developer products solo en `ProcessReceipt`, de forma idempotente.
- `task.wait`, `task.spawn`, `task.delay`; nunca `wait()` ni `spawn()`.
- Interfaz pensada primero para móvil: botones grandes y tamaños en escala.
- No copies nombres, imágenes ni mecánicas idénticas de otros juegos; no uses modelos gratuitos del Creator Store con scripts sin revisar.

**Trabajar con Claude Code.** Gran parte del código lo ha escrito Claude Code siguiendo `CLAUDE.md`. Para que pueda hacer playtests, activa en Studio *Enable Studio as MCP server* y abre Claude Code en la carpeta del repo. Para revisar estilo sin Studio se puede usar `selene` (linter de Luau).

## Estado actual (16/11/2026)

El juego está completo en funciones y sin publicar. `main` incluye todo hasta el PR 6; el PR 7 está abierto y pendiente de probar en Studio. Todo se ha desarrollado entre el 15 y el 16 de noviembre de 2026.

| PR | Qué trae | Estado |
| --- | --- | --- |
| [7](https://github.com/danielduranmoya-spec/santuario-brainrot/pull/7) | Rankings físicos, stands de eventos, índice de bichos; `CritterArt` pasa a `shared` | **Abierto**, sin probar en Studio |
| [6](https://github.com/danielduranmoya-spec/santuario-brainrot/pull/6) | Antitrampas (`Guard`), coste de fusión, rendimiento en móvil, objetivos, aviso de mutación rara | Fusionado el 16/11, tras dos playtests |
| [5](https://github.com/danielduranmoya-spec/santuario-brainrot/pull/5) | Pendientes del lanzamiento, catálogo v3 (21 bichos, 9 bóvedas), mutaciones, fusión; fuera el día y la noche | Fusionado el 16/11 |
| 4 | Modelos y escenarios de más calidad, campo de bóvedas, nueva interfaz | Fusionado el 15/11 |
| 3 | Arte low-poly, sonido y efectos | Fusionado el 15/11 |
| 2 | Guardado, mejoras, zonas, tienda, recompensa diaria | Fusionado el 15/11 |
| 1 | Bucle principal con piezas grises | Fusionado el 15/11 |

**Decisiones pendientes de Daniel:**

- [ ] **Ritmo de la bóveda 4.** Con el catálogo v3, la bóveda 4 (300.000) se abre hacia el minuto 27 y la 5 hacia el 44, más lento que el objetivo. Propuesta: bajar la 4 a unos 150.000 (`design/Economia.md`).
- [ ] **Fusión que pierde dinero.** Fusionar 5 Normales en 1 Grande (x3) baja los ingresos si los 5 estaban en pedestales. Propuesta: Grande x5 y Enorme x20.
- [ ] **PR 7, interpretaciones sin confirmar:** «criaturas coleccionadas» del ranking se ha leído como capturas totales, no bichos distintos; las cantidades de los premios del índice y los nombres y posiciones de los stands son una propuesta.
- [ ] **Pesos de los eventos de mutación** (26 %, 23 %, 20 %, 15 %, 11 %, 5 %): son una propuesta.
- [ ] **Aspecto y nombre:** elegir estilo de botón (Caramelo, Pegatina o Neón), miniatura, icono y nombre final entre las tres opciones de `design/miniaturas/disenos.html`.

**Sin hacer o sin probar:**

- No se ha publicado: los IDs de la tienda están a 0 y el guardado y los rankings globales solo funcionan en un juego publicado.
- No se ha probado en un móvil real (solo el emulador de Studio, y el modo móvil sin probar).
- La hora de la Lluvia de Bichos hay que cambiarla a mano con el horario de verano.
- `design/GDD.md` describe todavía las 4 zonas y 8 bichos originales en su primera parte: para los números actuales manda `Config/`.

## Siguientes pasos

Para el primer día, en este orden:

1. Lee `CLAUDE.md`, este documento y `design/Rarezas.md`.
2. Monta el entorno, conecta Rojo y juega 15 minutos: atrapa, coloca, mejora y abre la bóveda 2. Usa los comandos de prueba para ver mutaciones y eventos.
3. Recorre el código de una captura de punta a punta: `CritterSpawner` (aparición y `AttemptCatch`) → `CatchBar` → `Plots` (depósito y monedas) → `Data`.
4. Prueba el PR 7 en Studio (índice, rankings y stands) y deja tus comentarios en GitHub.

Después, el camino al lanzamiento:

1. Daniel cierra las decisiones pendientes de balance y aspecto.
2. Publicar la experiencia en el grupo DAJULU GAMES y dar acceso de edición al equipo.
3. Crear pases y productos en Creator Hub y poner los IDs en `Config/Shop.luau`.
4. Activar el acceso a API en Studio y probar guardado y rankings globales con datos reales.
5. Probar en móviles reales (rendimiento y botones).
6. Lanzamiento silencioso y seguir el embudo: D1 ≥ 20 %, sesión media ≥ 12 min, conversión ≥ 1 %.

Pendiente técnico para más adelante: migrar `Data` a ProfileStore, añadir CI con `selene` y actualizar el principio de `design/GDD.md` al catálogo v3.
