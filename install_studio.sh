#!/bin/bash

# =================================================================
# SCRIPT DE INSTALACIÓN AUTOMATIZADA: ANDROID STUDIO ARM64 (TERMINAL)
# Ejecutar dentro del guest Debian de la app Terminal (proot).
# El guest corre como root: no se necesita sudo.
# Combinación verificada (octubre de 2026):
#   Android Studio Rabbit 1 (2026.2.1) + IDEA Community 2025.3 aarch64
#   + skiko 0.144.5 (Maven Central) + OpenJDK 25 del guest.
# =================================================================

set -e

echo "🚀 Iniciando configuración de Android Studio..."

# 1. Definir rutas (ajusta si tus carpetas se llaman distinto)
STUDIO_DIR="$HOME/android-studio"
IDEA_DIR="$HOME/idea-IC" # Nombre tras renombrar la carpeta extraída de IDEA

# 2. Dependencias (el guest ya trae OpenJDK 25)
echo "📦 Instalando dependencias..."
apt update
apt install -y openjdk-25-jdk tar curl unzip

JDK_ARM64="$(ls -d /usr/lib/jvm/java-2*-openjdk-arm64 2>/dev/null | sort -V | tail -n1)"
if [ -z "$JDK_ARM64" ]; then
    echo "❌ Error: no se encontró un JDK aarch64 en /usr/lib/jvm."
    exit 1
fi
echo "☕ JDK detectado: $JDK_ARM64"

# Comprobación previa de carpetas
if [ ! -d "$IDEA_DIR/lib" ] || [ ! -d "$STUDIO_DIR/lib" ]; then
    echo "❌ Error: no se encontraron las carpetas de Android Studio o IntelliJ."
    echo "   STUDIO_DIR=$STUDIO_DIR  IDEA_DIR=$IDEA_DIR"
    echo "   ¿Descargaste y extrajiste ambos tarballs en \$HOME?"
    echo "   Nota: la IDEA extraída puede llamarse idea-IU-…; renómbrala:"
    echo "     mv ~/idea-IU-* ~/idea-IC"
    exit 1
fi

# 3. Parche de compatibilidad ARM64 (el corazón del proceso)
echo "🔧 Aplicando parche de librerías ARM64 desde IntelliJ..."
cp -r "$IDEA_DIR/lib/jna/"*                 "$STUDIO_DIR/lib/jna/"
cp -r "$IDEA_DIR/lib/native/"*              "$STUDIO_DIR/lib/native/"
cp -r "$IDEA_DIR/lib/pty4j/"*               "$STUDIO_DIR/lib/pty4j/"
cp -r "$IDEA_DIR/lib/skiko-awt-runtime-all/"* "$STUDIO_DIR/lib/skiko-awt-runtime-all/"
echo "✅ Librerías parcheadas."

# 4. Parche skiko: los natives de IDEA Community (línea 253) son antiguos
#    para la plataforma de Android Studio 2026+ (línea 262). Sin este paso,
#    el splash muere con "RenderException/UnsatisfiedLinkError _nSetFontEdging".
echo "🎨 Aplicando parche skiko desde Maven Central..."
SKIKO_DESEADO="$(unzip -p "$STUDIO_DIR/lib/intellij.libraries.skiko.jar" \
    org/jetbrains/skiko/Version.class \
    | grep -aoE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
if [ -z "$SKIKO_DESEADO" ]; then
    echo "❌ Error: no se pudo leer la versión de skiko del jar."
    exit 1
fi
echo "   skiko requerido por este Android Studio: $SKIKO_DESEADO"
TMP_SO="/tmp/libskiko-linux-arm64.so"
curl -L -o /tmp/skiko-native.jar \
    "https://repo1.maven.org/maven2/org/jetbrains/skiko/skiko-awt-runtime-linux-arm64/${SKIKO_DESEADO}/skiko-awt-runtime-linux-arm64-${SKIKO_DESEADO}.jar"
unzip -o -j /tmp/skiko-native.jar "libskiko-linux-arm64.so" -d /tmp
mv "$TMP_SO" "$STUDIO_DIR/lib/skiko-awt-runtime-all/libskiko-linux-arm64.so"
rm -f /tmp/skiko-native.jar
echo "✅ skiko $SKIKO_DESEADO instalado."

# 5. Verificación de arquitectura de los binarios clave
if command -v file >/dev/null 2>&1; then
    echo "🔍 Verificando que los natives clave son aarch64..."
    for so in \
        "$STUDIO_DIR/lib/jna/aarch64/libjnidispatch.so" \
        "$STUDIO_DIR/lib/native/linux-aarch64/libsqliteij.so" \
        "$STUDIO_DIR/lib/pty4j/linux/aarch64/libpty.so" \
        "$STUDIO_DIR/lib/skiko-awt-runtime-all/libskiko-linux-arm64.so"; do
        if file "$so" | grep -q "ARM aarch64"; then
            echo "   ✔ $(basename "$so")"
        else
            echo "   ⚠ No es aarch64 (o no existe): $so"
        fi
    done
else
    echo "ℹ (instala 'file' para verificar arquitecturas)"
    apt install -y file
fi

# 6. Configuración del Java Runtime (JBR)
echo "☕ Configurando el Java Runtime del guest..."
if [ -d "$STUDIO_DIR/jbr" ] || [ -L "$STUDIO_DIR/jbr" ]; then
    rm -rf "$STUDIO_DIR/jbr"
fi
ln -s "$JDK_ARM64" "$STUDIO_DIR/jbr"
echo "✅ Enlace simbólico de Java creado."

# 7. Permisos de ejecución
echo "🔑 Otorgando permisos de ejecución..."
chmod +x "$STUDIO_DIR/bin/studio.sh"

echo "----------------------------------------------------"
echo "🎉 ¡PROCESO COMPLETADO!"
echo "Antes de arrancar: abre la pestaña X11 de la app y pulsa"
echo "'Iniciar el servidor X' (el escritorio usa DISPLAY=:0)."
echo "Para iniciar Android Studio:"
echo "  cd $STUDIO_DIR/bin && ./studio.sh"
echo "----------------------------------------------------"
