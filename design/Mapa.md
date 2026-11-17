# Mapa: Isla Santuario

Sustituye al campo recto (plaza + bóvedas en fila). Todo se genera por código al arrancar el servidor;
los números están en `src/shared/Config/Island.luau` (trazado) y `Config/Art.luau` (`Art.island`, cantidades
de decorado).

## Trazado

```
                 islas flotantes 8, 9, 10… (espiral sobre el mar, unidas por puentes)
                          ↑ puente desde la costa de la zona 7
        zona 6 ─ zona 7 ─┐
       /                  \        faro (entre la 7 y la 1)
  zona 5     ┌────────┐    zona 1 ── muelle con barcas
     |       │ PLAZA  │◄── avenida (única salida del seto)
  zona 4*    │ árbol  │    |
       \     └────────┘   zona 2
        zona 3 (volcán) ─┘
  * la zona 4 (Nube Pegajosa) es una isla flotante sobre su sector, con escaleras en zigzag y cascada
```

- **Plaza central** (radio 50): árbol gigante en flor con farolillos y pétalos, estanque en anillo con
  cuatro puentes, farolas y bancos. Alrededor, el césped con los **6 santuarios en círculo** (mirando al
  árbol), los puestos de eventos, las máquinas de fusión junto a la avenida y los rankings enfrente.
  Un **seto** rodea la plaza: solo se sale por la **avenida** (farolas y banderines) hacia la zona 1.
- **Zonas 1-7**: sectores del anillo que rodea la plaza, separados por **crestas de roca** (con muros
  invisibles encima). Un **camino en anillo** las une pasando por el arco de cada zona. Cada sector tiene
  el suelo y el decorado de su temática.
- **Zona 4**: isla de nubes flotando sobre su sector (escalera de subida junto a su arco y de bajada hacia
  el arco de la 5), con arcoíris y una cascada que cae a un lago.
- **Zonas 8 en adelante**: islas flotantes en espiral sobre el mar, cada una más alta, unidas por puentes
  colgantes. La puerta de cada una está al principio de su puente.
- **Paisaje**: volcán en la costa de la zona 3 (cráter con lava, humo y río de lava hacia el mar), faro,
  muelle con barcas, rocas en la orilla y mar alrededor.

## Distancias (para el bucle de juego)

Del santuario al borde de la zona 1 hay unos 75 studs (~5 s andando) y al centro de la zona 1 unos 130
(~8 s). Antes, con el campo recto, los trayectos eran parecidos.

## Código

- `Shared/VaultMath`: posición, giro y tamaño de cada zona (`frame`, `size`, `point`, `clamp`), sus arcos
  (`gate`) y en qué zona está una posición (`vaultAt`, sectores para las zonas 1-7).
- `Shared/Layout`: santuarios, máquinas, rankings, puestos y punto de aparición.
- `server/Services/WorldArt`: terreno y decorado. `Boundary`: muros invisibles (costa, seto, crestas) y
  rescate si alguien cae al mar o desde una isla. `Vaults`: arcos y puertas de pago.

## Ver el mapa sin Studio

Las capturas del PR se hicieron ejecutando el servidor real del juego en una simulación de Roblox y
dibujando lo que construye (piezas y terreno en vóxeles de 4 studs). Los colores y la luz de Roblox no
son idénticos, pero la distribución sí.
