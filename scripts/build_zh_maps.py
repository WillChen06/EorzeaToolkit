#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_zh_maps.py — 繁中 datamining 的 Map / PlaceName → zh-maps.json

由 build_data.py 呼叫,不單獨執行。

key 為 Map id(字串),值為該地圖 PlaceName 的繁中名稱。沒有地名的地圖(繁中服尚未開放的地圖
PlaceName 為 0)不收。藏寶圖頁以 treasures.json 的地圖 id 查這份檔案取得地區名稱。
"""
from build_treasure_maps import load_map_places
from datamining import Sheet, names_by_id, source_meta, write_json


def build(tc_files, sources, out_path):
    """tc_files: data_sources.json 中 ffxiv-datamining-tc 的檔案 → 本機路徑。"""
    map_places = load_map_places(Sheet(tc_files['Map.csv']))
    place_names = names_by_id(Sheet(tc_files['PlaceName.csv']))

    names = {map_id: place_names[place_id] for map_id, place_id in map_places.items()
             if place_names.get(place_id)}

    output = {
        '_meta': {
            'map_count': len(names),
            'game_version': sources['upstreams']['ffxiv-datamining-tc']['game_version'],
            'sources': source_meta(sources, 'ffxiv-datamining-tc'),
            'note': 'key 為 Map id(字串),zh 為該地圖 PlaceName 的繁中名稱;沒有地名的地圖不收。',
        },
    }
    output.update({str(map_id): {'zh': names[map_id]} for map_id in sorted(names)})
    write_json(out_path, output)

    print('完成:', out_path)
    print('  地圖數:', len(names))
