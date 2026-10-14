# 開発用 PowerShell 関数のローダー。
# Functions/*.ps1 をドットソースするだけ。1関数=1ファイルで追加する。
$functionFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Functions' '*.ps1') -ErrorAction SilentlyContinue
foreach ($file in $functionFiles) {
    . $file.FullName
}
