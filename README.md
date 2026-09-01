# Minibar y entorno Hyprland

Este repositorio instala el Minibar de Quickshell y reproduce el entorno de
trabajo de la máquina original en Arch Linux, CachyOS y derivadas compatibles.
La instalación completa está pensada para ejecutarse como un usuario normal
con acceso a `sudo`.

## Qué instala

- Hyprland, Quickshell, Overview, Hyprpaper, Hyprlauncher y Hyprshutdown.
- PipeWire/WirePlumber para audio, BlueZ/Blueman para Bluetooth,
  NetworkManager, UPower y herramientas de brillo (`brightnessctl` y DDC/CI).
- Docker Engine y Docker Compose, con el usuario agregado al grupo `docker`.
- Portapapeles, capturas y grabación: `cliphist`, `wl-clipboard`, Grim, Slurp,
  Satty y wf-recorder.
- Kitty y Zsh con autocompletado (incluidos Codex y OpenCode), autosugerencias,
  resaltado de sintaxis, historial, `eza`, `bat`, `zoxide`, Fastfetch y
  JetBrains Mono Nerd Font.
- HyprFM y todas sus integraciones para archivos, discos, red, vistas previas,
  archivos comprimidos, video y PDF. No instala Dolphin.
- Brave, Zed, OpenCode, Codex CLI, Claude Code, Hermes Agent, NVM y Node.js LTS.
- Tu configuración de Hyprland, Overview, Kitty y Zsh. `SUPER+E` abre HyprFM.

Los paquetes oficiales están en [packages/arch.txt](packages/arch.txt) y los
de AUR en [packages/aur.txt](packages/aur.txt). Si no hay `paru` ni `yay`, el
instalador construye esos tres paquetes directamente desde AUR.

## Instalación en la PC del trabajo

Después de publicar este repositorio en GitHub:

```bash
git clone https://github.com/TU_USUARIO/TU_REPOSITORIO.git ~/.config/quickshell/minibar
cd ~/.config/quickshell/minibar
chmod +x install.sh scripts/check-dependencies.sh
./install.sh
```

El proceso actualiza Arch, muestra las confirmaciones normales de `pacman` y
AUR, descarga los instaladores oficiales de Zed, Codex y Claude Code, y guarda
copias de todo archivo reemplazado bajo:

```text
~/.local/state/minibar-installer/backups/FECHA-HORA/
```

Las configuraciones de monitores y teclados empiezan con valores portables. Si
el instalador se ejecuta dentro de una sesión Hyprland, Minibar detecta y guarda
los conectores reales de esa PC automáticamente.

Al terminar, cierra sesión y vuelve a entrar. Esto aplica Zsh como shell y la
pertenencia a los grupos `docker` e `i2c` (este último permite ajustar el brillo
de monitores externos). Luego completa los inicios de sesión que sí requieren
tu cuenta:

```bash
tailscale up
codex
claude
opencode
hermes setup
```

Comprueba el entorno en cualquier momento con:

```bash
./scripts/check-dependencies.sh
```

Para restaurar solo las configuraciones sin instalar paquetes ni modificar
servicios:

```bash
./install.sh --dotfiles-only
```

## Decisiones de seguridad y compatibilidad

- El instalador nunca debe ejecutarse como `root`; usa `sudo` solo para paquetes,
  servicios, grupos y el shell predeterminado.
- Las configuraciones existentes se copian antes de reemplazarse.
- No se copian llaves SSH, tokens, sesiones de Docker ni credenciales de las
  herramientas de IA.
- Los controladores de GPU no se instalan automáticamente porque dependen del
  hardware y, en NVIDIA, también del kernel. La PC debe tener un controlador
  gráfico funcional antes de iniciar Hyprland.
- AUR ejecuta PKGBUILDs mantenidos por la comunidad. Revisa las recetas durante
  la confirmación si la política de la empresa lo exige.

## Fuentes de instalación

- [Quickshell en Arch](https://quickshell.org/docs/v0.3.0/guide/install-setup/)
- [HyprFM](https://github.com/soyeb-jim285/hyprfm)
- [Zed para Linux](https://zed.dev/docs/linux)
- [OpenCode](https://github.com/anomalyco/opencode)
- [Codex CLI](https://developers.openai.com/codex/cli/)
- [Claude Code](https://code.claude.com/docs/en/installation)
- [Hermes Agent](https://github.com/NousResearch/hermes-agent)
