' Lanza el widget de uso de Claude sin mostrar ventana de consola.
' Se ubica solo: usa la carpeta donde esta este .vbs.
Set fso = CreateObject("Scripting.FileSystemObject")
here = fso.GetParentFolderName(WScript.ScriptFullName)
script = here & "\claude-usage-widget.ps1"
Set sh = CreateObject("WScript.Shell")
sh.Run "powershell -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File """ & script & """", 0, False
