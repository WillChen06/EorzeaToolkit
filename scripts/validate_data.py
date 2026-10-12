#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
validate_data.py — 檢查 EorzeaToolkit/Resources/Data 下的資料檔不變式。

這裡只放 Swift 型別表達不了的檢查。「每個檔案能不能被 app 的 model 解碼」由
EorzeaToolkitTests/BundledDataTests.swift 直接用真正的型別驗證,不在這裡重寫一份 schema。

留給這支腳本的是跨檔案、跨統計的部分:

1. 產生器寫在 `_meta` 裡的計數,要和檔案實際內容相符。
2. 產生器宣告「查不到對應道具」的 id 清單,要和實際查不到的集合完全相等。
   採集與釣魚資料來自以國際服為準的 Teamcraft,會有繁中服還沒開放的道具,
   所以「全部都要查得到」不成立;成立的是「查不到的那些,產生器有如實記錄下來」。
3. recipes 的 `resolvable` 旗標,必須等價於該材料 id 在 items.json 中存在。
4. 每個由 build_data.py 產出的檔案,`_meta` 記錄的來源 repo、commit、遊戲版本
   與 scripts/data_sources.json 一致;items.json 的 `_meta.version` 與之對應。
5. items.json 只用繁中資料:每筆道具都有 name_tw、沒有 name_cn;對照表非空、
   不含代表「無」的 id 0,且道具引用的非 0 id 都查得到。
6. 由 build_data.py 產出的檔案,任何一層都沒有 `cn` 或 `*_cn` 欄位(只用繁中資料)。
7. battle_actions.json 的技能說明已由產生器轉成純文字,不含任何 `<…>` 標記。

用法:
    python3 scripts/validate_data.py
"""
import json
import re
import sys
from pathlib import Path

SCRIPTS_DIR = Path(__file__).resolve().parent
DATA_DIR = SCRIPTS_DIR.parent / 'EorzeaToolkit/Resources/Data'
SOURCES_PATH = SCRIPTS_DIR / 'data_sources.json'

# 每個由 build_data.py 產出的檔案讀了哪些上游(data_sources.json 的 upstreams key)
FILE_UPSTREAMS = {
    'items.json': ('ffxiv-datamining-tc',),
    'recipes.json': ('ffxiv-datamining-tc',),
    'item_shop.json': ('ffxiv-datamining-tc',),
    'gathering.json': ('ffxiv-datamining-tc', 'teamcraft'),
    'fishing.json': ('ffxiv-datamining-tc', 'teamcraft'),
    'battle_actions.json': ('ffxiv-datamining-tc',),
    'treasure_maps_final.json': ('ffxiv-datamining-tc', 'teamcraft'),
    'zh-maps.json': ('ffxiv-datamining-tc',),
}

MARKUP = re.compile(r'<[^>]*>')

failures = []


def check(condition, message):
    if not condition:
        failures.append(message)


def load(name):
    with open(DATA_DIR / name, encoding='utf-8') as f:
        return json.load(f)


def check_counters(filename, data, index_key, expected):
    """`_meta` 的計數欄位 vs 實際內容。"""
    meta = data.get('_meta', {})

    for meta_key, actual in expected.items():
        if meta_key not in meta:
            failures.append(f'{filename}: _meta 缺少 {meta_key}')
            continue
        check(meta[meta_key] == actual,
              f'{filename}: _meta.{meta_key} = {meta[meta_key]},實際為 {actual}')

    non_digit = [k for k in data[index_key] if not k.isdigit()]
    check(not non_digit,
          f'{filename}: {index_key} 有非數字 key(app 用 String(itemID) 查詢): {non_digit[:5]}')


def check_unresolved(filename, meta, meta_key, actual_ids):
    """`_meta` 宣告查不到的 id 清單 vs 實際查不到的集合。"""
    if meta_key not in meta:
        failures.append(f'{filename}: _meta 缺少 {meta_key}')
        return

    declared = set(meta[meta_key])
    missing = actual_ids - declared
    stale = declared - actual_ids

    check(not missing,
          f'{filename}: 有 {len(missing)} 個 id 查不到 items.json 卻未列入 '
          f'{meta_key}: {sorted(missing)[:5]}')
    check(not stale,
          f'{filename}: {meta_key} 列了 {len(stale)} 個其實查得到的 id: {sorted(stale)[:5]}')


def check_sources(filename, meta, sources):
    """`_meta` 記錄的來源 repo、commit、遊戲版本 vs data_sources.json。"""
    upstreams = sources['upstreams']
    expected_names = FILE_UPSTREAMS[filename]
    recorded = meta.get('sources')
    if not isinstance(recorded, dict):
        failures.append(f'{filename}: _meta 缺少 sources')
        return

    check(set(recorded) == set(expected_names),
          f'{filename}: _meta.sources 應為 {sorted(expected_names)},實際為 {sorted(recorded)}')

    for name in expected_names:
        entry = recorded.get(name) or {}
        upstream = upstreams.get(name) or {}
        commit = entry.get('commit')
        check(isinstance(commit, str) and len(commit) == 40
              and all(c in '0123456789abcdef' for c in commit),
              f'{filename}: _meta.sources.{name}.commit 不是完整的 commit SHA: {commit!r}')
        check(entry.get('repo') == upstream.get('repo') and commit == upstream.get('commit'),
              f'{filename}: _meta.sources.{name} 是 {entry.get("repo")}@{commit},'
              f'data_sources.json 是 {upstream.get("repo")}@{upstream.get("commit")}')

    game_version = upstreams['ffxiv-datamining-tc']['game_version']
    check(meta.get('game_version') == game_version,
          f'{filename}: _meta.game_version = {meta.get("game_version")!r},'
          f'data_sources.json 是 {game_version!r}')


def cn_key_paths(value, path='$'):
    """value 中所有 `cn` 或 `*_cn` 欄位的路徑。"""
    if isinstance(value, dict):
        for key, child in value.items():
            child_path = f'{path}.{key}'
            if key == 'cn' or key.endswith('_cn'):
                yield child_path
            yield from cn_key_paths(child, child_path)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from cn_key_paths(child, f'{path}[{index}]')


def battle_actions(data):
    """battle_actions.json 的每個技能:(標籤, 技能),職業技能與共通技能都包含。"""
    for job in data['jobs']:
        for action in job['actions']:
            yield f"{job['abbreviation']} {action['id']}", action
    for action in data['role_actions']:
        yield f"共通技能 {action['id']}", action


def check_items(items, sources):
    """items.json 的名稱、版本與對照表。"""
    meta = items['_meta']
    upstream = sources['upstreams']['ffxiv-datamining-tc']
    expected_version = f"{upstream['game_version']}-r{sources['data_revision']}"
    check(meta.get('version') == expected_version,
          f'items.json: _meta.version = {meta.get("version")!r},應為 {expected_version!r}')

    # 只用繁中資料:每筆都要有名稱,且不再有 name_cn
    unnamed = [i['id'] for i in items['items']
               if not isinstance(i.get('name_tw'), str) or not i['name_tw'].strip()]
    check(not unnamed, f'items.json: {len(unnamed)} 筆道具沒有 name_tw: {unnamed[:5]}')
    with_cn = [i['id'] for i in items['items'] if 'name_cn' in i]
    check(not with_cn, f'items.json: {len(with_cn)} 筆道具仍有 name_cn: {with_cn[:5]}')

    # 對照表:非空、id 唯一、不含代表「無」的 0,且不再有 name_cn
    references = {
        'ui_categories': 'ui_category_id',
        'classjob_categories': 'classjob_category_id',
        'equip_slots': 'equip_slot',
    }
    for table_key, item_key in references.items():
        table = items.get(table_key)
        if not isinstance(table, list) or not table:
            failures.append(f'items.json: {table_key} 不存在或是空的')
            continue

        ids = [row['id'] for row in table]
        check(len(set(ids)) == len(ids), f'items.json: {table_key} 的 id 有重複')
        check(0 not in ids, f'items.json: {table_key} 不應包含 id 0(0 代表「無」)')
        check(not any('name_cn' in row for row in table),
              f'items.json: {table_key} 仍有 name_cn')

        # 道具引用的非 0 id 都要查得到
        known = set(ids)
        dangling = sorted({i[item_key] for i in items['items']
                           if i.get(item_key, 0) != 0 and i[item_key] not in known})
        check(not dangling,
              f'items.json: 道具的 {item_key} 指向 {table_key} 沒有的 id: {dangling[:5]}')


def main():
    with open(SOURCES_PATH, encoding='utf-8') as f:
        sources = json.load(f)

    items = load('items.json')
    item_ids = {i['id'] for i in items['items']}

    check(len(item_ids) == len(items['items']),
          f"items.json: id 有重複({len(items['items'])} 筆 / {len(item_ids)} 個唯一 id)")
    check(items['_meta'].get('count') == len(items['items']),
          f"items.json: _meta.count = {items['_meta'].get('count')},"
          f"實際為 {len(items['items'])}")
    check_sources('items.json', items['_meta'], sources)
    check_items(items, sources)

    # --- item_shop.json ---
    shop_data = load('item_shop.json')
    shop = shop_data['shop']
    check_counters('item_shop.json', shop_data, 'shop', {
        'item_count': len(shop),
        'priced_items': sum(1 for v in shop.values() if 'price_mid' in v),
        'in_gil_shop_items': sum(1 for v in shop.values() if v.get('in_gil_shop')),
    })
    check_sources('item_shop.json', shop_data['_meta'], sources)

    # --- recipes.json ---
    recipe_data = load('recipes.json')
    recipes = recipe_data['recipes']
    check_counters('recipes.json', recipe_data, 'recipes', {
        'result_item_count': len(recipes),
        'recipe_count': sum(len(v) for v in recipes.values()),
    })
    check_sources('recipes.json', recipe_data['_meta'], sources)
    check_unresolved('recipes.json', recipe_data['_meta'], 'unresolved_result_ids',
                     {int(k) for k in recipes} - item_ids)

    ingredient_ids = set()
    mismatched_flags = []
    for entries in recipes.values():
        for recipe in entries:
            for ingredient in recipe['ingredients']:
                item_id = ingredient['item_id']
                ingredient_ids.add(item_id)
                if bool(ingredient.get('resolvable')) != (item_id in item_ids):
                    mismatched_flags.append(item_id)

    check(not mismatched_flags,
          f'recipes.json: {len(mismatched_flags)} 個材料的 resolvable 旗標與 items.json '
          f'不一致: {sorted(set(mismatched_flags))[:5]}')
    check_unresolved('recipes.json', recipe_data['_meta'], 'unresolved_ingredient_ids',
                     ingredient_ids - item_ids)

    # --- gathering.json ---
    gathering_data = load('gathering.json')
    gathering = gathering_data['gathering']
    check_counters('gathering.json', gathering_data, 'gathering', {
        'gatherable_item_count': len(gathering),
    })
    check_sources('gathering.json', gathering_data['_meta'], sources)
    check_unresolved('gathering.json', gathering_data['_meta'], 'unresolved_item_ids',
                     {int(k) for k in gathering} - item_ids)

    # --- fishing.json ---
    # `_meta.fishing_spot_count` 沒有被檢查:它不等於任何從輸出算得出來的數量
    # (既非不重複的 teamcraft_url,也非不重複的座標),來源語意不明,不便斷言。
    fishing_data = load('fishing.json')
    fishing = fishing_data['fishing']
    check_counters('fishing.json', fishing_data, 'fishing', {
        'fishable_item_count': len(fishing),
    })
    check_sources('fishing.json', fishing_data['_meta'], sources)
    check_unresolved('fishing.json', fishing_data['_meta'], 'unresolved_item_ids',
                     {int(k) for k in fishing} - item_ids)

    # --- battle_actions.json ---
    battle_data = load('battle_actions.json')
    check_sources('battle_actions.json', battle_data['_meta'], sources)
    with_markup = [f'{label} Lv{level}'
                   for label, action in battle_actions(battle_data)
                   for level, text in action['descriptions'].items() if MARKUP.search(text)]
    check(not with_markup,
          f'battle_actions.json: {len(with_markup)} 份技能說明仍有標記: {with_markup[:5]}')

    # --- treasure_maps_final.json ---
    treasure_data = load('treasure_maps_final.json')
    check_sources('treasure_maps_final.json', treasure_data['_meta'], sources)

    # --- zh-maps.json ---
    zh_maps = load('zh-maps.json')
    check_sources('zh-maps.json', zh_maps['_meta'], sources)

    # --- 只用繁中資料 ---
    for filename in FILE_UPSTREAMS:
        paths = list(cn_key_paths(load(filename)))
        check(not paths, f'{filename}: {len(paths)} 個簡中欄位: {paths[:5]}')

    if failures:
        print(f'資料驗證失敗({len(failures)} 項):', file=sys.stderr)
        for message in failures:
            print(f'  - {message}', file=sys.stderr)
        return 1

    print('資料驗證通過。')
    return 0


if __name__ == '__main__':
    sys.exit(main())
