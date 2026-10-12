#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_recipes.py — 繁中 datamining 的 Recipe + RecipeLevelTable → recipes.json

由 build_data.py 呼叫,不單獨執行。輸出 recipes.json 結構見檔尾說明。
"""
from datamining import Sheet, load_class_jobs, source_meta, to_int, write_json

# CraftType 數字 → 生產職縮寫。8 個工藝職；特殊值(200+/其他)沒有對應職業,craft_job 為 None。
# 職業名稱讀 ClassJob,不寫在這裡。
CRAFT_TYPE_JOBS = {
    0: 'CRP', 1: 'BSM', 2: 'ARM', 3: 'GSM',
    4: 'LTW', 5: 'WVR', 6: 'ALC', 7: 'CUL',
}

INGREDIENT_SLOTS = 8  # Item{Ingredient}[0..7] / Amount{Ingredient}[0..7]


def load_recipe_levels(sheet):
    """RecipeLevelTable → { key(int): {'level': int, 'stars': int} }"""
    table = {}
    for key, level, stars in sheet.records('#', 'ClassJobLevel', 'Stars'):
        if not key.lstrip('-').isdigit():
            continue
        table[int(key)] = {'level': to_int(level), 'stars': to_int(stars)}
    return table


def load_craft_job_names(sheet):
    """CraftType → 繁中服官方的生產職名稱。ClassJob 缺少任何一個生產職時結束程式。"""
    names_by_abbreviation = {job['abbreviation']: job['name'] for job in load_class_jobs(sheet).values()}
    missing = sorted(abbr for abbr in CRAFT_TYPE_JOBS.values() if not names_by_abbreviation.get(abbr))
    if missing:
        raise SystemExit(f'{sheet.name}: 找不到生產職 {missing}')
    return {craft_type: names_by_abbreviation[abbr] for craft_type, abbr in CRAFT_TYPE_JOBS.items()}


def build(files, item_ids, sources, out_path):
    """files: data_sources.json 中 ffxiv-datamining-tc 的檔案 → 本機路徑;item_ids: items.json 的 id。"""
    levels = load_recipe_levels(Sheet(files['RecipeLevelTable.csv']))
    craft_job_names = load_craft_job_names(Sheet(files['ClassJob.csv']))

    columns = ['Number', 'CraftType', 'RecipeLevelTable', 'Item{Result}', 'Amount{Result}']
    for slot in range(INGREDIENT_SLOTS):
        columns += [f'Item{{Ingredient}}[{slot}]', f'Amount{{Ingredient}}[{slot}]']

    # item_id(產出) → list[recipe]
    index = {}
    skipped_no_result = 0
    unresolved_results = set()
    unresolved_ingredients = set()

    for values in Sheet(files['Recipe.csv']).records(*columns):
        number, craft_type, recipe_level, result_item, result_amount = values[:5]
        ingredient_values = values[5:]

        # 跳過無產出的空列
        if result_item in ('0', ''):
            skipped_no_result += 1
            continue

        result_id = int(result_item)
        if result_id not in item_ids:
            unresolved_results.add(result_id)
            # 仍保留此配方，UI 自行處理；產出 id 對不到 items.json 屬少數新道具

        # CraftType → 職業名
        ct = int(craft_type) if craft_type.isdigit() else -1
        craft_job = craft_job_names.get(ct)  # 查不到為 None（特殊配方）

        # 製作等級 / 星數
        lvl_key = int(recipe_level) if recipe_level.isdigit() else -1
        lvl = levels.get(lvl_key, {'level': 0, 'stars': 0})

        # 材料：8 組 item/amount 交錯
        ingredients = []
        for slot in range(INGREDIENT_SLOTS):
            iv = ingredient_values[slot * 2]
            av = ingredient_values[slot * 2 + 1]
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
            'recipe_number': int(number) if number.isdigit() else 0,
            'craft_type': ct,
            'craft_job': craft_job,           # 職業名 or None
            'recipe_level': lvl['level'],     # 職業等級 0~100
            'stars': lvl['stars'],            # 星數 0~5
            'result_amount': int(result_amount) if result_amount.isdigit() else 1,
            'ingredients': ingredients,
        }
        index.setdefault(result_id, []).append(recipe)

    # 多配方依等級排序，讓 UI 顯示穩定
    for rid in index:
        index[rid].sort(key=lambda x: (x['recipe_level'], x['craft_type']))

    output = {
        '_meta': {
            'result_item_count': len(index),
            'recipe_count': sum(len(v) for v in index.values()),
            'unresolved_result_ids': sorted(unresolved_results),
            'unresolved_ingredient_ids': sorted(unresolved_ingredients),
            'game_version': sources['upstreams']['ffxiv-datamining-tc']['game_version'],
            'sources': source_meta(sources, 'ffxiv-datamining-tc'),
            'note': 'key 為產出道具 id（字串）；值為該道具的配方陣列（可多筆）',
        },
        # JSON 物件 key 必為字串；依 id 排序，輸出與 CSV 列順序無關
        'recipes': {str(k): index[k] for k in sorted(index)},
    }
    write_json(out_path, output)

    print('完成:', out_path)
    print('  產出道具數:', output['_meta']['result_item_count'])
    print('  配方總數:', output['_meta']['recipe_count'])
    print('  無產出空列(略過):', skipped_no_result)
    print('  產出 id 對不到 items.json:', len(unresolved_results))
    print('  材料 id 對不到 items.json:', len(unresolved_ingredients))


# 輸出結構:
# {
#   "_meta": {...},
#   "recipes": {
#     "<產出 item_id>": [
#       {"recipe_number", "craft_type", "craft_job", "recipe_level", "stars",
#        "result_amount", "ingredients": [{"item_id", "amount", "resolvable"}]}
#     ]
#   }
# }
