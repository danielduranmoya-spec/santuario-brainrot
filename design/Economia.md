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
