#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_recipes.py — 將 Recipe.csv + RecipeLevelTable.csv 轉成 recipes.json

用法:
    python3 build_recipes.py Recipe.csv RecipeLevelTable.csv items-xxxx.json recipes.json

輸出 recipes.json 結構見檔尾說明。
"""
import csv, json, sys

# CraftType 數字 → 職業名（繁中）。8 個工藝職；特殊值(200+/其他)查不到則為 None
CRAFT_TYPE = {
    0: "木工", 1: "鍛冶", 2: "鎧甲", 3: "雕金",
    4: "製革", 5: "裁縫", 6: "鍊金", 7: "烹調",
}

# Recipe.csv 欄位 index（依三行表頭確認）
COL_NUMBER = 1            # Number（recipe 自身編號）
COL_CRAFT_TYPE = 2        # CraftType
COL_RECIPE_LEVEL = 3      # RecipeLevelTable（指向 RecipeLevelTable.csv 的 key）
COL_RESULT_ITEM = 5       # Item{Result}
COL_RESULT_AMOUNT = 6     # Amount{Result}
ING_START = 7             # Item{Ingredient}[0] 起，item/amount 交錯，共 8 組


def load_recipe_levels(path):
    """RecipeLevelTable.csv → { key(int): {'level': int, 'stars': int} }"""
    rows = list(csv.reader(open(path, encoding='utf-8-sig')))
    table = {}
    for r in rows[3:]:
        if not r or not r[0].lstrip('-').isdigit():
            continue
        key = int(r[0])
        table[key] = {
            'level': int(r[1]) if r[1].isdigit() else 0,
            'stars': int(r[2]) if r[2].lstrip('-').isdigit() else 0,
        }
    return table


def load_item_ids(path):
    """items.json → set(item_id) 用來標記材料/產出是否可解析"""
    d = json.load(open(path, encoding='utf-8'))
    return set(it['id'] for it in d['items'])


def build(recipe_path, level_path, items_path, out_path):
    levels = load_recipe_levels(level_path)
    item_ids = load_item_ids(items_path)

    rows = list(csv.reader(open(recipe_path, encoding='utf-8-sig')))
    data = rows[3:]

    # item_id(產出) → list[recipe]
    index = {}
    skipped_no_result = 0
    unresolved_results = set()
    unresolved_ingredients = set()

    for r in data:
        # 跳過無產出的空列
        if r[COL_RESULT_ITEM] in ('0', ''):
            skipped_no_result += 1
            continue

        result_id = int(r[COL_RESULT_ITEM])
        if result_id not in item_ids:
            unresolved_results.add(result_id)
            # 仍保留此配方，UI 自行處理；產出 id 對不到 items.json 屬少數新道具

        # CraftType → 職業名
        ct = int(r[COL_CRAFT_TYPE]) if r[COL_CRAFT_TYPE].isdigit() else -1
        craft_job = CRAFT_TYPE.get(ct)  # 查不到為 None（特殊配方）

        # 製作等級 / 星數
        lvl_key = int(r[COL_RECIPE_LEVEL]) if r[COL_RECIPE_LEVEL].isdigit() else -1
        lvl = levels.get(lvl_key, {'level': 0, 'stars': 0})

        # 材料：8 組 item/amount 交錯
        ingredients = []
        for i in range(8):
            item_col = ING_START + i * 2
            amt_col = item_col + 1
            iv = r[item_col]
            av = r[amt_col]
            if iv in ('0', '', '-1'):
                continue
            iid = int(iv)
            amt = int(av) if av.lstrip('-').isdigit() else 0
            if amt <= 0:
                continue
            resolvable = iid in item_ids
            if not resolvable:
                unresolved_ingredients.add(iid)
            ingredients.append({
                'item_id': iid,
                'amount': amt,
                # 材料對不到 items.json 時 UI 顯示 id、不可點擊
                'resolvable': resolvable,
            })

        recipe = {
            'recipe_number': int(r[COL_NUMBER]) if r[COL_NUMBER].isdigit() else 0,
            'craft_type': ct,
            'craft_job': craft_job,           # 職業名 or None
            'recipe_level': lvl['level'],     # 職業等級 0~100
            'stars': lvl['stars'],            # 星數 0~5
            'result_amount': int(r[COL_RESULT_AMOUNT]) if r[COL_RESULT_AMOUNT].isdigit() else 1,
            'ingredients': ingredients,
        }
        index.setdefault(result_id, []).append(recipe)

    # 多配方依等級排序，讓 UI 顯示穩定
    for rid in index:
        index[rid].sort(key=lambda x: (x['recipe_level'], x['craft_type']))

    output = {
        '_meta': {
            'source': 'ffxiv-datamining-cn Recipe.csv + RecipeLevelTable.csv',
            'result_item_count': len(index),
            'recipe_count': sum(len(v) for v in index.values()),
            'unresolved_result_ids': sorted(unresolved_results),
            'unresolved_ingredient_ids': sorted(unresolved_ingredients),
            'note': 'key 為產出道具 id（字串）；值為該道具的配方陣列（可多筆）',
        },
        # JSON 物件 key 必為字串
        'recipes': {str(k): v for k, v in index.items()},
    }

    json.dump(output, open(out_path, 'w', encoding='utf-8'),
              ensure_ascii=False, separators=(',', ':'))

    print('完成:', out_path)
    print('  產出道具數:', output['_meta']['result_item_count'])
    print('  配方總數:', output['_meta']['recipe_count'])
    print('  無產出空列(略過):', skipped_no_result)
    print('  產出 id 對不到 items.json:', len(unresolved_results))
    print('  材料 id 對不到 items.json:', len(unresolved_ingredients))


if __name__ == '__main__':
    if len(sys.argv) != 5:
        print(__doc__)
        sys.exit(1)
    build(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
