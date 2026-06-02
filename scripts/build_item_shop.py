#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_item_shop.py — 將 Item.csv (PriceMid) + GilShopItem.csv 轉成 item_shop.json

獨立檔案,不修改既有 items.json。僅收錄「有售價」或「商店有賣」的道具。

用法:
    python3 build_item_shop.py Item.csv GilShopItem.csv item_shop.json
"""
import csv, json, sys

ITEM_PRICE_MID_COL = 26  # Item.csv 欄位 Price{Mid}(已驗證)


def build(item_csv, shop_item_csv, out_path):
    # 1) Item.csv 建 id -> price_mid
    rows = list(csv.reader(open(item_csv, encoding='utf-8-sig')))
    prices = {}
    for r in rows[3:]:
        if not r or not r[0].isdigit():
            continue
        pm = r[ITEM_PRICE_MID_COL]
        if pm.isdigit() and int(pm) > 0:
            prices[int(r[0])] = int(pm)

    # 2) GilShopItem.csv 建 set(item_id) —— 出現過就算「商店有賣」
    shop_rows = list(csv.reader(open(shop_item_csv, encoding='utf-8-sig')))[3:]
    in_shop = set()
    for r in shop_rows:
        if len(r) > 1 and r[1].isdigit():
            in_shop.add(int(r[1]))

    # 3) 合併:只收錄「有售價」或「在商店」的 item,其他不寫入(隱含「無資料」)
    ids = set(prices) | in_shop
    table = {}
    for iid in ids:
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
            'source': 'ffxiv-datamining-cn Item.csv (Price{Mid}) + GilShopItem.csv',
            'item_count': len(table),
            'priced_items': len(prices),
            'in_gil_shop_items': len(in_shop),
            'note': ('key 為道具 id(字串)。price_mid 為 NPC 商店售價(Gil),'
                     'in_gil_shop 表示該道具確實出現在某間 GilShop。'
                     '兩者皆 optional,UI 應同時檢查:'
                     'in_gil_shop=true 時 price_mid 才視為「商店購買價」。'),
        },
        'shop': table,
    }
    json.dump(output, open(out_path, 'w', encoding='utf-8'),
              ensure_ascii=False, separators=(',', ':'))
    print('完成:', out_path)
    print('  收錄道具數:', len(table))
    print('  有 PriceMid 的:', len(prices))
    print('  在 GilShop 有賣的:', len(in_shop))


if __name__ == '__main__':
    if len(sys.argv) != 4:
        print(__doc__)
        sys.exit(1)
    build(sys.argv[1], sys.argv[2], sys.argv[3])
