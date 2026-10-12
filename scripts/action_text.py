#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
action_text.py — 把 ActionTransient 的技能說明(含遊戲內標記)轉成某職業、某等級看到的純文字。

說明裡的標記只有:
- `<UIForeground>…</UIForeground>`、`<UIGlow>…</UIGlow>`:內容是顏色代碼,整段移除;
- `<If(條件)>…<Else/>…</If>`:依條件只留下成立的分支,可巢狀。
條件只有 `Equal(PlayerParameter(68),N)`(職業 id 等於 N)與
`GreaterThanOrEqualTo(PlayerParameter(72),N)`(等級大於等於 N)。

出現其他標記或條件時以非 0 結束,不默默輸出可能錯誤的文字。
輸出把換行統一成 `\\n`、每行去掉頭尾空白、刪掉空行(與 App 原本的整理方式相同)。
"""
import re
import sys

TOKEN = re.compile(
    r'<UIForeground>[^<]*</UIForeground>'
    r'|<UIGlow>[^<]*</UIGlow>'
    r'|<If\((?P<condition>[^>]*)\)>'
    r'|<Else/>'
    r'|</If>'
    r'|<[^>]*>'
)
CONDITION = re.compile(r'(Equal|GreaterThanOrEqualTo)\(PlayerParameter\((68|72)\),(\d+)\)')
PARAMETER_JOB = 68
PARAMETER_LEVEL = 72


class MarkupError(ValueError):
    pass


def _holds(condition, job_id, level):
    match = CONDITION.fullmatch(condition)
    if not match:
        raise MarkupError(f'不認得的條件: {condition}')
    kind, parameter, value = match.group(1), int(match.group(2)), int(match.group(3))
    if (kind, parameter) == ('Equal', PARAMETER_JOB):
        return job_id == value
    if (kind, parameter) == ('GreaterThanOrEqualTo', PARAMETER_LEVEL):
        return level >= value
    raise MarkupError(f'不認得的條件: {condition}')


def evaluate(text, job_id, level):
    """回傳 job_id 的職業在 level 等級看到的說明純文字。標記不認得或不成對時丟出 MarkupError。"""
    output = []
    # 每層 If:(進入這層之前是否輸出中, 條件是否成立, 是否已遇到 Else)
    stack = []
    active = True
    position = 0

    for match in TOKEN.finditer(text):
        if active:
            output.append(text[position:match.start()])
        position = match.end()
        token = match.group(0)

        if token.startswith(('<UIForeground>', '<UIGlow>')):
            continue
        if match.group('condition') is not None:
            holds = _holds(match.group('condition'), job_id, level)
            stack.append((active, holds, False))
            active = active and holds
        elif token == '<Else/>':
            if not stack or stack[-1][2]:
                raise MarkupError('<Else/> 沒有對應的 <If>')
            outer, holds, _ = stack[-1]
            stack[-1] = (outer, holds, True)
            active = outer and not holds
        elif token == '</If>':
            if not stack:
                raise MarkupError('</If> 沒有對應的 <If>')
            active = stack.pop()[0]
        else:
            raise MarkupError(f'不認得的標記: {token}')

    if stack:
        raise MarkupError('<If> 沒有結束')
    if active:
        output.append(text[position:])

    lines = ''.join(output).replace('\r\n', '\n').replace('\r', '\n').split('\n')
    return '\n'.join(line.strip() for line in lines if line.strip())


def evaluate_or_exit(text, job_id, level, label):
    """evaluate,失敗時以非 0 結束並指出是哪個技能。"""
    try:
        return evaluate(text, job_id, level)
    except MarkupError as error:
        sys.exit(f'{label}: {error}')
