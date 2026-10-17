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

    # fzf: Tab で複数選択、Esc でキャンセル
    $selected = @(
        $items | fzf `
            --multi `
            --layout=reverse `
            --height=80% `
            --border `
            --scheme=path `
            --prompt='copy path> ' `
            --header='Enter: パスをコピー  |  Tab: 複数選択  |  Esc: キャンセル' `
            --with-shell 'sh -c' `
            --preview='bat --color=always --style=numbers -- {} 2>/dev/null' `
            --preview-window='right,50%,border-left'
    )

    if ($selected.Count -eq 0) {
        return
    }

    # カレントディレクトリ相対のパスをそのまま改行区切りでコピー
    Set-Clipboard -Value ($selected -join "`n")
    if ($selected.Count -eq 1) {
        Write-Host "Copied: $($selected[0])"
    }
    else {
        Write-Host "Copied: $($selected.Count) paths"
    }
}
