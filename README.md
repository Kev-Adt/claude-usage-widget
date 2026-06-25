# Claude Usage Widget

Un widget de escritorio para **Windows** que muestra, en una ventanita flotante y en un icono de la barra de tareas, **cuánto llevas consumido de tu plan de Claude** — el mismo % que ves en el panel oficial `/usage` (Configuración → Uso).

- 🟠 Icono "mascota" (el destello de Claude) en la bandeja del sistema.
- ⬆️ Al hacer **clic** se despliega un panel hacia arriba con animación.
- 📊 Muestra el **% de la sesión (ventana de 5 h)** y el **% semanal**, con la hora a la que se reinician.
- 🎨 Colores de alerta (naranja / amarillo / rojo) según la severidad que reporta la API.
- 🔁 Se actualiza solo cada 2 minutos.
- 🧊 No se congela: si el token vence, avisa con un botón **Reconectar**.

> Hecho con **PowerShell + .NET WinForms**. Sin Electron, sin dependencias que instalar.

---

## ¿De dónde saca los números?

Lee el **mismo endpoint oficial** que usa Claude Code para su comando `/usage`:

```
GET https://api.anthropic.com/api/oauth/usage
Authorization: Bearer <token OAuth>
anthropic-beta: oauth-2025-04-20
anthropic-version: 2023-06-01
```

El token OAuth se toma de tu archivo local de credenciales de Claude Code:
`%USERPROFILE%\.claude\.credentials.json`.

Devuelve, entre otros campos: `five_hour.utilization` (sesión), `seven_day.utilization`
(semana) y `resets_at` (cuándo se reinicia cada límite).

> ⚠️ **Aviso importante:** este endpoint es **interno / no documentado** por Anthropic.
> No es una API pública oficial: puede cambiar o dejar de funcionar en cualquier momento.
> El widget solo **lee tu propio consumo**; no envía tus datos a ningún lado.

---

## Requisitos

- Windows 10/11.
- **Claude Code** instalado y con sesión iniciada (de ahí sale el token).
- PowerShell (viene con Windows) y .NET (incluido).

## Instalación

1. Copia esta carpeta a donde quieras (todo es portable, sin rutas fijas).
2. Doble clic en **`Start-Widget.vbs`** para iniciarlo.
3. (Opcional) Para que arranque con Windows, copia `Start-Widget.vbs` a la carpeta de Inicio:
   pulsa `Win + R`, escribe `shell:startup`, Enter, y pega ahí el `Start-Widget.vbs`.

## Uso

| Acción | Resultado |
|---|---|
| **Clic** en el icono de la bandeja | Despliega / repliega el panel |
| **Clic** en la **X** | Oculta el panel |
| **Clic derecho** en el icono | Menú: Mostrar/Ocultar, Actualizar, Reconectar, Salir |
| Arrastrar desde el título | Mueve la ventana |

---

## Sobre el token y el "Reconectar"

El token oficial **dura ~8 horas** y luego vence. **La renovación automática por API
no funciona** (Anthropic responde `429` de forma persistente), así que cuando el token
caduca el widget muestra en rojo **"Token vencido - CLIC AQUI para reconectar"**.

Al pulsarlo (o clic derecho → *Reconectar*) se ejecuta `Reconectar-Claude.cmd`, que corre:

```
claude auth login --claudeai
```

Esto abre el navegador para iniciar sesión; si muestra un código, se pega en la consola.
En ~10 segundos queda un token fresco y el widget se sincroniza solo. En la práctica,
basta reconectar **una vez al día**.

---

## Archivos

| Archivo | Para qué |
|---|---|
| `claude-usage-widget.ps1` | El widget (UI + lógica + lectura del endpoint) |
| `Start-Widget.vbs` | Lanza el widget oculto (sin ventana de consola) |
| `Reconectar-Claude.cmd` | Renueva el token (login del CLI de Claude) |

## Solución de problemas

- **No veo el icono:** está en la flecha **^** de iconos ocultos de la barra de tareas;
  arrástralo afuera para fijarlo.
- **Dice "Sin conexión":** revisa tu internet; reintenta solo.
- **Dice "Token vencido":** pulsa el texto rojo para reconectar.
- **SmartScreen al abrir un `.cmd`/`.vbs`:** *Más información → Ejecutar de todas formas*
  (son scripts locales, puedes leer su contenido).

## Aviso legal

Proyecto personal, no afiliado a Anthropic. Usa un endpoint no oficial bajo tu propia
responsabilidad. Solo lee tu propio uso; no almacena ni transmite credenciales.

## Licencia

MIT — ver [LICENSE](LICENSE).
