function ff {
    [CmdletBinding()]
    param()

    # 必要な外部コマンドを確認
    foreach ($cmd in @('fd', 'fzf', 'bat')) {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
            Write-Error "Required command not found: $cmd"
            return
        }
    }

    # カレントディレクトリ以下を検索
    # .gitignore 等で除外されたファイルは通常検索対象外
    $items = @(
        fd --hidden `
            --exclude .git `
            --exclude node_modules `
            --exclude .venv `
            --exclude __pycache__ `
            . .
    )

    if ($LASTEXITCODE -ne 0 -or $items.Count -eq 0) {
        Write-Host '検索対象がありません。'
        return
    }

    # fzf: Enter または Ctrl+E で選択を返す
    $result = @(
        $items | fzf `
            --layout=reverse `
            --height=80% `
            --border `
            --scheme=path `
            --prompt='ff> ' `
            --header='Enter: 開く/移動  |  Ctrl+E: 実行  |  Esc: キャンセル' `
            --preview='bat --color=always --style=numbers -- "{}" 2>$null' `
            --preview-window='right,50%,border-left' `
            --expect=ctrl-e
    )

    if ($result.Count -eq 0) {
        return
    }

    # Ctrl+E の場合は先頭にキー名が返る
    $execute = $result.Count -ge 2 -and $result[0] -eq 'ctrl-e'

    if ($execute) {
        $selected = $result[1]
    }
    else {
        $selected = $result[-1]
    }

    if ([string]::IsNullOrWhiteSpace($selected)) {
        return
    }

    $path = Join-Path (Get-Location).Path $selected

    if (-not (Test-Path -LiteralPath $path)) {
        Write-Warning "ファイルが見つかりません: $path"
        return
    }

    # Enter: ディレクトリなら移動
    if (-not $execute -and
        (Test-Path -LiteralPath $path -PathType Container)) {
        Set-Location -LiteralPath $path
        return
    }

    # Enter: ファイルなら VS Code で開く
    if (-not $execute) {
        if (Get-Command code -ErrorAction SilentlyContinue) {
            code --reuse-window -- "$path"
        }
        else {
            Invoke-Item -LiteralPath $path
        }
        return
    }

    # Ctrl+E: 明示的な確認後にのみ実行（誤押下によるトロイ実行を防止）
    $confirm = Read-Host "実行しますか? [y/N] $path"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host 'キャンセルしました。'
        return
    }

    switch ([IO.Path]::GetExtension($path).ToLowerInvariant()) {
        { $_ -in '.exe', '.com' } {
            & $path
        }
        { $_ -in '.bat', '.cmd' } {
            & $path
        }
        '.ps1' {
            & $path
        }
        '.py' {
            if (Get-Command python -ErrorAction SilentlyContinue) {
                python -- "$path"
            }
            else {
                Write-Warning 'Python が見つかりません。'
            }
        }
        default {
            Write-Warning "実行対象外の拡張子です: $path"
        }
    }
}
