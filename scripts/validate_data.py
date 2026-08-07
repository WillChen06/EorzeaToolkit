#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
validate_data.py — 檢查 EorzeaToolkit/Resources/Data 下的資料檔不變式。

這裡只放 Swift 型別表達不了的檢查。「每個檔案能不能被 app 的 model 解碼」由
EorzeaToolkitTests/BundledDataTests.swift 直接用真正的型別驗證,不在這裡重寫一份 schema。

留給這支腳本的是跨檔案、跨統計的部分:

1. 產生器寫在 `_meta` 裡的計數,要和檔案實際內容相符。
2. 產生器宣告「查不到對應道具」的 id 清單,要和實際查不到的集合完全相等。
   items.json 的更新節奏和其他檔案不同,所以「全部都要查得到」不成立;
   成立的是「查不到的那些,產生器有如實記錄下來」。
3. recipes 的 `resolvable` 旗標,必須等價於該材料 id 在 items.json 中存在。

用法:
    python3 scripts/validate_data.py
"""
import json
import sys
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent.parent / 'EorzeaToolkit/Resources/Data'

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


def main():
    items = load('items.json')
    item_ids = {i['id'] for i in items['items']}

    check(len(item_ids) == len(items['items']),
          f"items.json: id 有重複({len(items['items'])} 筆 / {len(item_ids)} 個唯一 id)")
    check(items['_meta'].get('count') == len(items['items']),
          f"items.json: _meta.count = {items['_meta'].get('count')},"
          f"實際為 {len(items['items'])}")

    # --- item_shop.json ---
    shop_data = load('item_shop.json')
    shop = shop_data['shop']
    check_counters('item_shop.json', shop_data, 'shop', {
        'item_count': len(shop),
        'priced_items': sum(1 for v in shop.values() if 'price_mid' in v),
        'in_gil_shop_items': sum(1 for v in shop.values() if v.get('in_gil_shop')),
    })

    # --- recipes.json ---
    recipe_data = load('recipes.json')
    recipes = recipe_data['recipes']
    check_counters('recipes.json', recipe_data, 'recipes', {
        'result_item_count': len(recipes),
        'recipe_count': sum(len(v) for v in recipes.values()),
    })
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
    check_unresolved('fishing.json', fishing_data['_meta'], 'unresolved_item_ids',
                     {int(k) for k in fishing} - item_ids)

    if failures:
        print(f'資料驗證失敗({len(failures)} 項):', file=sys.stderr)
        for message in failures:
            print(f'  - {message}', file=sys.stderr)
        return 1

    print('資料驗證通過。')
    return 0


if __name__ == '__main__':
    sys.exit(main())
