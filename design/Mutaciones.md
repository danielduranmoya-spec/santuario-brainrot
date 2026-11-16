# Mutaciones, máquinas de fusión y eventos de mutación

Los números viven en `src/shared/Config/Mutations.luau` (y los precios en Robux en `Config/Shop.luau`).
El ciclo de día y noche se ha quitado del juego: los bichos se pueden atrapar siempre.

## Dos capas que se sortean al aparecer cada bicho

Cada bicho salvaje sortea por separado un **color** y un **tamaño**. Los multiplicadores se
multiplican entre sí, con el multiplicador de bóveda y con lo que produce el bicho.
Ejemplo: Radioactivo x6 × Enorme x7 = **x42**.

### Color / Elemento

| Color | Multiplicador | Probabilidad base | Aspecto |
|---|---|---|---|
| Normal | x1 | 89,83 % | El original |
| Oro | x2 | 6,00 % | Foil dorado, destellos amarillos |
| Diamante | x3 | 2,50 % | Cristal azul semitransparente, brillos blancos |
| Neón | x4 | 1,00 % | Neon vibrante con luz y chispas |
| Arcoíris | x5 | 0,40 % | El color va girando sin parar (lo hace el cliente) |
| Radioactivo | x6 | 0,20 % | Verde tóxico brillante, humo verde |
| Espectral | x7 | 0,06 % | Transparencia 0,5, aura celeste, humo azul |
| Vacío | x8 | 0,01 % | Negro absoluto, luz y humo morado oscuro |

Los ojos no cambian de color para que el bicho se siga reconociendo.

### Tamaño

| Tamaño | Multiplicador | Probabilidad | Escala | Zona verde |
|---|---|---|---|---|
| Normal | x1 | 96,5 % | 100 % | igual |
| Grande | x3 | 3,0 % | 160 % | −2 puntos |
| Enorme | x7 | 0,5 % | 250 % | −4 puntos |

La zona verde nunca baja de 1,5 %. En el santuario los grandes se dibujan algo más pequeños
(x1,3 y x1,6, y nunca más anchos que la distancia entre pedestales) para no pisar a los vecinos.

## Máquinas de fusión (solo tamaño)

Están en la plaza, una a cada lado de la avenida, justo antes de la primera bóveda.

- **Agrandadora:** 5 bichos iguales de tamaño Normal + monedas → 1 Grande.
- **Titánica:** 4 Grandes iguales + monedas → 1 Enorme.

Coste en monedas: lo que produce ese bicho (base) en 300 s en la Agrandadora y en 900 s en la
Titánica, con un mínimo de 100 y 1.000. *(Decisión mía; ajustable en `Mutations.Machines`.)*

**Herencia de color:** el resultado toma el color de uno de los bichos que entran, elegido al azar.
Todos del mismo color → se conserva al 100 %. 2 Oro + 3 Normales → 40 % Oro. Si tienes más bichos
de los necesarios, entran primero los del color más valioso. El multiplicador de bóveda del
resultado es el más bajo de los que entran (para que no se pueda «subir» de bóveda fusionando).

## Eventos de mutación

Cada 20 minutos empieza uno automáticamente (si hay jugadores), dura 5 minutos y afecta a todos
los bichos que aparecen. La pantalla se tiñe del color del evento, caen partículas del cielo y sale
un aviso con cuenta atrás.

| Evento | Efecto | Peso en el sorteo | Invocar |
|---|---|---|---|
| Fiebre del Oro | Oro sube al 18 % | 26 % | 49 R$ |
| Lluvia de Cristales | Diamante sube al 10 % | 23 % | 79 R$ |
| Sobrecarga Neón | Neón sube al 5 % | 20 % | 119 R$ |
| Aurora Arcoíris | Arcoíris sube al 3,2 % | 15 % | 179 R$ |
| Fuga Radioactiva | Radioactivo sube al 2 % | 11 % | 249 R$ |
| Grieta del Vacío (rara) | Espectral 0,9 % y Vacío 0,15 % | 5 % | 399 R$ |

Los pesos son una propuesta mía. Normal se queda lo que sobra (por ejemplo 77,83 % en la Fiebre del Oro).

## Robux

- **Invocar Evento para el Servidor** (un producto por evento): empieza al momento, o al terminar el
  que esté en marcha, y sale un aviso dorado para todos: «¡[Usuario] ha invocado una Grieta del
  Vacío para todos!».
- **Pase Red Titánica** (399 R$, precio propuesto): al atrapar, 10 % de que el bicho crezca un tamaño
  (Normal → Grande, Grande → Enorme).

Los IDs están a 0 hasta que se creen en el Creator Hub (ver `Config/Shop.luau`).

## Cómo se guarda

`"id"`, `"id*multiplicador"` y, con mutación, `":Color:Tamaño"` al final
(`"caracol_turbo:Oro:Grande"`). Las partidas viejas se leen como bichos sin mutación.
