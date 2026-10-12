#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_item_shop.py — 繁中 datamining 的 Item (Price{Mid}) + GilShopItem → item_shop.json

由 build_data.py 呼叫,不單獨執行。
獨立檔案,不修改 items.json。僅收錄「有售價」或「商店有賣」的道具。
"""
from datamining import Sheet, source_meta, write_json


def build(files, sources, out_path):
    """files: data_sources.json 中 ffxiv-datamining-tc 的檔案 → 本機路徑。"""
    # 1) Item 建 id -> price_mid
    prices = {}
    for item_id, price_mid in Sheet(files['Item.csv']).records('#', 'Price{Mid}'):
        if not item_id.isdigit():
            continue
        if price_mid.isdigit() and int(price_mid) > 0:
            prices[int(item_id)] = int(price_mid)

    # 2) GilShopItem 建 set(item_id) —— 出現過就算「商店有賣」
    in_shop = set()
    for (item_id,) in Sheet(files['GilShopItem.csv']).records('Item'):
        if item_id.isdigit():
            in_shop.add(int(item_id))

    # 3) 合併:只收錄「有售價」或「在商店」的 item,其他不寫入(隱含「無資料」)
    table = {}
    for iid in sorted(set(prices) | in_shop):
        entry = {}
        if iid in prices:
            entry['price_mid'] = prices[iid]
        if iid in in_shop:
            entry['in_gil_shop'] = True
        # 若沒在商店但有 PriceMid(出售給 NPC 的賣價,非購買價),仍保留 price_mid
        # —— UI 自行判斷:只在 in_gil_shop 為 true 時才顯示為「商店購買價」
        table[str(iid)] = entry

    output = {
        '_meta': {
            'item_count': len(table),
            'priced_items': len(prices),
            'in_gil_shop_items': len(in_shop),
            'game_version': sources['upstreams']['ffxiv-datamining-tc']['game_version'],
            'sources': source_meta(sources, 'ffxiv-datamining-tc'),
            'note': ('key 為道具 id(字串)。price_mid 為 NPC 商店售價(Gil),'
                     'in_gil_shop 表示該道具確實出現在某間 GilShop。'
                     '兩者皆 optional,UI 應同時檢查:'
                     'in_gil_shop=true 時 price_mid 才視為「商店購買價」。'),
        },
        'shop': table,
    }
    write_json(out_path, output)

    print('完成:', out_path)
    print('  收錄道具數:', len(table))
    print('  有 PriceMid 的:', len(prices))
    print('  在 GilShop 有賣的:', len(in_shop))
