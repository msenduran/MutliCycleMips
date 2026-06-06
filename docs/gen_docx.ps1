# gen_docx.ps1 — Regenerate proje-raporu.docx from the canonical proje-raporu.md.
# Auto-locates pandoc. Run from docs/:  .\gen_docx.ps1
Set-Location $PSScriptRoot

$pandoc = (Get-Command pandoc -ErrorAction SilentlyContinue).Source
foreach ($p in @("$env:LOCALAPPDATA\Pandoc\pandoc.exe",
                 "$env:LOCALAPPDATA\Microsoft\WinGet\Links\pandoc.exe",
                 "$env:ProgramFiles\Pandoc\pandoc.exe")) {
    if (-not $pandoc -and (Test-Path $p)) { $pandoc = $p }
}
if (-not $pandoc) { Write-Error "pandoc bulunamadi. winget install JohnMacFarlane.Pandoc"; exit 1 }

& $pandoc proje-raporu.md -o proje-raporu.docx --toc --toc-depth=2 --resource-path=.
if ($?) { Write-Host "proje-raporu.docx guncellendi (kaynak: proje-raporu.md)" }
