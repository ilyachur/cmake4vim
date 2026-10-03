"""Convert Vim/Neovim :profile output to line coverage in LCOV format."""
import re
from pathlib import Path


def executable(text):
    text = text.strip()
    return bool(text) and not text.startswith(('"', '\\')) and not re.match(r'end\w*\b', text)


def read_profile(path, root):
    scripts = {}
    functions = []
    section = None
    rows = None
    for line in Path(path).read_text(encoding='utf-8').splitlines():
        if line.startswith('SCRIPT  '):
            section = ('script', Path(line[8:]).expanduser().resolve())
            rows = None
        elif line.startswith('FUNCTION  '):
            section = ('function', None)
            rows = None
        elif line.startswith('    Defined:') and section and section[0] == 'function':
            location = re.match(r'(.+?)(?::| line )(\d+)$', line.strip()[9:])
            if not location:
                raise ValueError(f'Invalid function location: {line}')
            section = ('function', (Path(location[1]).expanduser().resolve(), int(location[2])))
        elif line.startswith('count') and section:
            rows = []
            if section[0] == 'script':
                scripts[section[1]] = rows
            else:
                if section[1] is None:
                    raise ValueError('Profile lacks function source locations; use a current editor')
                functions.append((section[1], rows))
        elif line == '':
            section = None if rows is not None else section
            rows = None
        elif rows is not None:
            # Recent Vim uses nanosecond precision, so timed columns are wider.
            timed = re.match(r'^\s*(\d+)\s+(?:\d+\.\d+\s+){1,2}(.*)$', line)
            if timed:
                rows.append((int(timed[1]), timed[2]))
            else:
                count = line[:5].strip()
                rows.append((int(count) if count else 0, line[28:]))

    coverage = {}
    for source, rows in scripts.items():
        try:
            relative = source.relative_to(root).as_posix()
        except ValueError:
            continue
        if relative.split('/')[0] not in ('autoload', 'plugin', 'after') or source.suffix != '.vim':
            continue
        coverage[source] = {number: count for number, (count, text) in enumerate(rows, 1)
                            if executable(text)}

    for (source, definition), rows in functions:
        if source not in coverage:
            continue
        script = scripts[source]
        # Built-ins such as popup_notification attribute generated lambdas to
        # their call site. Their synthetic bodies are not source file lines.
        if not re.match(r'^\s*fu\w*!?\s+', script[definition - 1][1]):
            continue
        position = definition
        for count, text in rows:
            start = position
            if position >= len(script):
                raise ValueError(f'Function exceeds source: {source}:{definition}')
            original = script[position][1]
            position += 1
            while position < len(script) and script[position][1].lstrip().startswith('\\'):
                original += script[position][1].lstrip()[1:]
                position += 1
            if original.strip() != text.strip():
                raise ValueError(f'Function/source mismatch: {source}:{start + 1}')
            if executable(text):
                for number in range(start + 1, position + 1):
                    coverage[source][number] = coverage[source].get(number, 0) + count
    return coverage


def write_lcov(profiles, root, output):
    root = Path(root).resolve()
    merged = {}
    for profile in profiles:
        for source, lines in read_profile(profile, root).items():
            target = merged.setdefault(source, {})
            for number, count in lines.items():
                target[number] = target.get(number, 0) + count
    if not merged or not any(count for lines in merged.values() for count in lines.values()):
        raise ValueError('No Vim coverage collected; check editor +profile support')
    # Files never sourced by any suite still contribute uncovered lines.
    for directory in ('autoload', 'plugin', 'after'):
        for source in (root / directory).rglob('*.vim'):
            if source not in merged:
                merged[source] = {number: 0 for number, text in enumerate(
                    source.read_text(encoding='utf-8').splitlines(), 1) if executable(text)}
    with Path(output).open('w', encoding='utf-8') as report:
        for source, lines in sorted(merged.items()):
            report.write(f'SF:{source.relative_to(root).as_posix()}\n')
            for number, count in sorted(lines.items()):
                report.write(f'DA:{number},{count}\n')
            report.write(f'LF:{len(lines)}\nLH:{sum(count > 0 for count in lines.values())}\nend_of_record\n')
