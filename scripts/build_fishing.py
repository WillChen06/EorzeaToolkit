#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_fishing.py — Teamcraft fishing-spots.json + fish-parameter.json
                    + PlaceName.csv → fishing.json

反向索引:item_id -> 釣魚採集點清單(精簡資訊,無 bait/時段/天氣細節)。
詳細釣法由 UI 提供「查看完整釣法 →」外連到 Teamcraft。

用法:
  python3 build_fishing.py fishing-spots.json fish-parameter.json \\
                            PlaceName.csv items-xxxx.json fishing.json
"""
import csv, json, sys
import opencc

cc = opencc.OpenCC('s2t')


def load_place_names(path):
    rows = list(csv.reader(open(path, encoding='utf-8-sig')))
    names = {}
    for r in rows[3:]:
        if not r or not r[0].strip():
            continue
        zid = r[0]
        cn = r[1] if len(r) > 1 else ''
        names[zid] = cc.convert(cn) if cn.strip() else ''
    return names


def load_item_ids(path):
    d = json.load(open(path, encoding='utf-8'))
    return set(it['id'] for it in d['items'])


def build(spots_path, params_path, place_path, items_path, out_path):
    spots = json.load(open(spots_path, encoding='utf-8'))
    params = json.load(open(params_path, encoding='utf-8'))
    place_names = load_place_names(place_path)
    item_ids = load_item_ids(items_path)

    # 建 itemId -> fish-parameter 紀錄
    # fish-parameter key 是 fish 自身 id(非 item_id),value.itemId 才是 item_id
    fp_by_item = {}
    for v in params.values():
        if isinstance(v, dict) and 'itemId' in v:
            fp_by_item[v['itemId']] = v

    # item_id -> [釣魚點]
    index = {}

    for spot in spots:
        place_id = str(spot.get('placeId', ''))
        zone_name = place_names.get(place_id, '')
        coords = spot.get('coords') or {}
        spot_level = spot.get('level', 0)

        for fish_item_id in spot.get('fishes', []):
            fp = fp_by_item.get(fish_item_id, {})

            point = {
                'job': '漁師',
                'method': '釣魚',
                # 魚自身的 fp.level 比釣場 level 更準(同釣場可有不同等級的魚)
                'level': fp.get('level') or spot_level,
                'stars': fp.get('stars', 0),
                'zone_id': spot.get('placeId', 0),
                'zone_name': zone_name,
                'x': coords.get('x', 0),
                'y': coords.get('y', 0),
                'map_id': spot.get('mapId', 0),
                # 詳細釣法在 Teamcraft;布林標記讓玩家知道有條件存在
                'is_timed': bool(fp.get('timed', 0)),
                'is_weathered': bool(fp.get('weathered', 0)),
                'has_folklore': bool(fp.get('folklore', 0)),
                # Teamcraft 該魚的 DB 頁面外連
                'teamcraft_url': f'https://ffxivteamcraft.com/db/zh/item/{fish_item_id}',
            }
            index.setdefault(fish_item_id, []).append(point)

    # 依等級 → zone_id 排序,顯示穩定
    for iid in index:
        index[iid].sort(key=lambda p: (p['level'], p['zone_id']))

    unresolved = sorted(i for i in index if i not in item_ids)

    output = {
        '_meta': {
            'source': ('ffxiv-teamcraft fishing-spots.json + fish-parameter.json '
                       '+ ffxiv-datamining-cn PlaceName.csv'),
            'fishable_item_count': len(index),
            'fishing_spot_count': len(spots),
            'unresolved_item_ids': unresolved,
            'note': ('key 為可釣魚道具 id(字串);值為釣魚點陣列。'
                     '不含 bait/時段/天氣細節,UI 應提供 teamcraft_url 外連。'),
        },
        'fishing': {str(k): v for k, v in index.items()},
    }
    json.dump(output, open(out_path, 'w', encoding='utf-8'),
              ensure_ascii=False, separators=(',', ':'))
    print('完成:', out_path)
    print('  可釣魚道具數:', len(index))
    print('  釣場數:', len(spots))
    print('  魚 id 對不到 items.json(警告):', len(unresolved))


if __name__ == '__main__':
    if len(sys.argv) != 6:
        print(__doc__)
        sys.exit(1)
    build(*sys.argv[1:6])
