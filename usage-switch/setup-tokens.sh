#!/bin/bash
# C1/C2 トークンセットアップ（一度だけ実行）
# 1PasswordからAPIキーを取得してローカルファイルに保存します

echo "🔑 1Passwordからトークンを取得中..."

C1_TOKEN=$(op item get gndrqilk2wsril4rdeoln7xc5e --reveal --format=json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); f=next((x for x in d.get('fields',[]) if str(x.get('value','')).startswith('sk-ant')),None); print(f['value'] if f else '')")

C2_TOKEN=$(op item get zubedk7dddbjhiosyj3fho7cea --reveal --format=json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); f=next((x for x in d.get('fields',[]) if str(x.get('value','')).startswith('sk-ant')),None); print(f['value'] if f else '')")

if [ -z "$C1_TOKEN" ] || [ -z "$C2_TOKEN" ]; then
  echo "❌ トークン取得失敗。1Passwordにログイン済みか確認してください"
  exit 1
fi

# 保存
python3 -c "
import json
data = {'c1': '$C1_TOKEN', 'c2': '$C2_TOKEN'}
with open('$HOME/.openclaw/workspace/tools/usage-switch/tokens.json', 'w') as f:
    json.dump(data, f, indent=2)
print('✅ tokens.json に保存完了')
"
chmod 600 ~/.openclaw/workspace/tools/usage-switch/tokens.json
echo "✅ セットアップ完了"
