# 🚀 Android Studio en ARM64 con la app Terminal

Esta guía detalla cómo ejecutar Android Studio dentro del guest Debian de la app **[Terminal](https://github.com/ESTRIN217/Terminal)** (Debian vía `proot`, sin root), usando las librerías nativas de IntelliJ IDEA para habilitar la compatibilidad con la arquitectura **ARM64 (aarch64)** y un parche skiko obligatorio para las versiones 2026+.

> ✅ **Verificado en octubre de 2026**: Android Studio Rabbit 1 (2026.2.1) + IDEA Community 2025.3 aarch64 + skiko 0.144.5 + OpenJDK 25, en un dispositivo con 5 GB de RAM.

---

## 📋 Requisitos Previos

| Recurso | Requisito Mínimo |
| :--- | :--- |
| **RAM** | 5 GB (se ha probado; 6–8 GB recomendados) |
| **Espacio** | 10 GB de almacenamiento libre |
| **SO** | Guest Debian de Terminal (sesión Debian de la app) |
| **GUI** | Pestaña X11 de Terminal con el servidor iniciado |
| **JDK** | `openjdk-25-jdk` |

---

## 🛠️ Paso 1: Descarga de Componentes

Necesitaremos ambos paquetes para realizar un "híbrido" funcional:

1.  **Android Studio (Linux):** [Descargar aquí](https://developer.android.com/studio?hl=es-419) — el tarball `*-linux.tar.gz`
2.  **IntelliJ IDEA Community (aarch64):** [Descargar aquí](https://www.jetbrains.com/idea/download/?section=linux) — el artefacto **Linux ARM64**

> [!IMPORTANT]
> Asegúrate de descargar la versión **aarch64/ARM64** de IntelliJ IDEA. Los artefactos x86_64 no traen natives útiles para esta arquitectura.
> Verificada: IDEA Community 2025.3 (build 253.28294.334); las líneas superiores ya no tienen build Community.

Descarga o extrae dentro de la sesión Debian (o usa el gestor de archivos como pestaña y extrae con la terminal del guest):

```bash
cd ~
tar -xzf android-studio-*.tar.gz        # → ~/android-studio
tar -xzf idea-*-aarch64.tar.gz          # → ~/idea-IU-253.… (¡nombre unificado!)
mv idea-IU-* idea-IC
```

---

## 📦 Paso 2: Parche de compatibilidad ARM64

Android Studio no incluye binarios nativos para ARM64 en Linux. Copiamos los de IDEA (que sí los tiene) sobre la instalación de AS:

```bash
cp -r ~/idea-IC/lib/jna/*                   ~/android-studio/lib/jna/
cp -r ~/idea-IC/lib/native/*                ~/android-studio/lib/native/
cp -r ~/idea-IC/lib/pty4j/*                 ~/android-studio/lib/pty4j/
cp -r ~/idea-IC/lib/skiko-awt-runtime-all/* ~/android-studio/lib/skiko-awt-runtime-all/
```

---

## 🎨 Paso 3: Parche skiko (obligatorio con AS 2026+)

Los natives de la última IDEA Community (línea 253) se han quedado **antiguos** respecto a la plataforma de Android Studio 2026 (línea 262): al arrancar, el splash muere con `org.jetbrains.skiko.RenderException: Cannot create surface` y `UnsatisfiedLinkError` en `…TextStyleKt._nSetFontEdging`.

Se sustituye el nativo `skiko` por la versión exacta que pide tu build (Rabbit 1 pide **0.144.5**):

```bash
SKIKO_DESEADO=$(unzip -p ~/android-studio/lib/intellij.libraries.skiko.jar \
    org/jetbrains/skiko/Version.class \
    | grep -aoE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
echo "skiko requerido: $SKIKO_DESEADO"

cd /tmp
curl -LO "https://repo1.maven.org/maven2/org/jetbrains/skiko/skiko-awt-runtime-linux-arm64/${SKIKO_DESEADO}/skiko-awt-runtime-linux-arm64-${SKIKO_DESEADO}.jar"
unzip -j -o "skiko-awt-runtime-linux-arm64-${SKIKO_DESEADO}.jar" "libskiko-linux-arm64.so"
mv libskiko-linux-arm64.so ~/android-studio/lib/skiko-awt-runtime-all/
```

---

## ☕ Paso 4: Configuración del Java Runtime (JBR)

Android Studio trae un JBR para x86_64: se elimina y se reemplaza con el JDK del guest:

```bash
rm -rf ~/android-studio/jbr
JDK_ARM64=$(ls -d /usr/lib/jvm/java-2*-openjdk-arm64 | sort -V | tail -n1)
ln -s "$JDK_ARM64" ~/android-studio/jbr
```

> [!NOTE]
> La guía clásica de Termux indicaba `openjdk-21` porque Termux no ofrecía el 25. En el guest Debian el 25 va bien (verificado).

---

## 🚀 Paso 5: Ejecución

1. Abre la **pestaña X11** de Terminal y pulsa *Iniciar el servidor X* (el escritorio usa `DISPLAY=:0`, ya exportado por la app en las sesiones Debian).
2. En la sesión Debian:

```bash
cd ~/android-studio/bin
./studio.sh
```

La primera ejecución tarda varios minutos (asistente de configuración) — es lo normal en un móvil.

## ⚡ Script automatizado

Los pasos 2–4 los hace el script del propio repo:

```bash
curl -LO https://github.com/ESTRIN217/Android-Studio-terminal-arm64/raw/main/install_studio.sh
bash install_studio.sh
```

---

## 📦 Anexo: SDK de Android

Android Studio descargará el SDK a demanda (puedes cambiar su ruta a la carpeta del guest). Para herramientas previas adaptadas, consulta los repositorios de HomuHomu833:

👉 HomuHomu833 — https://github.com/HomuHomu833

⚠️ Advertencia: el emulador de Android Studio no funcionará (sin KVM en los kernels de Android). Prueba tus apps en un dispositivo físico con ADB (por USB, con la app Terminal).

## 🔗 Wiki del proyecto

- [Parcheo automático (script)](https://github.com/ESTRIN217/Android-Studio-terminal-arm64/wiki/Parcheo-autom%C3%A1tico)
- [Pasos adicionales](https://github.com/ESTRIN217/Android-Studio-terminal-arm64/wiki/Pasos-adicionales)
- [Problemas comunes](https://github.com/ESTRIN217/Android-Studio-terminal-arm64/blob/main/Problemas%20comunes.md)

---
