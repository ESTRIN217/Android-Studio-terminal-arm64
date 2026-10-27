## 🛠️ Solución de Problemas Comunes

### 1. El splash muere con `RenderException: Cannot create surface` (AS ≥ 2026)
Es el problema grande de las versiones actuales: los natives de la última IDEA Community (línea 253) son antiguos frente a la plataforma de Android Studio 2026 (línea 262). El log muestra `UnsatisfiedLinkError` en `…skia/paragraph/TextStyleKt._nSetFontEdging`.

Solución: parche skiko con la versión exacta que pide tu build (el script `install_studio.sh` lo hace solo); a mano:

```bash
SKIKO_DESEADO=$(unzip -p ~/android-studio/lib/intellij.libraries.skiko.jar \
    org/jetbrains/skiko/Version.class \
    | grep -aoE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
curl -LO "https://repo1.maven.org/maven2/org/jetbrains/skiko/skiko-awt-runtime-linux-arm64/${SKIKO_DESEADO}/skiko-awt-runtime-linux-arm64-${SKIKO_DESEADO}.jar"
unzip -j -o "skiko-awt-runtime-linux-arm64-${SKIKO_DESEADO}.jar" libskiko-linux-arm64.so -d ~/android-studio/lib/skiko-awt-runtime-all/
```

### 2. Error de "Permission Denied" al ejecutar `studio.sh`
Otorga permisos de ejecución a la carpeta `bin`:
```bash
chmod +x ~/android-studio/bin/*.sh
```

### 3. Pantalla en blanco o parpadeo (Problemas de Renderizado)
Si la interfaz no se ve bien en el escritorio X11, desactiva la aceleración xrender de Java2D (añádelo antes de lanzar el IDE, o al final de `~/.bashrc`):
```bash
export _JAVA_OPTIONS="-Dsun.java2d.xrender=false"
```

### 4. El IDE cierra por memoria (5–6 GB de RAM)
Limita el heap en `~/android-studio/bin/studio.vmoptions`:
```
-Xms512m
-Xmx2048m   # verificado con 5 GB de RAM; baja a 1536m si el sistema se apura
```
Truco: cierra los daemons Gradle que queden vivos de pruebas anteriores con `gradle --stop`, liberan JVMs completas.

### 5. Avisos inofensivos en el arranque
- `[warning][cds] Archived non-system classes are disabled…` — informativo de Java, ignóralo.
- `dbind-WARNING … Couldn't register with accessibility bus` — notificación de accesibilidad GTK sin consecuencias.
- Sobran ficheros x86_64 en las carpetas de natives: se queda sin usar (carga por `os.arch`). Borrarlos es opcional (ahorra algo de disco).

### 6. El emulador no arranca
Normal: no hay KVM en los kernels de Android. Prueba en dispositivo físico con ADB por USB (la app Terminal soporta USB), por ejemplo: `adb install -r ~/mi-app-debug.apk`.
