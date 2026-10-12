#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_battle_actions.py — 繁中 datamining 的 Action / ActionTransient / ClassJob /
ClassJobCategory / BaseParam / Item → battle_actions.json

由 build_data.py 呼叫,不單獨執行。

- 職業:ClassJob 中 JobIndex > 0 的職業,排除限定職業(青魔道士),依 id 排序。
- 職業技能:屬於該職業或其基本職業、可用職業包含該職業、玩家技能、非 PvP、非共通技能、
  有習得等級。規則挑不到的技能寫在 EXTRA_ACTIONS。依(習得等級, id)排序。
- 共通技能:可用職業包含任一戰鬥職業的共通玩家技能(排除採集職的共通技能)。
- 技能說明:技能循環可選的每個等級各一份,依該職業、該等級求值成純文字(見 action_text.py)。

繁中 ClassJob.csv 第 29 欄之後的欄位名稱錯一格,基本職業與主屬性因此不從表裡讀,
改用下面的 JOBS 對照表;挑出的職業不在表裡時結束程式。
"""
from action_text import evaluate_or_exit
from build_items import icon_path
from datamining import (Sheet, load_class_jobs, names_by_id, source_meta, to_bool, to_int,
                        write_json)

# 技能循環編輯頁可選的等級(SkillRotationLevel)
LEVELS = (50, 60, 70, 80, 90, 100)

# 職業縮寫 → (基本職業縮寫, 主屬性)。已對照遊戲確認:武僧為力量、毒蛇劍士為靈巧。
JOBS = {
    'PLD': ('GLA', 'strength'),
    'MNK': ('PGL', 'strength'),
    'WAR': ('MRD', 'strength'),
    'DRG': ('LNC', 'strength'),
    'BRD': ('ARC', 'dexterity'),
    'WHM': ('CNJ', 'mind'),
    'BLM': ('THM', 'intelligence'),
    'SMN': ('ACN', 'intelligence'),
    'SCH': ('ACN', 'mind'),
    'NIN': ('ROG', 'dexterity'),
    'MCH': (None, 'dexterity'),
    'DRK': (None, 'strength'),
    'AST': (None, 'mind'),
    'SAM': (None, 'strength'),
    'RDM': (None, 'intelligence'),
    'GNB': (None, 'strength'),
    'DNC': (None, 'dexterity'),
    'RPR': (None, 'strength'),
    'SGE': (None, 'mind'),
    'VPR': (None, 'dexterity'),
    'PCT': (None, 'intelligence'),
}
LIMITED_JOBS = {'BLU'}

# 規則挑不到、但遊戲裡屬於該職業的技能
EXTRA_ACTIONS = {
    # 光芒四射:Action 表裡沒有指定職業(ClassJob 0)且標為非玩家技能,
    # 但遊戲裡是赤魔道士 Lv100 的技能。
    'RDM': [37007],
}

# ActionCategory id → 技能類別
CATEGORIES = {2: 'spell', 3: 'weaponskill', 4: 'ability'}

# 爆發藥道具 id → 屬性。目前最高等級的寶藥;新資料片推出新等級時更新。
TINCTURES = {
    44157: 'strength',
    44158: 'dexterity',
    44159: 'vitality',
    44160: 'intelligence',
    44161: 'mind',
}
# 屬性 → BaseParam id;順序即 tincture_stat_jobs 的順序
STATS = {'strength': 1, 'dexterity': 2, 'vitality': 3, 'intelligence': 4, 'mind': 5}

ACTION_COLUMNS = ('#', 'Name', 'Icon', 'ActionCategory', 'ClassJob', 'ClassJobLevel',
                  'IsRoleAction', 'Range', 'EffectRange', 'Cast<100ms>', 'Recast<100ms>',
                  'MaxCharges', 'ClassJobCategory', 'IsPvP', 'IsPlayerAction')


def load_classjob_category_jobs(sheet):
    """ClassJobCategory id → 可用職業縮寫的集合(欄位名稱即縮寫)。"""
    id_column = sheet.column('#')
    name_column = sheet.column('Name')
    job_columns = [(index, header) for index, header in enumerate(sheet.header)
                   if header.strip() and index not in (id_column, name_column)]
    categories = {}
    for row in sheet.rows:
        if not row[id_column].strip().isdigit():
            continue
        categories[to_int(row[id_column])] = {
            header for index, header in job_columns if index < len(row) and to_bool(row[index])
        }
    return categories


def load_actions(sheet):
    actions = {}
    for values in sheet.records(*ACTION_COLUMNS):
        row = dict(zip(ACTION_COLUMNS, values))
        if row['#'].strip().isdigit():
            actions[to_int(row['#'])] = row
    return actions


def select_jobs(class_jobs):
    """ClassJob → 戰鬥職業 [(id, abbreviation, name)],依 id 排序。"""
    selected = []
    for job_id in sorted(class_jobs):
        job = class_jobs[job_id]
        if job['job_index'] <= 0 or job['abbreviation'] in LIMITED_JOBS:
            continue
        if job['abbreviation'] not in JOBS:
            raise SystemExit(f"ClassJob.csv: 職業 {job['abbreviation']}({job_id})不在 JOBS 對照表")
        selected.append((job_id, job['abbreviation'], job['name']))
    missing = sorted(set(JOBS) - {abbr for _, abbr, _ in selected})
    if missing:
        raise SystemExit(f'ClassJob.csv: 找不到 JOBS 對照表裡的職業 {missing}')
    return selected


def action_entry(action_id, row, job_id, descriptions_source, label):
    category = CATEGORIES.get(to_int(row['ActionCategory']))
    if category is None:
        raise SystemExit(f"{label}: 技能 {action_id} 的 ActionCategory {row['ActionCategory']} 不是戰技、魔法或能力")
    level = to_int(row['ClassJobLevel'])
    text = descriptions_source.get(action_id, '')
    icon_id = to_int(row['Icon'])
    return {
        'id': action_id,
        'name_tw': row['Name'].strip(),
        'icon_id': icon_id,
        'icon_path': icon_path(icon_id),
        'category': category,
        'level': level,
        'range': to_int(row['Range']),
        'effect_range': to_int(row['EffectRange']),
        'cast_100ms': to_int(row['Cast<100ms>']),
        'recast_100ms': to_int(row['Recast<100ms>']),
        'max_charges': to_int(row['MaxCharges']),
        'descriptions': {
            str(at): evaluate_or_exit(text, job_id, at, f'{label} 技能 {action_id}')
            for at in LEVELS if at >= level
        },
    }


def sort_key(entry):
    return entry['level'], entry['id']


def build(files, sources, out_path):
    """files: data_sources.json 中 ffxiv-datamining-tc 的檔案 → 本機路徑。"""
    class_jobs = load_class_jobs(Sheet(files['ClassJob.csv']))
    id_by_abbreviation = {job['abbreviation']: job_id for job_id, job in class_jobs.items()}
    categories = load_classjob_category_jobs(Sheet(files['ClassJobCategory.csv']))
    actions = load_actions(Sheet(files['Action.csv']))
    descriptions = {to_int(i): text for i, text in Sheet(files['ActionTransient.csv']).records('#', 'Description')
                    if i.strip().isdigit()}
    stat_names = names_by_id(Sheet(files['BaseParam.csv']))

    jobs = select_jobs(class_jobs)
    battle_abbreviations = {abbr for _, abbr, _ in jobs}

    def is_player_action(row):
        return (to_bool(row['IsPlayerAction']) and not to_bool(row['IsPvP'])
                and to_int(row['ClassJobLevel']) > 0)

    job_entries = []
    for job_id, abbr, name in jobs:
        base = JOBS[abbr][0]
        owners = {job_id}
        if base is not None:
            if base not in id_by_abbreviation:
                raise SystemExit(f'ClassJob.csv: 找不到 {abbr} 的基本職業 {base}')
            owners.add(id_by_abbreviation[base])

        selected = [
            action_id for action_id, row in actions.items()
            if to_int(row['ClassJob'], -1) in owners
            and abbr in categories.get(to_int(row['ClassJobCategory']), set())
            and is_player_action(row) and not to_bool(row['IsRoleAction'])
        ]
        for action_id in EXTRA_ACTIONS.get(abbr, []):
            if action_id not in actions:
                raise SystemExit(f'Action.csv: 找不到 {abbr} 的例外技能 {action_id}')
            if action_id not in selected:
                selected.append(action_id)

        entries = [action_entry(action_id, actions[action_id], job_id, descriptions, abbr)
                   for action_id in selected]
        job_entries.append({
            'id': job_id,
            'name_tw': name,
            'abbreviation': abbr,
            'icon_id': 62100 + job_id,
            'icon_path': icon_path(62100 + job_id),
            'actions': sorted(entries, key=sort_key),
        })

    # 共通技能:說明以「可用職業中 id 最小的職業」求值
    role_entries = []
    for action_id, row in actions.items():
        usable = categories.get(to_int(row['ClassJobCategory']), set())
        if not (to_bool(row['IsRoleAction']) and is_player_action(row) and usable & battle_abbreviations):
            continue
        evaluate_as = min(id_by_abbreviation[abbr] for abbr in usable if abbr in id_by_abbreviation)
        role_entries.append(action_entry(action_id, row, evaluate_as, descriptions, '共通技能'))
    role_entries.sort(key=sort_key)

    item_rows = {to_int(i): (name.strip(), to_int(icon), to_int(level))
                 for i, name, icon, level in Sheet(files['Item.csv']).records('#', 'Name', 'Icon', 'Level{Item}')
                 if to_int(i) in TINCTURES}
    tinctures = []
    for item_id, stat in sorted(TINCTURES.items(), key=lambda pair: pair[1]):
        if not item_rows.get(item_id, ('',))[0]:
            raise SystemExit(f'Item.csv: 找不到爆發藥 {item_id}')
        name, icon_id, item_level = item_rows[item_id]
        tinctures.append({
            'id': item_id,
            'name_tw': name,
            'icon_id': icon_id,
            'icon_path': icon_path(icon_id),
            'item_level': item_level,
            'stat': stat,
        })

    tincture_stat_jobs = {}
    for stat, base_param in STATS.items():
        if not stat_names.get(base_param):
            raise SystemExit(f'BaseParam.csv: 找不到屬性 {stat}({base_param})')
        tincture_stat_jobs[stat] = {
            'name_tw': stat_names[base_param],
            'jobs': [abbr for _, abbr, _ in jobs if JOBS[abbr][1] == stat],
        }

    output = {
        '_meta': {
            'job_count': len(job_entries),
            'action_count': sum(len(job['actions']) for job in job_entries),
            'role_action_count': len(role_entries),
            'description_levels': list(LEVELS),
            'game_version': sources['upstreams']['ffxiv-datamining-tc']['game_version'],
            'sources': source_meta(sources, 'ffxiv-datamining-tc'),
            'note': ('descriptions 以等級為 key,為該職業在該等級看到的說明純文字;'
                     '只收已習得的等級。共通技能以可用職業中 id 最小者求值。'
                     'range -1 為近戰、0 為自身;cast/recast 單位為 100ms。'),
        },
        'jobs': job_entries,
        'role_actions': role_entries,
        'tinctures': tinctures,
        'tincture_stat_jobs': tincture_stat_jobs,
    }
    write_json(out_path, output)

    print('完成:', out_path)
    print('  職業 / 職業技能 / 共通技能:', len(job_entries), '/', output['_meta']['action_count'], '/', len(role_entries))
