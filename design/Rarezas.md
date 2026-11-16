# Rarezas, bichos y bóvedas

Documento generado a partir de `src/shared/Config/Critters.luau` (la única fuente de verdad). Si cambias
los números allí, vuelve a generar este documento o corrígelo a mano.

## Cómo se elige el bicho que aparece

1. Se sortea la **rareza** con los porcentajes de la bóveda (tabla de abajo).
2. Dentro de esa rareza, se reparte **a partes iguales** entre los bichos que ya salen en esa bóveda.
   Los bichos de las bóvedas anteriores siguen activos.

El Común pierde 7 puntos por bóveda de la 1 a la 5 y 12 por bóveda de la 5 a la 9, donde se extingue.
Cada bóveda nueva abre una sola rareza nueva. A partir de la bóveda 5, los bichos atrapados generan x3 por
cada bóveda (x3 en la 5, x9 en la 6, x27 en la 7, x81 en la 8, x243 en la 9). De la bóveda 10 en adelante se
mantienen los porcentajes de la 9.

## Curva de rarezas por bóveda

| Bóveda | Común | Poco común | Raro | Épico | Legendario | Mítico | Secreto |
|---|---|---|---|---|---|---|---|
| 1 · Playa Rara | 76 % | 24 % | — | — | — | — | — |
| 2 · Bosque Ruidoso | 69 % | 26 % | 5 % | — | — | — | — |
| 3 · Volcán Tímido | 62 % | 28 % | 8,5 % | 1,5 % | — | — | — |
| 4 · Nube Pegajosa | 55 % | 30 % | 11 % | 3,5 % | 0,5 % | — | — |
| 5 · Pantano de Cristal | 48 % | 32 % | 13 % | 5 % | 1,3 % | 0,7 % | — |
| 6 · Relojería Abandonada | 36 % | 35,4 % | 16,1 % | 7,4 % | 3 % | 2,1 % | — |
| 7 · Valle de los Titanes | 24 % | 38,4 % | 18,9 % | 9,8 % | 5,1 % | 3,8 % | — |
| 8 · Observatorio Astral | 12 % | 41 % | 21,5 % | 12,2 % | 7,3 % | 5,8 % | 0,2 % |
| 9 · Santuario del Eclipse | — | 43,5 % | 24 % | 14,5 % | 9,5 % | 8 % | 0,5 % |

## Rarezas

| Rareza | Zona verde | Velocidad |
|---|---|---|
| Común | 35 % | x1 |
| Poco común | 25 % | x1,3 |
| Raro | 18 % | x1,7 |
| Épico | 12 % | x2,2 |
| Legendario | 8 % | x2,8 |
| Mítico | 5 % | x3,4 |
| Secreto | 3 % | x4 |

La zona verde crece con la mejora Red (+2 puntos por nivel). Mítico y Secreto exigen mejorarla.

## Reparto exacto por bicho

Porcentaje de aparición de cada bicho en cada bóveda (— = todavía no sale).

| Bicho | Rareza | Monedas/s base | B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Caracol Turbo | Común | 1 | 25,33 % | 23 % | 20,67 % | 18,33 % | 16 % | 12 % | 8 % | 4 % | — |
| Estrella Ninja | Común | 2 | 25,33 % | 23 % | 20,67 % | 18,33 % | 16 % | 12 % | 8 % | 4 % | — |
| Pulpo Cubo | Común | 3 | 25,33 % | 23 % | 20,67 % | 18,33 % | 16 % | 12 % | 8 % | 4 % | — |
| Gaviota Pirata | Poco común | 5 | 24 % | 8,67 % | 9,33 % | 10 % | 10,67 % | 11,8 % | 12,8 % | 13,67 % | 14,5 % |
| Erizo Tambor | Poco común | 15 | — | 8,67 % | 9,33 % | 10 % | 10,67 % | 11,8 % | 12,8 % | 13,67 % | 14,5 % |
| Camaleón Neón | Poco común | 22 | — | 8,67 % | 9,33 % | 10 % | 10,67 % | 11,8 % | 12,8 % | 13,67 % | 14,5 % |
| Búho Despertador | Raro | 40 | — | 2,5 % | 2,83 % | 3,67 % | 4,33 % | 5,37 % | 6,3 % | 7,17 % | 8 % |
| Planta Beatbox | Raro | 65 | — | 2,5 % | 2,83 % | 3,67 % | 4,33 % | 5,37 % | 6,3 % | 7,17 % | 8 % |
| Salamandra Chispa | Raro | 95 | — | — | 2,83 % | 3,67 % | 4,33 % | 5,37 % | 6,3 % | 7,17 % | 8 % |
| Gólem de Obsidiana | Épico | 300 | — | — | 0,75 % | 1,75 % | 2,5 % | 3,7 % | 4,9 % | 6,1 % | 7,25 % |
| Murciélago de Magma | Épico | 450 | — | — | 0,75 % | 1,75 % | 2,5 % | 3,7 % | 4,9 % | 6,1 % | 7,25 % |
| Ajolote Chubasquero | Épico | 120 | solo en la Lluvia de Bichos (12 % de los bichos que aparecen) | | | | | | | | |
| Lobo de Tormenta | Legendario | 2.500 | — | — | — | 0,25 % | 0,43 % | 1 % | 1,7 % | 2,43 % | 3,17 % |
| Dragón de Algodón | Legendario | 3.200 | — | — | — | 0,25 % | 0,43 % | 1 % | 1,7 % | 2,43 % | 3,17 % |
| Garza de Prisma | Legendario | 4.500 | — | — | — | — | 0,43 % | 1 % | 1,7 % | 2,43 % | 3,17 % |
| Leviatán de Espejo | Mítico | 15.000 | — | — | — | — | 0,23 % | 0,7 % | 1,27 % | 1,93 % | 2,67 % |
| Búho de Cuerda | Mítico | 22.000 | — | — | — | — | 0,23 % | 0,7 % | 1,27 % | 1,93 % | 2,67 % |
| Coloso de Bronce | Mítico | 32.000 | — | — | — | — | 0,23 % | 0,7 % | 1,27 % | 1,93 % | 2,67 % |
| Sombra de Péndulo | Secreto | 100.000 | — | — | — | — | — | — | — | 0,07 % | 0,17 % |
| Zorro de Tinta | Secreto | 160.000 | — | — | — | — | — | — | — | 0,07 % | 0,17 % |
| Caballero del Eclipse | Secreto | 250.000 | — | — | — | — | — | — | — | 0,07 % | 0,17 % |

El Lobo de Tormenta aparece además cada 8 minutos en la Playa Rara como evento de servidor.

Los tres Míticos se abren juntos en la bóveda 5 y los tres Secretos en la 8, aunque su zona de origen sea
posterior (Búho de Cuerda: Relojería; Coloso de Bronce: Valle de los Titanes; Caballero del Eclipse: Santuario
del Eclipse). Se cambia en el campo `vault` de cada bicho.

## Modelos

Los modelos están en `src/server/Services/CritterArt.luau`, hechos por código con piezas de Roblox. Para verlos
sin abrir Studio: `python3 design/herramientas/vista_previa_bichos.py` y abre
`design/herramientas/vista_previa_bichos.html` en el navegador. `Config/Art.critterDetail = 1` quita los adornos
pequeños si el juego va lento en móviles modestos.
