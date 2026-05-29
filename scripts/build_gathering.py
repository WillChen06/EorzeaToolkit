#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_gathering.py — 將 nodes.json + PlaceName.csv 轉成 gathering.json

反向索引：item_id -> 採集點清單。
- 濾除 type 5（釣魚）—— Phase C 不做釣魚
- zoneid 經 PlaceName.csv + OpenCC s2t 轉繁中地名
- hiddenItems 一併納入，以 is_hidden 旗標區分

用法:
    python3 build_gathering.py nodes.json PlaceName.csv items-xxxx.json gathering.json
"""
import csv, json, sys
import opencc

# nodes.json type -> 採集職業（繁中）。type 5 = 釣魚，轉檔時濾除不會進到這裡
NODE_TYPE = {
    0: {"job": "礦工", "method": "採掘"},
    1: {"job": "礦工", "method": "碎屑採集"},
    2: {"job": "園藝工", "method": "伐木"},
    3: {"job": "園藝工", "method": "採伐"},
}
FISHING_TYPE = 5  # 濾除

cc = opencc.OpenCC('s2t')


def load_place_names(path):
    """PlaceName.csv -> { zoneid(str): 繁中地名 }，經 OpenCC s2t"""
    with open(path, encoding='utf-8-sig') as f:
        rows = list(csv.reader(f))
    names = {}
    for r in rows[3:]:
        if not r or not r[0].strip():
            continue
        zid = r[0]
        cn = r[1] if len(r) > 1 else ''
        names[zid] = cc.convert(cn) if cn.strip() else ''
    return names


def load_item_ids(path):
    with open(path, encoding='utf-8') as f:
        d = json.load(f)
    return set(it['id'] for it in d['items'])


def build(nodes_path, place_path, items_path, out_path):
    with open(nodes_path, encoding='utf-8') as f:
        nodes = json.load(f)
    place_names = load_place_names(place_path)
    item_ids = load_item_ids(items_path)

    # item_id -> list[採集點]
    index = {}
    skipped_fishing = 0
    skipped_no_type = 0

    def add(item_id, node, is_hidden):
        t = node.get('type')
        type_info = NODE_TYPE.get(t)
        if type_info is None:
            return  # 理論上 type 5 已先濾除，其餘未知 type 跳過
        zid = str(node.get('zoneid', ''))
        spot = {
            'job': type_info['job'],
            'method': type_info['method'],
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
        if t not in NODE_TYPE:
            skipped_no_type += 1
            continue
        for iid in node.get('items', []):
            add(iid, node, is_hidden=False)
        for iid in node.get('hiddenItems', []):
            add(iid, node, is_hidden=True)

    # 每個道具的採集點依等級排序，顯示穩定
    for iid in index:
        index[iid].sort(key=lambda s: (s['level'], s['zone_id']))

    # 標記哪些採集到的 item_id 對不到 items.json（少數水晶 / 新道具）
    unresolved = sorted(i for i in index if i not in item_ids)

    output = {
        '_meta': {
            'source': 'ffxiv-teamcraft nodes.json + ffxiv-datamining-cn PlaceName.csv',
            'gatherable_item_count': len(index),
            'fishing_nodes_excluded': skipped_fishing,
            'unresolved_item_ids': unresolved,
            'note': 'key 為可採集道具 id（字串）；值為採集點陣列。釣魚(type 5)已排除。',
        },
        'gathering': {str(k): v for k, v in index.items()},
    }
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, separators=(',', ':'))

    print('完成:', out_path)
    print('  可採集道具數:', output['_meta']['gatherable_item_count'])
    print('  濾除釣魚 node:', skipped_fishing)
    print('  未知 type node(略過):', skipped_no_type)
    print('  採集 item 對不到 items.json:', len(unresolved))


if __name__ == '__main__':
    if len(sys.argv) != 5:
        print(__doc__)
        sys.exit(1)
    build(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
