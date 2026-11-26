#!/usr/bin/env python3
"""Draws every Bab V figure and puts it under its number in the book.

usage:
  python3 -I docs/thesis/tools/make_bab5_figs.py

Runs the two generators (make_bab5_figs_a.py: architecture, use case,
activity, page map; make_bab5_figs_b.py: data model, sequence, status) into
a temporary folder and copies each drawing to docs/thesis/word/fig_5_N.png.
BOOK maps a drawing to its figure number; the numbers follow the order in
BAB_V_DESAIN_SISTEM.md, so change both together. Heights for the book are in
FIG_SIZE_CM of build_book.py.
"""
import glob, os, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
WORD = os.path.join(os.path.dirname(HERE), 'word')
BOOK = {'a01': 1, 'a02': 2, 'b10': 3, 'b09': 4, 'b07': 5, 'b11': 6, 'b08': 7,
        'a03': 8, 'a04': 9, 'a05': 10, 'a06': 11, 'a07': 12,
        'a08': 13, 'a09': 14, 'a10': 15, 'a11': 16, 'a12': 17, 'a13': 18,
        'b01': 19, 'b02': 20, 'b03': 21, 'b04': 22, 'b05': 23, 'b06': 24, 'a14': 25, 'a15': 26}

tmp = tempfile.mkdtemp(prefix='bab5figs-')
for part in ('a', 'b'):
    subprocess.run([sys.executable, '-I', os.path.join(HERE, 'make_bab5_figs_%s.py' % part), tmp, os.path.join(tmp, 'work')], check=True)
made = {os.path.basename(f)[:3]: f for f in glob.glob(os.path.join(tmp, '*.png'))}
missing = sorted(set(BOOK) - set(made))
if missing or set(made) - set(BOOK):
    sys.exit('drawings and BOOK differ: missing %s, extra %s' % (missing, sorted(set(made) - set(BOOK))))
for key, n in sorted(BOOK.items(), key=lambda kv: kv[1]):
    shutil.copyfile(made[key], os.path.join(WORD, 'fig_5_%d.png' % n))
    print('fig_5_%d.png  <-  %s' % (n, os.path.basename(made[key])))
