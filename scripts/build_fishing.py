#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_fishing.py — Teamcraft fishing-spots.json + fish-parameter.json
                    + 繁中 datamining 的 PlaceName → fishing.json

由 build_data.py 呼叫,不單獨執行。

反向索引:item_id -> 釣魚採集點清單(精簡資訊,無 bait/時段/天氣細節)。
詳細釣法由 UI 提供「查看完整釣法 →」外連到 Teamcraft。
"""
import json

from datamining import Sheet, load_class_jobs, source_meta, write_json

# 釣魚(用釣竿)在 GatheringType 沒有對應的列(4、5 是刺魚),採集方式維持寫死。
FISHING_METHOD = '釣魚'

SPOTS_PATH = 'libs/data/src/lib/json/fishing-spots.json'
PARAMS_PATH = 'libs/data/src/lib/json/fish-parameter.json'


def load_place_names(sheet):
    """PlaceName -> { placeId(str): 繁中地名 }"""
    return {place_id: name.strip() for place_id, name in sheet.records('#', 'Name')
            if place_id.strip()}


def load_fisher_name(sheet):
    """漁師的繁中服官方名稱。ClassJob 沒有 FSH 時結束程式。"""
    for job in load_class_jobs(sheet).values():
        if job['abbreviation'] == 'FSH' and job['name']:
            return job['name']
    raise SystemExit(f'{sheet.name}: 找不到漁師(FSH)')


def build(tc_files, teamcraft_files, item_ids, sources, out_path):
    """tc_files / teamcraft_files: data_sources.json 中各上游的檔案 → 本機路徑。"""
    with open(teamcraft_files[SPOTS_PATH], encoding='utf-8') as f:
        spots = json.load(f)
    with open(teamcraft_files[PARAMS_PATH], encoding='utf-8') as f:
        params = json.load(f)
    place_names = load_place_names(Sheet(tc_files['PlaceName.csv']))
    fisher_name = load_fisher_name(Sheet(tc_files['ClassJob.csv']))

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
                'job': fisher_name,
                'method': FISHING_METHOD,
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

    # Teamcraft 以國際服為準,會有繁中服尚未開放的魚
    unresolved = sorted(i for i in index if i not in item_ids)

    output = {
        '_meta': {
            'fishable_item_count': len(index),
            'fishing_spot_count': len(spots),
            'unresolved_item_ids': unresolved,
            'game_version': sources['upstreams']['ffxiv-datamining-tc']['game_version'],
            'sources': source_meta(sources, 'ffxiv-datamining-tc', 'teamcraft'),
            'note': ('key 為可釣魚道具 id(字串);值為釣魚點陣列。'
                     '不含 bait/時段/天氣細節,UI 應提供 teamcraft_url 外連。'),
        },
        'fishing': {str(k): index[k] for k in sorted(index)},
    }
    write_json(out_path, output)

    print('完成:', out_path)
    print('  可釣魚道具數:', len(index))
    print('  釣場數:', len(spots))
    print('  魚 id 對不到 items.json(警告):', len(unresolved))
