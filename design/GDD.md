---
juego: Santuario de Bichos Raros
estado: diseño inicial
version: 0.1
fecha: 2026-11-15
publico: 16+ al lanzar (Kids/Select más adelante)
plataforma: móvil primero, también PC y consola
---

# Santuario de Bichos Raros — diseño en una página

## Gancho
**Atrapa bichos absurdos con una red y conviértelos en una fortuna en tu santuario.** Un pez con piernas, una tostada voladora, un cactus que estornuda: cuanto más raro, más monedas genera.

## Bucle de 30 segundos
1. Un bicho aparece en la isla (cada pocos segundos, en puntos al azar).
2. Corres hacia él y pulsas **Atrapar**: una barra con zona verde; si aciertas, lo capturas. Los bichos raros tienen zona más pequeña.
3. Lo llevas a tu santuario (parcela propia). Al soltarlo, empieza a generar monedas por segundo.
4. Gastas monedas en mejoras y vuelves a por un bicho mejor.

## Progresión (primera semana, ~2 h de contenido en el MVP)
| Zona | Se desbloquea con | Rarezas que aparecen |
|---|---|---|
| Playa Rara | inicio | Común, Poco común |
| Bosque Ruidoso | 2.500 monedas | + Raro |
| Volcán Tímido | 40.000 monedas | + Épico |
| Nube Pegajosa | 600.000 monedas | + Legendario |

Mejoras: **Red** (zona verde más grande), **Botas** (velocidad), **Santuario** (más huecos para bichos), **Imán** (recoge monedas a distancia). Valores en `src/shared/Config/`.

## Elemento social
- **Bicho legendario de servidor:** cada 8 minutos aparece uno para todos, con aviso de 15 s. El primero en atraparlo se lo queda y sale en el chat.
- **Cebo:** puedes poner cebo junto al santuario de otro jugador; durante 20 s uno de sus bichos (nunca legendario) puede escaparse hacia ti. El dueño lo evita con una **valla** (dura 10 min, se compra con monedas). Robo amable: nunca pierdes más de 1 bicho cada 10 min.
- Ver santuarios de otros y darles "me gusta" (top del servidor).

## Retorno
- **Recompensa diaria** (racha de 7 días, el día 7 da un bicho raro).
- **Lluvia de Bichos:** sábados 18:00 (hora de España), 30 min. Aparecen bichos x3 y uno exclusivo de la semana.
- **Bicho nuevo cada dos semanas** + código de recompensa con cada actualización.

## Monetización (justa: todo se puede conseguir jugando salvo comodidades)
| Producto | Tipo | Precio |
|---|---|---|
| x2 Monedas | Game pass | 99 R$ |
| Red Dorada (zona verde máxima) | Game pass | 149 R$ |
| VIP (zona exclusiva, nombre de color, +1 hueco) | Game pass | 299 R$ |
| Pack de inicio (5 cebos + bicho raro) | Dev product, una vez, a los 5–10 min | 49 R$ |
| Cebo | Dev product | 25 R$ |
| Suerte x2, 15 min | Dev product | 49 R$ |
| Servidor privado | Servidor de pago | 99 R$/mes |
Además: prompt de Roblox Plus tras un logro (nunca al entrar).

## Primeros 60 segundos (lo más importante para el algoritmo)
- Apareces en la playa con un bicho común **justo delante**. Flecha y texto: "¡Atrápalo!".
- A los 10 s ya tienes tu primer bicho generando monedas. A los 45 s puedes comprar la primera mejora.
- Nada de menús ni tiendas antes del primer minuto.

## Métricas objetivo (lanzamiento silencioso)
D1 ≥ 20 % · sesión media ≥ 12 min · rebote < 60 s por debajo del 30 % · conversión a pago ≥ 1 %. Eventos de analítica: `entra`, `primer_bicho`, `primera_mejora`, `zona_2`, `primera_compra`.

## Fuera del MVP
Intercambio entre jugadores, mascotas que siguen al jugador, clanes, ranking global, Kids/Select.

## Preguntas abiertas
- ¿Estilo visual? (propuesta: low-poly de colores saturados)
- ¿Nombre final y en qué idiomas? (propuesta: inglés como principal + traducción automática de Roblox)
