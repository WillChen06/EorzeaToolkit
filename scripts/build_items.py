#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_items.py — 繁中 datamining 的 Item / ItemUICategory / ClassJobCategory /
EquipSlotCategory → items.json

由 build_data.py 呼叫,不單獨執行。

- 只收 Name 不為空的道具,名稱即繁中服官方譯名(name_tw),不再有 name_cn。
- 物品分類、職業分類、裝備部位的 id 0 代表「無」,不放進對照表。
- 裝備部位沒有名稱欄位,名稱由 EquipSlotCategory 各欄位的值推導:
  值 1 是裝備的部位,值 -1 是被占用的部位,例:13 → 主手（無法裝備副手）。
- equip_level 是 Level{Equip}:裝備或使用道具需要的等級,不是品級 Level{Item}。
"""
from datamining import Sheet, data_version, source_meta, to_bool, to_int, write_json

ICON_URL_TEMPLATE = 'https://beta.xivapi.com/api/1/asset/ui/icon/{icon_path}?format=png'
RARITY_MEANING = {
    '1': '一般 (白)',
    '2': '稀有 (綠)',
    '3': '貴重 (藍)',
    '4': '武勳 (紫)',
    '7': '紅蓮 (粉)',
}

# EquipSlotCategory 欄位 → 部位名稱。左右戒指在遊戲裡都叫「戒指」。
SLOT_NAMES = {
    'MainHand': '主手',
    'OffHand': '副手',
    'Head': '頭部',
    'Body': '身體',
    'Gloves': '手部',
    'Waist': '腰部',
    'Legs': '腿部',
    'Feet': '腳部',
    'Ears': '耳部',
    'Neck': '頸部',
    'Wrists': '腕部',
    'FingerL': '戒指',
    'FingerR': '戒指',
    'SoulCrystal': '靈魂水晶',
}


def icon_path(icon_id):
    return f'{icon_id // 1000 * 1000:06d}/{icon_id:06d}_hr1.tex'


def load_items(sheet):
    items = []
    columns = ('#', 'Name', 'Icon', 'Level{Item}', 'Rarity', 'CanBeHq', 'IsUntradable',
               'ItemUICategory', 'ClassJobCategory', 'EquipSlotCategory', 'Level{Equip}')
    for (item_id, name, icon, ilvl, rarity, can_be_hq, is_untradable,
         ui_category, classjob_category, equip_slot, equip_level) in sheet.records(*columns):
        if not name.strip():
            continue
        icon_id = to_int(icon)
        items.append({
            'id': to_int(item_id),
            'name_tw': name.strip(),
            'icon_id': icon_id,
            'icon_path': icon_path(icon_id),
            'ilvl': to_int(ilvl),
            'rarity': to_int(rarity),
            'can_be_hq': to_bool(can_be_hq),
            'is_untradable': to_bool(is_untradable),
            'ui_category_id': to_int(ui_category),
            'classjob_category_id': to_int(classjob_category),
            'equip_slot': to_int(equip_slot),
            'equip_level': to_int(equip_level),
        })
    items.sort(key=lambda item: item['id'])
    return items


def load_ui_categories(sheet):
    categories = []
    for category_id, name, order_minor, order_major in sheet.records(
            '#', 'Name', 'Order{Minor}', 'Order{Major}'):
        category_id = to_int(category_id)
        if category_id == 0 or not name.strip():
            continue
        categories.append({
            'id': category_id,
            'name_tw': name.strip(),
            'order_minor': to_int(order_minor),
            'order_major': to_int(order_major),
        })
    categories.sort(key=lambda category: category['id'])
    return categories


def load_classjob_categories(sheet):
    # 職業縮寫就是欄位名稱;依 CSV 的欄位順序,跳過 id、名稱與空白欄位
    id_column = sheet.column('#')
    name_column = sheet.column('Name')
    job_columns = [
        (index, header) for index, header in enumerate(sheet.header)
        if header.strip() and index not in (id_column, name_column)
    ]

    categories = []
    for row in sheet.rows:
        category_id = to_int(row[id_column])
        name = row[name_column].strip()
        if category_id == 0 or not name:
            continue
        jobs = [header for index, header in job_columns
                if index < len(row) and to_bool(row[index])]
        categories.append({'id': category_id, 'name_tw': name, 'jobs': jobs})
    categories.sort(key=lambda category: category['id'])
    return categories


def load_equip_slots(sheet, used_ids):
    id_column = sheet.column('#')
    slot_columns = [(index, header) for index, header in enumerate(sheet.header)
                    if header.strip() and index != id_column]
    unknown = [header for _, header in slot_columns if header not in SLOT_NAMES]
    if unknown:
        raise SystemExit(f'{sheet.name}: 對照表沒有這些部位欄位的名稱 {unknown}')

    slots = []
    for row in sheet.rows:
        slot_id = to_int(row[id_column])
        if slot_id not in used_ids:
            continue
        equipped = unique([SLOT_NAMES[header] for index, header in slot_columns
                           if to_int(row[index]) == 1])
        blocked = unique([SLOT_NAMES[header] for index, header in slot_columns
                          if to_int(row[index]) == -1])
        if not equipped:
            raise SystemExit(f'{sheet.name}: 部位 {slot_id} 有道具使用,但沒有任何值為 1 的欄位')
        name = '、'.join(equipped)
        if blocked:
            name += f"（無法裝備{'、'.join(blocked)}）"
        slots.append({'id': slot_id, 'name_tw': name})

    missing = sorted(used_ids - {slot['id'] for slot in slots})
    if missing:
        raise SystemExit(f'{sheet.name}: 找不到道具使用的部位 {missing}')
    slots.sort(key=lambda slot: slot['id'])
    return slots


def unique(names):
    result = []
    for name in names:
        if name not in result:
            result.append(name)
    return result


def build(files, sources, out_path):
    """files: data_sources.json 中 ffxiv-datamining-tc 的檔案 → 本機路徑。回傳 item id 集合。"""
    items = load_items(Sheet(files['Item.csv']))
    ui_categories = load_ui_categories(Sheet(files['ItemUICategory.csv']))
    classjob_categories = load_classjob_categories(Sheet(files['ClassJobCategory.csv']))
    used_slot_ids = {item['equip_slot'] for item in items if item['equip_slot'] != 0}
    equip_slots = load_equip_slots(Sheet(files['EquipSlotCategory.csv']), used_slot_ids)

    item_levels = [item['ilvl'] for item in items]
    output = {
        '_meta': {
            'count': len(items),
            'version': data_version(sources),
            'game_version': sources['upstreams']['ffxiv-datamining-tc']['game_version'],
            'sources': source_meta(sources, 'ffxiv-datamining-tc'),
            'icon_url_template': ICON_URL_TEMPLATE,
            'rarity_meaning': RARITY_MEANING,
            'ilvl_range': {'min': min(item_levels), 'max': max(item_levels)},
        },
        'items': items,
        'ui_categories': ui_categories,
        'classjob_categories': classjob_categories,
        'equip_slots': equip_slots,
    }
    data = write_json(out_path, output)

    print('完成:', out_path)
    print('  道具數:', len(items))
    print('  物品分類 / 職業分類 / 裝備部位:',
          len(ui_categories), '/', len(classjob_categories), '/', len(equip_slots))
    return {item['id'] for item in items}, data
