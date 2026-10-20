#!/usr/bin/env python3
"""Add the gallery only after genuine runtime screenshots have been captured."""
from pathlib import Path
root = Path(__file__).resolve().parent.parent
names = [('01-discover', 'Discover'), ('02-search', 'Search'),
         ('03-details', 'Details'), ('04-episodes', 'Episodes'),
         ('05-cast', 'Cast'), ('06-watchlist', 'Watchlist'),
         ('07-empty-watchlist', 'Empty watchlist')]
missing = [name for name, _ in names if not (root / 'docs/screenshots' / (name + '.png')).is_file()]
if missing:
    raise SystemExit('Missing runtime screenshots: ' + ', '.join(missing))
p = root / 'README.md'
text = p.read_text()
start, end = '<!-- screenshots:start -->', '<!-- screenshots:end -->'
gallery = '\n\n'.join(f'**{label}**\n\n<img src="docs/screenshots/{name}.png" alt="{label} screen" width="280">' for name, label in names)
before, rest = text.split(start, 1)
_, after = rest.split(end, 1)
p.write_text(before + start + '\n' + gallery + '\n' + end + after)
print('README now includes seven real runtime screenshots.')
