# GameBacklog

Icono original: mando blanco y pila de juegos sobre el morado `#6949DB` de la
barra de navegación. El diseño vectorial está en `gamebacklog.svg`; el PNG
maestro mide 1024 × 1024 y `preview.png` es una vista de 256 × 256.

Para regenerar los iconos, ejecutar desde la raíz en PowerShell de Windows:

```powershell
./tool/generate_app_icons.ps1
```

El script contiene la geometría original y genera el SVG, PNG, tamaños de
Android/iOS/macOS/web y el ICO de Windows usando System.Drawing. Los iconos
de Android incluyen capas adaptativas y una variante monocromática. El nombre
visible es GameBacklog; el identificador Android y el paquete Dart se mantienen
para actualizar la instalación existente.

Referencia de formato:
[Iconos adaptativos de Android](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive).
