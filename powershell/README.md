# PowerShell 関数

開発作業用の PowerShell 関数置き場。git エイリアス（`/.gitconfig`）とは独立。

## 構成

```text
powershell/
  DevTools.psm1      # ローダー（Functions/*.ps1 を読み込むだけ）
  Functions/
    ff.ps1           # 1関数=1ファイルで追加
```

## 導入（$PROFILE に1行）

```powershell
Import-Module '<このリポジトリのパス>/powershell/DevTools.psm1'
```

## 関数一覧

| 関数 | 説明 | 依存 |
| ---- | ---- | ---- |
| `ff` | `fd` + `fzf` + `bat` でファイルを探す。Enter: 開く/移動、Ctrl+E: 実行 | fd, fzf, bat, code（任意） |
| `gwt` | `git worktree` の一覧を fzf で選んで移動する。Enter: 移動、Ctrl+E: VS Code で開く | git, fzf, code（任意） |
| `cpf` | `fd` + `fzf` でファイルを選んでパスをコピーする。Tab: 複数選択 | fd, fzf, bat |
