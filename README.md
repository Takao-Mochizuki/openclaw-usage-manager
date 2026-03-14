# openclaw-usage-manager

Claude Max（Anthropic）の複数アカウント（C1/C2）の使用率をリアルタイム監視し、80%を超えたら自動切り替えするツールです。

OpenClawユーザー向け。

---

## 何ができるか

- **ダッシュボード**: `usage` コマンドで C1/C2 の使用率をブラウザで確認
- **自動切り替え**: 5時間または週間使用率が80%超えたら、もう一方のアカウントに自動切り替え
- **cronで3時間ごと監視**: ほったらかしで管理

```
C1: {5h: 7%, 7d: 43%}
C2: {5h: 4%, 7d: 69%} ← 80%超えたら自動でC1へ切り替え
```

---

## 前提条件

- [OpenClaw](https://openclaw.ai) インストール済み
- Claude Max アカウント × 2（C1/C2）
- [1Password CLI](https://developer.1password.com/docs/cli/) インストール済み（`op`コマンド）
- 1Password にAnthropicのAPIキーを保存済み

---

## セットアップ

### 1. ファイルを配置

```bash
mkdir -p ~/.openclaw/workspace/tools/usage-dashboard
mkdir -p ~/.openclaw/workspace/tools/usage-switch

cp usage-dashboard/server.mjs ~/.openclaw/workspace/tools/usage-dashboard/
cp usage-switch/check.mjs ~/.openclaw/workspace/tools/usage-switch/
cp usage-switch/setup-tokens.sh ~/.openclaw/workspace/tools/usage-switch/
chmod +x ~/.openclaw/workspace/tools/usage-switch/setup-tokens.sh
```

### 2. 1Password アイテムIDを設定

`setup-tokens.sh` と `check.mjs` の以下の変数を自分の1Password アイテムIDに書き換え:

```bash
C1_OP_ID="your-c1-item-id"   # 例: gndrqilk2wsril4rdeoln7xc5e
C2_OP_ID="your-c2-item-id"   # 例: zubedk7dddbjhiosyj3fho7cea
```

アイテムIDの確認方法:
```bash
op item list | grep -i anthropic
op item get "Anthropic C1" --format=json | jq '.id'
```

### 3. トークンセットアップ（一度だけ）

```bash
~/.openclaw/workspace/tools/usage-switch/setup-tokens.sh
```

TouchIDで認証 → `tokens.json` に保存完了。

### 4. ダッシュボードを `usage` コマンドで起動できるように

`~/.zshrc` に追加:

```bash
alias usage='lsof -ti:18800 | xargs kill -9 2>/dev/null; sleep 0.5; node ~/.openclaw/workspace/tools/usage-dashboard/server.mjs & sleep 1 && open http://localhost:18800'
```

---

## 動作確認

```bash
# 使用率確認
node ~/.openclaw/workspace/tools/usage-switch/check.mjs

# 出力例
# {"c1":{"5h":7,"7d":43,"over":false},"c2":{"5h":4,"7d":69,"over":false},"current":"C2","needSwitch":false}

# 強制切り替え（C1へ）
node -e "const fs=require('fs');const auth=JSON.parse(fs.readFileSync('/Users/sonia/.openclaw/agents/main/agent/auth-profiles.json'));const tokens=JSON.parse(fs.readFileSync('/Users/sonia/.openclaw/workspace/tools/usage-switch/tokens.json'));auth.profiles['anthropic:default'].token=tokens.c1;fs.writeFileSync('/Users/sonia/.openclaw/agents/main/agent/auth-profiles.json',JSON.stringify(auth,null,2));console.log('Switched to C1');"
openclaw gateway restart
```

---

## OpenClaw cronで自動切り替え（3時間ごと）

OpenClaw の cron に以下を設定:

```
スケジュール: 0 */3 * * * (Asia/Tokyo)
プロンプト:
  node ~/.openclaw/workspace/tools/usage-switch/check.mjs の結果を解析して、
  needSwitch: true なら gateway restart を実行し、#your-channel に通知。
  bothOver: true なら手動確認依頼を投稿。
  両方false なら無音。
```

---

## ファイル構成

```
openclaw-usage-manager/
├── usage-dashboard/
│   └── server.mjs        # ダッシュボードサーバー（ブラウザUI）
├── usage-switch/
│   ├── check.mjs          # 使用率チェック & 自動切り替え
│   └── setup-tokens.sh    # 初回セットアップ（1Password → tokens.json）
├── .gitignore             # tokens.json は除外
└── README.md
```

---

## 仕組み

1. Anthropic API に軽量リクエストを送信
2. レスポンスヘッダーの `anthropic-ratelimit-unified-5h-utilization` と `7d-utilization` を取得
3. どちらかが80%超え → `auth-profiles.json` のトークンを切り替え → `openclaw gateway restart`

---

## 注意

- `tokens.json` には APIキーが平文で入るため `.gitignore` で除外済み
- C1/C2 のリセット日が異なる場合に効果的（例: C1=金曜 / C2=火曜）
- 両方80%超えの場合は自動切り替えせず、手動対応を要求

---

## ライセンス

MIT

---

## 作者

[@5dmgmt](https://x.com/5dmgmt) — 五次元経営株式会社  
[5dmgmt.com](https://5dmgmt.com)
