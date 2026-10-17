function gwt {
    [CmdletBinding()]
    param()

    # 必要な外部コマンドを確認
    foreach ($cmd in @('git', 'fzf')) {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
            Write-Error "Required command not found: $cmd"
            return
        }
    }

    # git リポジトリの中か確認
    git rev-parse --show-toplevel *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning 'git リポジトリの中ではありません。'
        return
    }

    # worktree 一覧を解析（porcelain 形式）
    $entries = [System.Collections.Generic.List[object]]::new()
    foreach ($line in @(git worktree list --porcelain)) {
        if ($line -like 'worktree *') {
            $entries.Add([pscustomobject]@{
                    Path   = $line.Substring(9).Trim()
                    Branch = 'detached'
                    Bare   = $false
                })
            continue
        }
        if ($entries.Count -eq 0 -or [string]::IsNullOrEmpty($line)) { continue }
        $cur = $entries[-1]
        if ($line -like 'branch *') { $cur.Branch = $line.Substring(7) -replace '^refs/heads/', '' }
        elseif ($line -eq 'bare') { $cur.Bare = $true }
    }
    $entries = @($entries | Where-Object { -not $_.Bare })

    if ($entries.Count -le 1) {
        Write-Host 'このリポジトリには worktree が1つだけです。'
        return
    }

    # 表示行（フォルダ名 + ブランチ）とパス（隠しフィールド）をタブ区切りで作る
    $current = ((git rev-parse --show-toplevel) -replace '\\', '/').TrimEnd('/')
    $items = foreach ($e in $entries) {
        $mark = if ($e.Path.TrimEnd('/') -eq $current) { '*' } else { ' ' }
        "$mark $(Split-Path -Leaf $e.Path)  [$($e.Branch)]`t$($e.Path)"
    }

    # fzf: Enter または Ctrl+E で選択を返す
    $result = @(
        $items | fzf --no-sort `
            --delimiter='\t' `
            --with-nth=1 `
            --layout=reverse `
            --height=80% `
            --border `
            --scheme=path `
            --prompt='worktree> ' `
            --header='Enter: 移動  |  Ctrl+E: VS Code で開く  |  Esc: キャンセル' `
            --expect=ctrl-e `
            --with-shell 'sh -c' `
            --preview='git -C {2} -c color.status=always status -sb 2>/dev/null; git -C {2} log -5 --oneline --decorate --color=always 2>/dev/null'
    )

    if ($result.Count -eq 0) {
        return
    }

    # Ctrl+E の場合は先頭にキー名が返る
    $open = $result.Count -ge 2 -and $result[0] -eq 'ctrl-e'
    $path = ($result[-1] -split "`t")[-1]

    if ($open) {
        if (Get-Command code -ErrorAction SilentlyContinue) {
            code -n -- "$path"
        }
        else {
            Write-Warning "VS Code (code) が見つかりません: $path"
        }
        return
    }

    Set-Location -LiteralPath $path
}
