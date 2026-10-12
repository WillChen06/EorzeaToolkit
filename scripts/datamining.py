#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
datamining.py — 產生器共用的工具:讀 ffxiv-datamining 格式的 CSV、寫出資料檔。

CSV 為三列表頭:第一列 key,第二列欄位名,第三列型別,資料從第四列開始。
欄位一律以第二列的名稱定位(id 欄的名稱是 `#`),不用固定 index:遊戲改版會在中間插入欄位,
固定 index 會讀到錯的欄位而不報錯。需要的欄位不存在或名稱重複時,以非 0 結束並指出欄位名。
"""
import csv
import json
import sys
from pathlib import Path


class Sheet:
    def __init__(self, path):
        self.path = Path(path)
        with open(self.path, encoding='utf-8-sig', newline='') as f:
            rows = list(csv.reader(f))
        if len(rows) < 3:
            sys.exit(f'{self.name}: 表頭少於三列,不是 datamining 格式的 CSV')
        self.header = rows[1]
        self.rows = [row for row in rows[3:] if row]

    @property
    def name(self):
        return self.path.name

    def column(self, name):
        """欄位名稱 → index。缺少或重複時結束程式。"""
        indices = [index for index, header in enumerate(self.header) if header == name]
        if not indices:
            sys.exit(f'{self.name}: 缺少欄位 {name!r}')
        if len(indices) > 1:
            sys.exit(f'{self.name}: 欄位 {name!r} 出現 {len(indices)} 次,無法判斷要讀哪一欄')
        return indices[0]

    def records(self, *names):
        """依 names 的順序,逐列回傳那幾個欄位的值(tuple of str)。"""
        indices = [self.column(name) for name in names]
        for row in self.rows:
            yield tuple(row[index] if index < len(row) else '' for index in indices)


def to_int(value, default=0):
    """CSV 字串 → int。空字串或非數字(例:GilShopItem 的 `262144.0`)回傳 default。"""
    text = value.strip()
    if text.lstrip('-').isdigit():
        return int(text)
    return default


def to_bool(value):
    return value.strip() == 'True'


def source_meta(sources, *upstream_names):
    """`_meta.sources`:這個資料檔讀了哪些上游,各自的 repo 與 commit。"""
    upstreams = sources['upstreams']
    return {
        name: {'repo': upstreams[name]['repo'], 'commit': upstreams[name]['commit']}
        for name in upstream_names
    }


def data_version(sources):
    """`<遊戲版本>-r<修訂號>`,例:2026.09.14.0000.0000-r1。"""
    game_version = sources['upstreams']['ffxiv-datamining-tc']['game_version']
    return f"{game_version}-r{sources['data_revision']}"


def write_json(path, payload):
    """寫出資料檔並回傳寫入的 bytes。

    格式與既有資料檔相同:UTF-8、不跳脫中文、無空白、結尾無換行。
    內容只取決於 payload,同樣的輸入每次產生同樣的 bytes。
    """
    data = json.dumps(payload, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return data
