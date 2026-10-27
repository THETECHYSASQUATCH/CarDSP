---
name: powershell-windows
description: Execute safe Windows PowerShell development commands.
---
# PowerShell
- Use PowerShell syntax, not cmd.exe switches.
- Prefer Get-ChildItem, Select-String, Get-Content, and Test-Path.
- Do not use nested powershell -Command strings unnecessarily.
- Do not invent shell commands or tools.
- Check the current directory before accessing relative paths.
- Quote paths containing spaces.
