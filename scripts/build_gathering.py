#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_gathering.py — Teamcraft nodes.json + 繁中 datamining 的 PlaceName → gathering.json

由 build_data.py 呼叫,不單獨執行。

反向索引：item_id -> 採集點清單。
- 濾除 type 5（釣魚）—— Phase C 不做釣魚
- zoneid 經 PlaceName 對到繁中服官方地名
- hiddenItems 一併納入，以 is_hidden 旗標區分
"""
import json

from datamining import Sheet, load_class_jobs, source_meta, write_json

NODES_PATH = 'libs/data/src/lib/json/nodes.json'

# nodes.json type -> 採集職縮寫(名稱讀 ClassJob)。type 5 = 釣魚，轉檔時濾除不會進到這裡
NODE_TYPE_JOBS = {0: 'MIN', 1: 'MIN', 2: 'BTN', 3: 'BTN'}
# nodes.json type -> 採集方式
NODE_TYPE_METHODS = {0: "採掘", 1: "碎屑採集", 2: "伐木", 3: "採伐"}
FISHING_TYPE = 5  # 濾除


def load_gatherer_names(sheet):
    """採集職縮寫 → 繁中服官方名稱。ClassJob 缺少採集職時結束程式。"""
    names = {job['abbreviation']: job['name'] for job in load_class_jobs(sheet).values()}
    missing = sorted({abbr for abbr in NODE_TYPE_JOBS.values() if not names.get(abbr)})
    if missing:
        raise SystemExit(f'{sheet.name}: 找不到採集職 {missing}')
    return names


def load_place_names(sheet):
    """PlaceName -> { zoneid(str): 繁中地名 }"""
    return {place_id: name.strip() for place_id, name in sheet.records('#', 'Name')
            if place_id.strip()}


def build(tc_files, teamcraft_files, item_ids, sources, out_path):
    """tc_files / teamcraft_files: data_sources.json 中各上游的檔案 → 本機路徑。"""
    with open(teamcraft_files[NODES_PATH], encoding='utf-8') as f:
        nodes = json.load(f)
    place_names = load_place_names(Sheet(tc_files['PlaceName.csv']))
    gatherer_names = load_gatherer_names(Sheet(tc_files['ClassJob.csv']))

    # item_id -> list[採集點]
    index = {}
    skipped_fishing = 0
    skipped_no_type = 0

    def add(item_id, node, is_hidden):
        t = node.get('type')
        if t not in NODE_TYPE_JOBS:
            return  # 理論上 type 5 已先濾除，其餘未知 type 跳過
        zid = str(node.get('zoneid', ''))
        spot = {
            'job': gatherer_names[NODE_TYPE_JOBS[t]],
            'method': NODE_TYPE_METHODS[t],
            'level': node.get('level', 0),
            'zone_id': node.get('zoneid', 0),
            'zone_name': place_names.get(zid, ''),
            # 座標：x/y 為地圖座標；z 多為 0，保留但 UI 可忽略
            'x': node.get('x', 0),
            'y': node.get('y', 0),
            'map_id': node.get('map', 0),
            'is_hidden': is_hidden,             # 隱藏道具（需特定條件才採得到）
            'is_legendary': node.get('legendary', False),  # 傳說採集點
            'is_ephemeral': node.get('ephemeral', False),  # 時限採集點
            'is_limited': node.get('limited', False),      # 限時出現
            # 限時點出現的 ET 時段（spawns）與持續時間；非限時點為空 / 0
            'spawns': node.get('spawns', []),
            'duration': node.get('duration', 0),
        }
        index.setdefault(item_id, []).append(spot)

    for node in nodes.values():
        t = node.get('type')
        if t == FISHING_TYPE:
            skipped_fishing += 1
            continue
        if t not in NODE_TYPE_JOBS:
            skipped_no_type += 1
            continue
        for iid in node.get('items', []):
            add(iid, node, is_hidden=False)
        for iid in node.get('hiddenItems', []):
            add(iid, node, is_hidden=True)

    # 每個道具的採集點依等級排序，顯示穩定
    for iid in index:
        index[iid].sort(key=lambda s: (s['level'], s['zone_id']))

    # 標記哪些採集到的 item_id 對不到 items.json（Teamcraft 以國際服為準，會有繁中服尚未開放的道具）
    unresolved = sorted(i for i in index if i not in item_ids)

    output = {
        '_meta': {
            'gatherable_item_count': len(index),
            'fishing_nodes_excluded': skipped_fishing,
            'unresolved_item_ids': unresolved,
            'game_version': sources['upstreams']['ffxiv-datamining-tc']['game_version'],
            'sources': source_meta(sources, 'ffxiv-datamining-tc', 'teamcraft'),
            'note': 'key 為可採集道具 id（字串）；值為採集點陣列。釣魚(type 5)已排除。',
        },
        'gathering': {str(k): index[k] for k in sorted(index)},
    }
    write_json(out_path, output)

    print('完成:', out_path)
    print('  可採集道具數:', output['_meta']['gatherable_item_count'])
    print('  濾除釣魚 node:', skipped_fishing)
    print('  未知 type node(略過):', skipped_no_type)
    print('  採集 item 對不到 items.json:', len(unresolved))
