# Bichos 3D en estilo figura

Los 21 bichos rehechos como **figuras de juguete con proporciones de animal real** (el estilo elegido
con el Murciélago de Magma), esculpidos de una pieza y con **texturas** (degradado de color, pelo o
escamas en relieve y sombras suaves), y con su parte fantástica bien a la vista (nubes y rayos, llamas,
lava, cristales, tinta, agua…). Vista previa: [`design/bichos/bichos_figura_21.png`](bichos/bichos_figura_21.png).

- Modelos: [`assets/bichos/bichos_figura.fbx`](../assets/bichos/bichos_figura.fbx), un solo archivo con los
  21 bichos. Cada bicho es un grupo con su id (`caracol_turbo`, `murcielago_magma`…) y dentro una malla por
  pieza (Cuerpo, Ala_I, Ala_D, Cola, Parpado, Brillo_…), con sus texturas dentro (JPG). Unos 8.000-13.000
  triángulos por bicho.
- Datos de cada pieza (posición, tamaño, color, material, papel en la animación y punto de giro):
  [`src/shared/Config/CritterMeshes.luau`](../src/shared/Config/CritterMeshes.luau), generado.
- Código: `server/Services/CritterVisual` usa las mallas si están importadas; **si no, dibuja el bicho
  con las piezas de siempre (Shared/CritterArt)**. Se puede aceptar el PR antes de importar nada.

Las animaciones (alas, colas, párpados, engranajes, péndulos, brillos), las mutaciones de tamaño y el
modo de bajo detalle del móvil funcionan igual que con los bichos de piezas. Las mutaciones de color
tiñen la textura (`SurfaceAppearance.Color`) en las piezas con textura y cambian el color en las demás.

## Importarlos en Roblox Studio (una vez, ~5 minutos)

Hace falta tener la sesión de Roblox iniciada en Studio: las mallas se suben a tu cuenta.

1. Abre el sitio (con `rojo serve` conectado, como siempre).
2. En el **Explorador**, dentro de **ReplicatedStorage**, crea una carpeta llamada **`Assets`**
   (botón derecho → Insertar objeto → Folder).
3. Pestaña **Inicio** (o Avatar) → **Importar 3D** → elige `assets/bichos/bichos_figura.fbx`.
   En las opciones del importador:
   - deja **desmarcado** «Fusionar mallas» / «Merge meshes» (cada pieza tiene que ser su propia MeshPart);
   - deja **marcado** importar texturas/materiales (crean la SurfaceAppearance de cada pieza);
   - lo demás, por defecto. La escala da igual: el juego pone el tamaño de cada pieza.
4. Pulsa **Importar**. Aparece un modelo con los 21 bichos dentro (suele llamarse `bichos_figura`).
5. Cámbiale el nombre a **`Bichos`** y arrástralo dentro de **ReplicatedStorage › Assets**.
   (Si dentro hay una carpeta o modelo intermedio, no pasa nada: el juego busca cada bicho por su id.)
6. **Guarda el sitio** y dale a **Jugar**. Los bichos deben verse como en la vista previa.
   - Si salen **mirando hacia atrás**, en `src/shared/Config/Art.luau` pon `Art.critterMeshYawFix = 180`.
   - Si algún bicho sale con las piezas de antes, es que falta alguna malla con su nombre: en la consola no
     hay error; revisa que el modelo de ese id tenga todas sus piezas (están en `Config/CritterMeshes`).
7. Publica (Archivo → Publicar en Roblox).

Roblox revisa las mallas subidas; pueden tardar unos minutos en verse en el juego publicado.

## Cambiar o añadir un bicho

Las herramientas están en `design/herramientas/figuras/` (Python + Blender como módulo `bpy`):

```bash
pip install bpy pillow   # Blender 4.x/5.x como módulo de Python
cd design/herramientas/figuras
python3 hacer2.py v2a v2b v2c v2d          # esculpe, hornea texturas y exporta cada bicho (out2/) + vista previa
python3 hacer2.py v2b:caracol_turbo        # solo uno
python3 juntar2.py                         # out2/bichos_figura.fbx con todos (texturas en JPG dentro)
python3 generar_config.py                  # reescribe src/shared/Config/CritterMeshes.luau
```

Cada bicho es una clase en `v2a.py`…`v2d.py`. `tex.sculpt` esculpe cuerpos de una pieza (elipsoides +
extremidades que se afinan), `tex.furry` / `tex.veined` hacen los materiales que se hornean a textura, y
`piece(nombre, formas, color, material, anim, pivot, bake=…)` crea cada pieza. El nombre antes de `_` es el
papel en la animación (`Ala`, `Cola`, `Parpado`, `Pinza`, `Gota`, `Giro`, `Brillo`, `Arcoiris`, `Pendulo`).
Tras cambiar un bicho hay que volver a importar el FBX en Studio (paso 3) y sustituir el modelo `Bichos`.
