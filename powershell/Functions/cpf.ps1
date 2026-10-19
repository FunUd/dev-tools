function cpf {
    [CmdletBinding()]
    param()

    # 必要な外部コマンドを確認
    foreach ($cmd in @('fd', 'fzf', 'bat')) {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
            Write-Error "Required command not found: $cmd"
            return
        }
    }

    # カレントディレクトリ以下を検索（ff と同じ条件）
    $items = @(
        fd --hidden `
            --exclude .git `
            --exclude node_modules `
            --exclude .venv `
            --exclude __pycache__ `
            . .
    )
    if ($LASTEXITCODE -ne 0 -or $items.Count -eq 0) {
        Write-Host '対象がありません。'
        return
    }

    # 一覧は「ファイル名 (ディレクトリ)」+ TAB + 実パス に加工する
    # （深いパスでもファイル名が隠れないようにするため。選択値はTAB区切りの2列目を使う）
    $display = foreach ($item in $items) {
        $trimmed = $item.TrimEnd('/', '\')
        $slashIndex = $trimmed.LastIndexOfAny([char[]]@('/', '\'))
        if ($slashIndex -ge 0) {
            $name = $trimmed.Substring($slashIndex + 1)
            $dir = $trimmed.Substring(0, $slashIndex) -replace '^[.][/\\]', ''
        }
        else {
            $name = $trimmed
            $dir = '.'
        }
        $suffix = if ($item.EndsWith('/') -or $item.EndsWith('\')) { '/' } else { '' }
        "$name$suffix  ($dir)`t$item"
    }

    # fzf: Tab で複数選択、Esc でキャンセル
    $selected = @(
        $display | fzf `
            --multi `
            --layout=reverse `
            --height=80% `
            --border `
            --scheme=path `
            --delimiter='\t' `
            --with-nth=1 `
            --prompt='copy path> ' `
            --header='Enter: パスをコピー  |  Tab: 複数選択  |  Esc: キャンセル' `
            --with-shell 'sh -c' `
            --preview='bat --color=always --style=numbers -- {2} 2>/dev/null' `
            --preview-window='right,50%,border-left'
    )

    if ($selected.Count -eq 0) {
        return
    }

    # TAB区切りの2列目（実パス）を取り出す
    $paths = @($selected | ForEach-Object { ($_ -split "`t")[-1] })

    # カレントディレクトリ相対のパスをそのまま改行区切りでコピー
    Set-Clipboard -Value ($paths -join "`n")
    if ($paths.Count -eq 1) {
        Write-Host "Copied: $($paths[0])"
    }
    else {
        Write-Host "Copied: $($paths.Count) paths"
    }
}
