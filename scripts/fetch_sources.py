#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fetch_sources.py — 依 scripts/data_sources.json 鎖定的 commit,下載產生器需要的上游檔案。

只下載 data_sources.json 列出的檔案,不 clone 整個 repo。檔案放在
build/data-sources/<repo>/<commit>/<path>(build/ 已在 .gitignore)。
已經下載過的檔案不再重抓:同一個 commit 的內容不會變。
要放在其他位置時,設定環境變數 EORZEA_DATA_CACHE_DIR。

用法:
    python3 scripts/fetch_sources.py
"""
import json
import os
import re
import shutil
import sys
import tempfile
import urllib.parse
import urllib.request
from pathlib import Path

SCRIPTS_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPTS_DIR.parent
SOURCES_PATH = SCRIPTS_DIR / 'data_sources.json'
RAW_URL = 'https://raw.githubusercontent.com/{repo}/{commit}/{path}'
COMMIT_PATTERN = re.compile(r'[0-9a-f]{40}')


def load_sources():
    with open(SOURCES_PATH, encoding='utf-8') as f:
        return json.load(f)


def cache_root():
    override = os.environ.get('EORZEA_DATA_CACHE_DIR')
    if override:
        return Path(override)
    return REPO_ROOT / 'build' / 'data-sources'


def fetch_all(sources):
    """下載所有上游檔案,回傳 {upstream 名稱: {檔案路徑: 本機 Path}}。"""
    result = {}
    for name, upstream in sources['upstreams'].items():
        repo = upstream['repo']
        commit = upstream['commit']
        if not COMMIT_PATTERN.fullmatch(commit):
            sys.exit(f'data_sources.json: {name} 的 commit 必須是 40 位小寫 SHA,目前是 {commit!r}')

        base = cache_root() / repo / commit
        paths = {}
        for relative_path in upstream['files']:
            destination = base / relative_path
            if not destination.exists():
                url = RAW_URL.format(repo=repo, commit=commit,
                                     path=urllib.parse.quote(relative_path))
                download(url, destination)
            paths[relative_path] = destination
        result[name] = paths
    return result


def download(url, destination):
    destination.parent.mkdir(parents=True, exist_ok=True)
    print('下載', url)
    # 先寫到同目錄的暫存檔再改名,中斷時不會留下半個檔案被當成快取
    fd, temporary_path = tempfile.mkstemp(dir=destination.parent, prefix='.download-')
    try:
        with os.fdopen(fd, 'wb') as output, urllib.request.urlopen(url, timeout=300) as response:
            shutil.copyfileobj(response, output)
        os.replace(temporary_path, destination)
    except Exception as error:
        if os.path.exists(temporary_path):
            os.remove(temporary_path)
        sys.exit(f'下載失敗:{url}\n{error}')


if __name__ == '__main__':
    for upstream_name, files in fetch_all(load_sources()).items():
        print(f'{upstream_name}: {len(files)} 個檔案就緒')
