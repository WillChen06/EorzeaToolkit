#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_treasure_maps.py — treasure_map_definitions.json + 繁中 datamining 的 Item / Map / PlaceName
                         + Teamcraft nodes.json → treasure_maps_final.json

由 build_data.py 呼叫,不單獨執行。

- 地圖:依 scripts/treasure_map_definitions.json 的順序。名稱讀 Item;繁中資料沒有名稱的地圖
  (繁中服尚未開放)不收,列在 `_meta.unreleased_map_ids`。
- 採集點:Teamcraft 的採集點中,類型在 gathering_types、所在地圖(Map 的 PlaceName)在
  gathering_zone_ids、等級不低於地圖等級者。zone_id 用 Map 的 PlaceName,map_id 是採集點所在的
  Map(同一個 PlaceName 可能有好幾張地圖,App 開地圖要用 map_id),座標取到小數一位,
  依(類型, zone_id, x, y)排序。
- 地區名稱:收錄的地圖的 gathering_zone_ids 對到 PlaceName 的繁中名稱;找不到名稱時結束程式。
"""
import json
from pathlib import Path

from build_gathering import NODES_PATH
from datamining import Sheet, names_by_id, source_meta, to_int, write_json

DEFINITIONS_PATH = Path(__file__).resolve().parent / 'treasure_map_definitions.json'

# nodes.json type(= GatheringType id)→ App 的採集職 key(GatheringJob)。顯示文字由 App 本地化。
NODE_TYPE_JOBS = {0: 'miner', 1: 'miner', 2: 'botanist', 3: 'botanist'}


def load_map_places(sheet):
    """Map id → PlaceName id,略過沒有地名的地圖。"""
    return {to_int(map_id): to_int(place_id) for map_id, place_id in sheet.records('#', 'PlaceName')
            if map_id.strip().isdigit() and to_int(place_id) > 0}


def coordinate(value):
    """地圖座標取到小數一位;整數維持整數,與既有資料相同。"""
    return value if isinstance(value, int) else round(value, 1)


def gathering_nodes(definition, nodes, map_places):
    types = set(definition['gathering_types'])
    zones = set(definition['gathering_zone_ids'])
    unknown = sorted(types - set(NODE_TYPE_JOBS))
    if unknown:
        raise SystemExit(f"{DEFINITIONS_PATH.name}: {definition['grade']} 的採集類型 {unknown} 不是採掘、碎石、採伐或割草")

    selected = []
    for node in nodes.values():
        node_type = node.get('type')
        map_id = node.get('map', 0)
        zone_id = map_places.get(map_id)
        if node_type not in types or zone_id not in zones or node.get('level', 0) < definition['level']:
            continue
        selected.append({
            'type': node_type,
            'job': NODE_TYPE_JOBS[node_type],
            'zone_id': zone_id,
            'map_id': map_id,
            'x': coordinate(node['x']),
            'y': coordinate(node['y']),
        })
    selected.sort(key=lambda spot: (spot['type'], spot['zone_id'], spot['x'], spot['y']))
    return selected


def build(tc_files, teamcraft_files, sources, out_path):
    """tc_files / teamcraft_files: data_sources.json 中各上游的檔案 → 本機路徑。"""
    with open(DEFINITIONS_PATH, encoding='utf-8') as f:
        definitions = json.load(f)['maps']
    with open(teamcraft_files[NODES_PATH], encoding='utf-8') as f:
        nodes = json.load(f)
    item_names = names_by_id(Sheet(tc_files['Item.csv']))
    map_places = load_map_places(Sheet(tc_files['Map.csv']))
    place_names = names_by_id(Sheet(tc_files['PlaceName.csv']))

    maps = []
    unreleased = []
    for definition in definitions:
        name = item_names.get(definition['item_id'])
        if not name:
            unreleased.append(definition['id'])
            continue
        maps.append({
            'id': definition['id'],
            'item_id': definition['item_id'],
            'grade': definition['grade'],
            'name_tw': name,
            'level': definition['level'],
            'expansion': definition['expansion'],
            'type': definition['type'],
            'max_party_size': definition['max_party_size'],
            'gathering_types': definition['gathering_types'],
            'gathering_zone_ids': definition['gathering_zone_ids'],
            'gathering_nodes': gathering_nodes(definition, nodes, map_places),
        })

    zone_ids = sorted({zone_id for entry in maps for zone_id in entry['gathering_zone_ids']})
    missing = [zone_id for zone_id in zone_ids if not place_names.get(zone_id)]
    if missing:
        raise SystemExit(f'PlaceName.csv: 找不到採集區域 {missing} 的名稱')

    output = {
        '_meta': {
            'map_count': len(maps),
            'unreleased_map_ids': unreleased,
            'game_version': sources['upstreams']['ffxiv-datamining-tc']['game_version'],
            'sources': source_meta(sources, 'ffxiv-datamining-tc', 'teamcraft'),
            'note': ('地圖定義(等級、採集類型、採集區域等)來自 scripts/treasure_map_definitions.json;'
                     '繁中服尚未開放的地圖列在 unreleased_map_ids。zone_names 的 key 為 PlaceName id。'),
        },
        'maps': maps,
        'zone_names': {str(zone_id): {'tw': place_names[zone_id]} for zone_id in zone_ids},
    }
    write_json(out_path, output)

    print('完成:', out_path)
    print('  地圖 / 採集點:', len(maps), '/', sum(len(entry['gathering_nodes']) for entry in maps))
    print('  繁中服尚未開放:', unreleased)
