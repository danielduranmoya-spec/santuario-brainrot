# Ritmo de la economía

Objetivo del feedback: abrir la **bóveda 2 hacia el minuto 5** y la **bóveda 3 dentro de la primera sesión** (la sesión media objetivo es de 12 min, ver GDD).

## Qué fallaba
- Con 2.500 / 40.000 / 600.000 monedas, un jugador medio abría la bóveda 2 hacia el **minuto 11** y la 3 hacia el **minuto 35** (solo 6 de cada 10 llegaban en 40 min).
- Con el santuario lleno ya no servía de nada atrapar bichos mejores: no se podían colocar. La única salida era la mejora Santuario, cada vez más cara.

## Qué ha cambiado
| Ajuste | Antes | Ahora | Dónde |
|---|---|---|---|
| Bóveda 2 | 2.500 | 1.000 | `Config/Progression.luau` |
| Bóveda 3 | 40.000 | 18.000 | `Config/Progression.luau` |
| Bóveda 4 | 600.000 | 300.000 | `Config/Progression.luau` |
| Santuario lleno | no cabe | el bicho nuevo sustituye al más flojo si genera más, y el flojo se vende por 30 s de lo que generaba | `Config/Gameplay.luau` (`autoReplaceWeakest`, `sellValueSeconds`) |

Las bóvedas sin fin (5ª en adelante) siguen igual: cada una cuesta x4 y sus bichos valen x3. Eso hace que, a partir de la 6ª (minuto 25-30), cada bóveda cueste algo más de esfuerzo que la anterior, que es lo que da recorrido a largo plazo.

## Resultado simulado (mediana de 200 jugadores)
| Bóveda | Antes | Ahora |
|---|---|---|
| 2 | min 11 | **min 5** |
| 3 | min 35 | **min 12** |
| 4 | — | min 18 |
| 5 | — | min 22 |
| 6 | — | min 28 |

La simulación está en [`simulacion_economia.py`](simulacion_economia.py) (`python3 design/simulacion_economia.py`). Es aproximada: no cuenta el legendario de servidor, los códigos ni la recompensa diaria, que adelantan algo el ritmo.

## Cómo comprobarlo con jugadores de verdad
En el Creator Hub > Analíticas > Embudos verás cuántos jugadores llegan a `zona_2` y `zona_3` (ver `Config/Analytics.luau`). Si menos de la mitad de los que cobran llegan a `zona_2`, baja su precio; si casi todos llegan en 2 minutos, súbelo.

## Mutaciones (noviembre 2026): ¿rompen los precios?
Pregunta: con Vacío x8 y Enorme x7 (x56 en total), ¿un jugador con suerte se salta las bóvedas?
La simulación ahora lee los números directamente de `src/shared/Config` (catálogo de 21 bichos,
9 bóvedas, mutaciones y eventos), así que basta con volver a ejecutarla tras cambiar el balance.

Minuto en que se abre cada bóveda (400 jugadores, 60 minutos):

| Bóveda | Sin mutaciones | Con mutaciones (mediana) | Con mutaciones (el 5 % con más suerte) |
|---|---|---|---|
| 2 | 4,3 | 3,9 | 2,8 |
| 3 | 13,3 | 11,7 | 8,7 |
| 4 | 31,9 | 27,4 | 20,6 |
| 5 | 49,1 | 43,6 | 31,4 |

- Las mutaciones adelantan al jugador medio un 10-15 %, y al 5 % con más suerte un 25-35 %. No se
  salta bóvedas: el precio de cada bóveda sube x4 y un bicho x56 sale en menos de 1 de cada
  100.000 apariciones.
- Peor caso, con alguien invocando la Grieta del Vacío sin parar: casi igual que sin evento
  (el Vacío sigue siendo rarísimo). La Fiebre del Oro sin parar adelanta algo más, pero poco.
- Pase Red Titánica: adelanta un 5-10 % más. Es una ventaja de pago aceptable.
- **Fallo corregido:** la fusión no contaba el multiplicador de bóveda, así que en las bóvedas
  lejanas salía casi gratis. Ver `design/Mutaciones.md`.
- Ojo: con el catálogo v3, la bóveda 4 (300.000) se abre hacia el minuto 27 y la 5 hacia el
  minuto 44. Es más lento que el objetivo de la tabla de arriba. No lo he cambiado porque es una
  decisión de ritmo. Si quieres que la 4 llegue antes, bájala a unos 150.000.
