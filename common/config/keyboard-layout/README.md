# keyboard-layout 設定

`scripts/darwin/keyboard-layout.ts` が使う設定。`~/.config/keyboard-layout/config.json` に
symlink して使う（共通設定。マシンごとに変えたい部分は `config.local.json` に書く）。

設計は [docs/ADR/20261014-010329-keyboard-layout-auto-switching.md](../../ADR/20261014-010329-keyboard-layout-auto-switching.md) を参照。

## インストール

`install.sh` から `scripts/darwin/install-keyboard-layout.sh` が呼ばれる。単体でも実行できる。

```sh
# 全部入りで実行（LaunchAgent も登録する。登録直後に初回 sync が走る）
scripts/darwin/install-keyboard-layout.sh

# ファイルの用意とビルドまで（LaunchAgent は登録しない）
scripts/darwin/install-keyboard-layout.sh --skip-agent
```

| もの | 場所 |
| --- | --- |
| CLI（TypeScript 本体） | `scripts/darwin/keyboard-layout.ts` |
| CLI（コンパイル済み） | `scripts/darwin/bin/keyboard-layout`（gitignore 対象） |
| 監視デーモ（Swift） | `scripts/darwin/KeyboardWatcher.swift` |
| 監視デーモ（コンパイル済み） | `scripts/darwin/bin/keyboard-watcher`（gitignore 対象） |
| LaunchAgent | `~/Library/LaunchAgents/local.keyboard-layout.plist` |
| 状態（唯一の真実） | `~/.local/state/keyboard-layout/state.json` |
| ログ | `~/Library/Logs/keyboard-layout.log` |

手元でビルド・再読み込みする場合:

```sh
cd ~/ghq/github.com/hagatasdelus/dotfiles
scripts/darwin/install-keyboard-layout.sh            # 作り直して登録し直す
tail -f ~/Library/Logs/keyboard-layout.log           # デーモのログ
launchctl kickstart -k gui/$(id -u)/local.keyboard-layout   # デーモ再起動
```

## コマンド

| コマンド | 役割 |
| --- | --- |
| `keyboard-layout resolve` | 接続デバイスからレイアウトを導出する（副作用なし） |
| `keyboard-layout status` | 現在の state.json と、今の接続デバイスからの導出結果 |
| `keyboard-layout sync` | 導出 → 適用 → state.json 書き込み |
| `keyboard-layout set US` | 手動で US に固定する（`pinned`） |
| `keyboard-layout toggle` | US/JIS を入れ替える（`pinned`） |
| `keyboard-layout auto` | 手動固定を解除してデバイス同期に戻す |
| `keyboard-layout select` | fzf で Karabiner プロファイルを選ぶ |
| `keyboard-layout run` | デーモが無い環境向けのポーリング（2 秒） |

`--dry-run` を付けると適用せず結果だけ返す。`--json` を付けると state.json 相当の JSON を返す。

## キー割り当て

| キー | 動作 |
| --- | --- |
| herdr `prefix+shift+k` | `toggle`（即時・通知のみ） |
| herdr `prefix+ctrl+k` | `select`（fzf ピッカー） |
| Neovim `<Leader>kl` | `toggle`（CLI 経由） |
| Neovim `<Leader>kL` / `:KeyboardLayoutSync` | 再解決（保険） |
| Neovim `:KeyboardLayoutToggle` | `toggle` |

## スキーマ

| キー | 説明 |
| --- | --- |
| `default_layout` | どのデバイスにも一致しなかったときに使うレイアウト id |
| `layouts` | レイアウト id → 適用先（Karabiner プロファイル / macSKK キーバインドセット / Neovim の AZIK テーブル） |
| `devices` | マッチャの配列。**上から順に**評価し、最初に一致したものが採用される（同時接続時のフォールバック順） |

`devices` の各要素:

| キー | 説明 |
| --- | --- |
| `label` | 表示用の名前（`status` の出力にしか出ない） |
| `layout` | 一致したときに採用するレイアウト id |
| `match` | 一致条件（下記） |
| `note` | 自分用メモ |

`match` は AND 条件。指定しなかったキーは判定に使わない。

| キー | 型 | 説明 |
| --- | --- | --- |
| `vendor_id` | number | VID（`karabiner_cli` / `ioreg` の十進表記） |
| `product_id` | number | PID（同上） |
| `is_built_in` | boolean | 内蔵キーボードかどうか |
| `transport` | string | `"usb"` / `"bluetooth"` / `"spi"` など（小文字で比較） |
| `country_code` | number | HID の CountryCode。`15` が Japan |
| `product_contains` | string | 製品名の部分一致（大文字小文字は無視） |

VID/PID は `keyboard-layout resolve` の `unregistered:` 行、あるいは以下で確認できる。

```sh
karabiner_cli --list-connected-devices
```

## レイアウト決定の優先順位

1. `mode: pinned`（手動で `toggle` / `set` した状態）→ そのレイアウト
2. **最後に接続された**外付けの登録済みデバイス → そのデバイスのレイアウト
   （macOS は取り付け時刻を公開しないため、接続履歴は state.json で保持している）
3. `devices` の宣言順で「いずれかの接続デバイスに一致」したもの → そのレイアウト
4. `default_layout`

内蔵キーボードは「最後に挿した」ではないので履歴対象外。内蔵キーボードと Karabiner の
仮想キーボードの appear / terminate は完全に無視する（SPI はスリープ等で発火しうるため）。
未登録の外付けキーボードは JIS（`default_layout`）のままで、通知と
`keyboard-layout resolve` の `unregistered:` 行に出る。

## 通知と state.json の書き換え

状態が**実際に変わったときだけ** macOS 通知を出し、state.json を書き換える。比較は
起動理由（`source`）と時刻を除いたフィンガープリントで行うので、デーモの定期実行
（reconcile）では何も出ない。コンソールには `no change: <layout>` とだけ出る。

| きっかけ | 通知 |
| --- | --- |
| デバイス着脱でレイアウトが変わった | 出る |
| 手動トグル / プロファイル選択 | 出る |
| 未登録キーボードを挿した | 出る（未登録デバイス名つき） |
| reconcile で変化なし | 出ない |
| 起動直後で既に正しい状態 | 出ない |

デーモ側でも、接続デバイスの一覧が変わっていなければ CLI を起こさないので、
reconcile のコストはデバイス列挙だけになる。間隔は `KEYBOARD_LAYOUT_RECONCILE_SECONDS`
（既定 30 秒）で変更できる。

## reconcile はなぜ必要か

イベントを取りこぼす可能性があるため。具体的には:

1. **Bluetooth キーボード** — USB と違って terminate が確実に飛ぶ保証が弱い
   （ホスト/キーボードのスリープ、ペアリング状態の変化）
2. **スリープ中の着脱** — 寝ている間にハブが再列挙したり切断したりしうる
3. **デーモ未起動期間** — ログイン前に挿した、Karabiner より先に起動した、クラッシュ後の空白
4. **適用失敗の再試行** — `--select-profile` が Karabiner 起動前に失敗した場合など

一覧が変わっていなければ CLI を起こさないので、あっても無料である。

## config.local.json

マシンごとの差分。`~/.config/keyboard-layout/config.local.json`（dotfiles 管理外）に置くと
`config.json` に再帰マージされる。配列はまるごと置き換わるので、`devices` だけ書き換えたい
場合は丸ごと書く。

例（Mac mini など内蔵キーボードが無い / 内蔵が US 配列のマシン）:

```json
{
  "default_layout": "US",
  "devices": [
    { "label": "内蔵 US キーボード", "layout": "US", "match": { "vendor_id": 1452, "is_built_in": true } }
  ]
}
```

## 新しい US キーボードを追加する

1. キーボードを挿して `keyboard-layout resolve` を実行する
2. `unregistered:` 行の `vendor_id/product_id` をコピーして `config.json` の `devices` に
   追加する（先頭ほど強い）
3. `keyboard-layout sync` で即時反映

## テスト

```sh
bun test scripts/darwin/tests/
```

Neovim 側の state.json 監視（`plugins/skkeleton/keyboard_layout.lua`）の検証:

```sh
DOTFILES_DIR=~/ghq/github.com/hagatasdelus/dotfiles \
XDG_STATE_HOME=$(mktemp -d) \
nvim --headless --clean -c "luafile scripts/darwin/tests/keyboard_layout_nvim_test.lua"
```
