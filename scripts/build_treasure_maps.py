#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_treasure_maps.py — treasure_map_definitions.json + 繁中 datamining 的 Item / TreasureHuntRank /
                         TreasureSpot / Level / Map / PlaceName + Teamcraft nodes.json → treasure_maps.json

由 build_data.py 呼叫,不單獨執行。

- 地圖:依 scripts/treasure_map_definitions.json 的順序。名稱讀 Item;繁中資料沒有名稱的地圖
  (繁中服尚未開放)不收,列在 `_meta.unreleased_map_ids`。
- 地區(zones):地圖的寶藏點所在的 Map,依 map_id 排序。地名是 Map 的 PlaceName,圖片網址與
  size_factor 也來自 Map。
- 寶藏點:ItemName 等於地圖道具的 TreasureHuntRank 列(第 N 列)底下的 TreasureSpot(key "N.M");
  Location 為 0 的佔位列不收。座標由 Level 的 X、Z(平面座標)換算成地圖座標,依 (N, M) 排序。
- 採集點:Teamcraft 的採集點中,類型在 gathering_types、所在地圖(Map 的 PlaceName)在
  gathering_zone_ids、等級不低於地圖等級者。zone_id 用 Map 的 PlaceName,map_id 是採集點所在的
  Map(同一個 PlaceName 可能有好幾張地圖),座標取到小數一位,依(類型, zone_id, x, y)排序。
  每個採集點帶著地區的繁中名稱、所在 Map 的圖片網址與 size_factor。
- 地名、圖片或 size_factor 找不到時結束程式,不輸出 fallback。
"""
import json
from decimal import ROUND_FLOOR, Decimal
from pathlib import Path

from build_gathering import NODES_PATH
from datamining import Sheet, names_by_id, source_meta, to_int, write_json

DEFINITIONS_PATH = Path(__file__).resolve().parent / 'treasure_map_definitions.json'

# nodes.json type(= GatheringType id)→ App 的採集職 key(GatheringJob)。顯示文字由 App 本地化。
NODE_TYPE_JOBS = {0: 'miner', 1: 'miner', 2: 'botanist', 3: 'botanist'}

MAP_IMAGE_URL = 'https://xivapi.com/m/{folder}/{folder}.{index}.jpg'
HUNDREDTH = Decimal('0.01')


def load_maps(sheet):
    """Map id → {'place_id', 'image', 'size_factor', 'offset_x', 'offset_y'}。

    缺少的欄位留空(place_id 0、image None、size_factor 0),由用到那張地圖的地方決定要不要失敗。
    """
    maps = {}
    for map_id, path, size_factor, offset_x, offset_y, place_id in sheet.records(
            '#', 'Id', 'SizeFactor', 'Offset{X}', 'Offset{Y}', 'PlaceName'):
        if not map_id.strip().isdigit():
            continue
        maps[to_int(map_id)] = {
            'place_id': to_int(place_id),
            'image': map_image(path),
            'size_factor': to_int(size_factor),
            'offset_x': to_int(offset_x),
            'offset_y': to_int(offset_y),
        }
    return maps


def map_image(path):
    """Map.Id(例:`f1f1/00`)→ 地圖圖片網址;格式不符時回傳 None。"""
    folder, _, index = path.strip().partition('/')
    if not folder or not index or '/' in index:
        return None
    return MAP_IMAGE_URL.format(folder=folder, index=index)


def require_map(maps, place_names, map_id, context):
    """用到的地圖:名稱、圖片、size_factor 都要有,否則結束程式。"""
    info = maps.get(map_id)
    if info is None:
        raise SystemExit(f'Map.csv: 找不到 {context} 所在的地圖 {map_id}')
    name = place_names.get(info['place_id'])
    if not name:
        raise SystemExit(f'PlaceName.csv: 找不到 {context} 所在地圖 {map_id} 的地名(PlaceName {info["place_id"]})')
    if not info['image']:
        raise SystemExit(f'Map.csv: 地圖 {map_id}({context})沒有圖片路徑')
    if info['size_factor'] <= 0:
        raise SystemExit(f'Map.csv: 地圖 {map_id}({context})的 SizeFactor 不是正數')
    return info, name


def truncate(value):
    """捨去到小數第二位(往負無限大)。現有的寶藏點座標就是這樣算出來的。"""
    return value.quantize(HUNDREDTH, rounding=ROUND_FLOOR)


def map_coordinate(raw, offset, size_factor):
    """Level 的平面座標 → 地圖座標。

    41 / (SizeFactor / 100) × ((原始座標 + Offset) × SizeFactor / 100 + 1024) / 2048 + 1
    為了重現現有資料,原始座標先捨去到小數第二位,換算結果再捨去到小數第二位。
    全程以 Decimal 計算,結果不受浮點誤差影響。
    """
    scale = Decimal(size_factor) / 100
    position = Decimal(41) / scale * ((truncate(Decimal(raw)) + offset) * scale + 1024) / 2048 + 1
    return float(truncate(position))


def spot_sort_key(spot_id):
    rank, _, index = spot_id.partition('.')
    return int(rank), int(index)


def load_spots_by_item(rank_sheet, spot_sheet):
    """藏寶圖道具 id → [(spot id, Level id)],依 (N, M) 排序。"""
    item_by_rank = {to_int(rank): to_int(item_id) for rank, item_id in rank_sheet.records('#', 'ItemName')
                    if rank.strip().isdigit()}
    spots = {}
    for key, location in spot_sheet.records('#', 'Location'):
        level_id = to_int(location)
        if level_id == 0:
            continue
        item_id = item_by_rank.get(spot_sort_key(key)[0], 0)
        if item_id:
            spots.setdefault(item_id, []).append((key.strip(), level_id))
    for entries in spots.values():
        entries.sort(key=lambda entry: spot_sort_key(entry[0]))
    return spots


def load_levels(sheet, level_ids):
    """Level id → (X, Z, Map id),只讀需要的列。X、Z 保留 CSV 的字串,換算時才轉成 Decimal。"""
    return {to_int(level_id): (x.strip(), z.strip(), to_int(map_id))
            for level_id, x, z, map_id in sheet.records('#', 'X', 'Z', 'Map')
            if to_int(level_id) in level_ids}


def treasure_zones(definition, spot_entries, levels, maps, place_names):
    grade = definition['grade']
    spots_by_map = {}
    for spot_id, level_id in spot_entries:
        level = levels.get(level_id)
        if level is None:
            raise SystemExit(f'Level.csv: 找不到 {grade} 寶藏點 {spot_id} 的位置 {level_id}')
        x, z, map_id = level
        info, _ = require_map(maps, place_names, map_id, f'{grade} 寶藏點 {spot_id}')
        spots_by_map.setdefault(map_id, []).append({
            'id': spot_id,
            'x': map_coordinate(x, info['offset_x'], info['size_factor']),
            'y': map_coordinate(z, info['offset_y'], info['size_factor']),
        })

    zones = []
    for map_id in sorted(spots_by_map):
        info, name = require_map(maps, place_names, map_id, f'{grade} 的地區')
        zones.append({
            'map_id': map_id,
            'name_tw': name,
            'image': info['image'],
            'size_factor': info['size_factor'],
            'spots': spots_by_map[map_id],
        })
    return zones


def coordinate(value):
    """地圖座標取到小數一位;整數維持整數,與既有資料相同。"""
    return value if isinstance(value, int) else round(value, 1)


def gathering_nodes(definition, nodes, maps, place_names):
    types = set(definition['gathering_types'])
    zones = set(definition['gathering_zone_ids'])
    unknown = sorted(types - set(NODE_TYPE_JOBS))
    if unknown:
        raise SystemExit(f"{DEFINITIONS_PATH.name}: {definition['grade']} 的採集類型 {unknown} 不是採掘、碎石、採伐或割草")

    selected = []
    for node in nodes.values():
        node_type = node.get('type')
        map_id = node.get('map', 0)
        zone_id = (maps.get(map_id) or {}).get('place_id')
        if node_type not in types or zone_id not in zones or node.get('level', 0) < definition['level']:
            continue
        info, name = require_map(maps, place_names, map_id, f"{definition['grade']} 的採集點")
        selected.append({
            'type': node_type,
            'job': NODE_TYPE_JOBS[node_type],
            'zone_id': zone_id,
            'map_id': map_id,
            'x': coordinate(node['x']),
            'y': coordinate(node['y']),
            'zone_name_tw': name,
            'image': info['image'],
            'size_factor': info['size_factor'],
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
    maps_by_id = load_maps(Sheet(tc_files['Map.csv']))
    place_names = names_by_id(Sheet(tc_files['PlaceName.csv']))
    spots_by_item = load_spots_by_item(Sheet(tc_files['TreasureHuntRank.csv']),
                                       Sheet(tc_files['TreasureSpot.csv']))

    released = []
    unreleased = []
    for definition in definitions:
        name = item_names.get(definition['item_id'])
        if name:
            released.append((definition, name))
        else:
            unreleased.append(definition['id'])

    level_ids = {level_id for definition, _ in released
                 for _, level_id in spots_by_item.get(definition['item_id'], [])}
    levels = load_levels(Sheet(tc_files['Level.csv']), level_ids)

    maps = []
    for definition, name in released:
        spot_entries = spots_by_item.get(definition['item_id'])
        if not spot_entries:
            raise SystemExit(f"TreasureSpot.csv: {definition['grade']}(道具 {definition['item_id']})沒有寶藏點")
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
            'zones': treasure_zones(definition, spot_entries, levels, maps_by_id, place_names),
            'gathering_nodes': gathering_nodes(definition, nodes, maps_by_id, place_names),
        })

    output = {
        '_meta': {
            'map_count': len(maps),
            'unreleased_map_ids': unreleased,
            'game_version': sources['upstreams']['ffxiv-datamining-tc']['game_version'],
            'sources': source_meta(sources, 'ffxiv-datamining-tc', 'teamcraft'),
            'note': ('地圖定義(等級、採集類型、採集區域等)來自 scripts/treasure_map_definitions.json;'
                     '繁中服尚未開放的地圖列在 unreleased_map_ids。寶藏點來自 TreasureHuntRank / '
                     'TreasureSpot / Level / Map,座標捨去到小數第二位。'),
        },
        'maps': maps,
    }
    write_json(out_path, output)

    print('完成:', out_path)
    print('  地圖 / 地區 / 寶藏點 / 採集點:', len(maps), '/',
          sum(len(entry['zones']) for entry in maps), '/',
          sum(len(zone['spots']) for entry in maps for zone in entry['zones']), '/',
          sum(len(entry['gathering_nodes']) for entry in maps))
    print('  繁中服尚未開放:', unreleased)
