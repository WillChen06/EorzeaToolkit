#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_data.py — 從 scripts/data_sources.json 鎖定的上游,重新產出全部道具相關資料檔。

1. 下載上游檔案(只抓需要的檔案,已下載的不重抓),見 fetch_sources.py
2. 產出 items / recipes / item_shop / gathering / fishing 到 EorzeaToolkit/Resources/Data
3. 產出遠端用的道具檔與 manifest.json 到 build/remote-data/,上傳到 Cloudflare Worker 仍是手動
4. 跑 validate_data.py

同一份 data_sources.json 每次產出的檔案逐 byte 相同。
只需要 Python 3.9 以上的標準函式庫。

用法:
    python3 scripts/build_data.py
"""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

import build_battle_actions
import build_fishing
import build_gathering
import build_item_shop
import build_items
import build_recipes
import fetch_sources
from datamining import data_version

SCRIPTS_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPTS_DIR.parent
DATA_DIR = REPO_ROOT / 'EorzeaToolkit' / 'Resources' / 'Data'
REMOTE_DIR = REPO_ROOT / 'build' / 'remote-data'

NOTICES = [
    'Unofficial community data distribution for EorzeaToolkit.',
    'FINAL FANTASY is a registered trademark of Square Enix Holdings Co., Ltd.',
    'FINAL FANTASY XIV © SQUARE ENIX CO., LTD.',
]


def write_remote(items_data, version):
    """遠端道具檔與內建 items.json 同內容;manifest 只含可重現的欄位(不寫產出時間)。"""
    REMOTE_DIR.mkdir(parents=True, exist_ok=True)
    items_name = f'items-{version}.json'
    (REMOTE_DIR / items_name).write_bytes(items_data)

    manifest = {
        'version': version,
        'itemsURL': f'/{items_name}',
        'items': {
            'sha256': hashlib.sha256(items_data).hexdigest(),
            'byteSize': len(items_data),
        },
        'notices': NOTICES,
    }
    manifest_text = json.dumps(manifest, ensure_ascii=False, indent=2) + '\n'
    (REMOTE_DIR / 'manifest.json').write_text(manifest_text, encoding='utf-8')
    print('完成:', REMOTE_DIR / items_name)
    print('完成:', REMOTE_DIR / 'manifest.json')


def main():
    sources = fetch_sources.load_sources()
    files = fetch_sources.fetch_all(sources)
    tc_files = files['ffxiv-datamining-tc']
    teamcraft_files = files['teamcraft']

    item_ids, items_data = build_items.build(tc_files, sources, DATA_DIR / 'items.json')
    build_recipes.build(tc_files, item_ids, sources, DATA_DIR / 'recipes.json')
    build_item_shop.build(tc_files, sources, DATA_DIR / 'item_shop.json')
    build_gathering.build(tc_files, teamcraft_files, item_ids, sources, DATA_DIR / 'gathering.json')
    build_fishing.build(tc_files, teamcraft_files, item_ids, sources, DATA_DIR / 'fishing.json')
    build_battle_actions.build(tc_files, sources, DATA_DIR / 'battle_actions.json')
    write_remote(items_data, data_version(sources))

    return subprocess.call([sys.executable, str(SCRIPTS_DIR / 'validate_data.py')])


if __name__ == '__main__':
    sys.exit(main())
