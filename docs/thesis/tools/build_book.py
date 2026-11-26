"""Build the whole Tugas Akhir book (cover to Riwayat Hidup) from the ISTTS
Word template and the markdown drafts in docs/thesis/.

usage:
  python3 -I docs/thesis/tools/build_book.py <TEMPLATE.dotx> <out.docx>

Reads docs/thesis/BAB_*.md, docs/thesis/DAFTAR_PUSTAKA.md and
docs/thesis/word/*.png. Standard library only. The template's styles,
numbering, headers, footers and section layout are kept; every text is
replaced. Page numbers in the lists are PAGEREF fields: in Word press
Ctrl+A then F9 once (Word also asks on opening).
"""
import os, re, sys, zipfile
from xml.sax.saxutils import escape
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.dirname(HERE)                      # docs/thesis
TEMPLATE, OUT = sys.argv[1], sys.argv[2]

# Private facts for the Riwayat Hidup (birth date, home address, schools).
# The repository is public, so they never go into git: they live in
# docs/thesis/local/riwayat.json (git-ignored) and are used only when the
# output file is written inside docs/thesis/local/. A book built into
# docs/thesis/word/ keeps the [ISI] marks.
import json
_PRIV_PATH = os.path.join(DOCS, 'local', 'riwayat.json')
_LOCAL_OUT = os.path.abspath(OUT).startswith(os.path.join(DOCS, 'local') + os.sep)
PRIV = json.load(open(_PRIV_PATH, encoding='utf8')) if (_LOCAL_OUT and os.path.exists(_PRIV_PATH)) else {}
# The owner's photo is private too: docs/thesis/local/foto.png, used only together with PRIV.
_FOTO = os.path.join(DOCS, 'local', 'foto.png')
FOTO = _FOTO if (PRIV and os.path.exists(_FOTO)) else os.path.join(DOCS, 'word', 'foto_placeholder.png')
def _png_size(path):
    import struct
    with open(path, 'rb') as f:
        head = f.read(24)
    return struct.unpack('>II', head[16:24])
W = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'

# ---------------------------------------------------------------- facts
F = dict(
    nama='WILSIN',                   # confirmed by the owner 2026-11-24 (all caps, as on the BAA list)
    nrp='221310660',
    prodi='Informatika',
    fakultas='Sains dan Teknologi',
    gelar='Sarjana Komputer',
    judul_lines=['APLIKASI MULTIPLATFORM', 'SISTEM KURSUS BAHASA MANDARIN', 'EASY STUDY MENGGUNAKAN FLUTTER'],   # 3 lines of at most 30 characters: the cover row has an exact height
    judul='Aplikasi Multiplatform Sistem Kursus Bahasa Mandarin Easy Study menggunakan Flutter',
    judul_en='Multiplatform Application for the Easy Study Mandarin Course System using Flutter',
    pembimbing='Ong, Hansel Santoso, S.SI., M.Kom.',
    co='Prof. Dr. Ir. Esther Irawati Setiawan, S.Kom., M.Kom.',
    penguji=['[ISI: nama Penguji I]', '[ISI: nama Penguji II]', '[ISI: nama Penguji III]'],
    tahun='⟦2027⟧',
    bulan_sidang='⟦JANUARI 2027⟧',       # owner wrote JANUARY 2027 in Word (2026-11-24); Indonesian spelling, confirm
    tgl_pernyataan='⟦28 Desember 2026⟧',  # owner wrote 28 December 2026 in Word; Indonesian spelling, confirm
    bulan_kata_pengantar='[ISI: bulan] ⟦2027⟧',
)

# ---------------------------------------------------------------- template parts
z = zipfile.ZipFile(TEMPLATE)
files = {n: z.read(n) for n in z.namelist()}
doc_xml = files['word/document.xml'].decode('utf8')
HEAD = doc_xml[:doc_xml.index('<w:body>') + len('<w:body>')]
assert 'xmlns:m=' in HEAD and 'xmlns:wp=' in HEAD

def clean(s):
    s = re.sub(r' w:rsid[A-Za-z]*="[^"]*"', '', s)
    s = re.sub(r' w:paraId="[^"]*"', '', s)
    s = re.sub(r' w:textId="[^"]*"', '', s)
    s = re.sub(r'<w:lastRenderedPageBreak\s*/>', '', s)
    return s

tree = ET.fromstring(files['word/document.xml'])
body_el = tree.find(W + 'body')
els = list(body_el)
NS = re.findall(r'xmlns:(\w+)="([^"]+)"', doc_xml)        # every prefix the template uses, root or local
ROOT_PREFIXES = set(re.findall(r'xmlns:(\w+)=', HEAD))
for p, uri in NS:
    ET.register_namespace(p, uri)
def raw(i):
    """XML of body element i (1-based, as in the template dump), template prefixes kept."""
    s = ET.tostring(els[i - 1], encoding='unicode')
    s = re.sub(r' xmlns:(\w+)="[^"]+"', lambda m: '' if m.group(1) in ROOT_PREFIXES else m.group(0), s)
    return clean(s)

SECTS = []
for i, el in enumerate(els, 1):
    sp = el if el.tag == W + 'sectPr' else (el.find(W + 'pPr/' + W + 'sectPr') if el.tag == W + 'p' else None)
    if sp is not None:
        s = ET.tostring(sp, encoding='unicode'); s = re.sub(r' xmlns:\w+="[^"]+"', '', s); SECTS.append(clean(s))
SECT_COVER, SECT_FRONT, SECT_BAB1, SECT_BAB, SECT_END = SECTS[0], SECTS[1], SECTS[2], SECTS[3], SECTS[-1]

# ---------------------------------------------------------------- run / paragraph helpers
MARK = re.compile(r'(\[ISI:[^\]]*\]|⟦[^⟧]*⟧)')
def runs(text, rpr=''):
    out = []
    for seg in MARK.split(text):
        if not seg:
            continue
        hl = ''
        if MARK.fullmatch(seg):
            hl = '<w:highlight w:val="yellow"/>'
            if seg.startswith('⟦'):
                seg = seg[1:-1]
        r = rpr + hl
        out.append('<w:r>%s<w:t xml:space="preserve">%s</w:t></w:r>' % ('<w:rPr>%s</w:rPr>' % r if r else '', escape(seg)))
    return ''.join(out)
def P(ppr='', body=''):
    return '<w:p>%s%s</w:p>' % ('<w:pPr>%s</w:pPr>' % ppr if ppr else '', body)
def p_style(style, text='', extra_ppr='', pre=''):
    return P('<w:pStyle w:val="%s"/>%s' % (style, extra_ppr), pre + (runs(text) if text else ''))
def p_body(text, ind=''):
    return P(ind, runs(text))
def p_empty():
    return '<w:p/>'
PAGEBREAK = '<w:r><w:br w:type="page"/></w:r>'
TAB = '<w:r><w:tab/></w:r>'

class Ctx:
    bk = 0
    toc = []        # (kind, number, title, bookmark|literal)
    gambar = []     # (number, title, bookmark)
    tabel = []
    rumus = []
    abstract_nums = []
    nums = []
    numid = 1000
    docpr = 200
    fig_files = {}  # rId -> png path of every figure placed as a picture
    algoritma = []  # (number, title, bookmark)
    segmen = []     # (number, title, bookmark)
C = Ctx()

def bookmark(name):
    C.bk += 1
    return ('<w:bookmarkStart w:id="%d" w:name="%s"/>' % (C.bk, name), '<w:bookmarkEnd w:id="%d"/>' % C.bk)
def pageref(bk):
    return ('<w:r><w:fldChar w:fldCharType="begin"/></w:r><w:r><w:instrText xml:space="preserve"> PAGEREF %s \\h </w:instrText></w:r>'
            '<w:r><w:fldChar w:fldCharType="separate"/></w:r><w:r><w:t>0</w:t></w:r><w:r><w:fldChar w:fldCharType="end"/></w:r>' % bk)

def new_num(abstract_id, restart=True):
    C.numid += 1
    C.nums.append('<w:num w:numId="%d"><w:abstractNumId w:val="%d"/>%s</w:num>' % (
        C.numid, abstract_id, '<w:lvlOverride w:ilvl="0"><w:startOverride w:val="1"/></w:lvlOverride>' if restart else ''))
    return C.numid

numxml = files['word/numbering.xml'].decode('utf8')
def abstract(aid):
    m = re.search(r'<w:abstractNum w:abstractNumId="%s"[ >].*?</w:abstractNum>' % aid, numxml, re.S); assert m; return m.group(0)
A_SUB, A_SUBSUB, A_LETTER = abstract('30'), abstract('28'), abstract('20')
A_DEC = re.sub(r'(<w:lvl w:ilvl="0"[^>]*>.*?<w:numFmt w:val=")lowerLetter(")', r'\1decimal\2', A_LETTER, count=1, flags=re.S)
def add_abstract(src, new_id, lvltext=None):
    s = re.sub(r'w:abstractNumId="\d+"', 'w:abstractNumId="%d"' % new_id, src, count=1)
    s = re.sub(r'<w:nsid w:val="[0-9A-F]+"', '<w:nsid w:val="%08X"' % (0x10000000 + new_id * 7919), s, count=1)
    if lvltext:
        s = re.sub(r'(<w:lvl w:ilvl="0"[^>]*>.*?<w:lvlText w:val=")[^"]*(")', lambda m: m.group(1) + lvltext + m.group(2), s, count=1, flags=re.S)
    C.abstract_nums.append(s)
    return new_id
A_DEC_ID = add_abstract(A_DEC, 60)
SUB_NUM, SUBSUB_NUM = {}, {}
for c in range(1, 9):
    SUB_NUM[c] = add_abstract(A_SUB, 200 + c, '%d.%%1' % c)       # abstractNumId == numId below
    C.nums.append('<w:num w:numId="%d"><w:abstractNumId w:val="%d"/></w:num>' % (200 + c, 200 + c))
def subsub_num(c, k):
    if (c, k) not in SUBSUB_NUM:
        aid = 300 + c * 20 + k
        add_abstract(A_SUBSUB, aid, '%d.%d.%%1' % (c, k))
        C.nums.append('<w:num w:numId="%d"><w:abstractNumId w:val="%d"/></w:num>' % (aid, aid))
        SUBSUB_NUM[(c, k)] = aid
    return SUBSUB_NUM[(c, k)]

def p_sub(text, c, bk=None):
    pre, post = bookmark(bk) if bk else ('', '')
    return P('<w:pStyle w:val="STTSJudulSubBab"/><w:numPr><w:ilvl w:val="0"/><w:numId w:val="%d"/></w:numPr><w:ind w:hanging="720"/>' % SUB_NUM[c], pre + runs(text) + post)
def p_subsub(text, c, k, bk=None):
    pre, post = bookmark(bk) if bk else ('', '')
    return P('<w:pStyle w:val="STTSJudulSubBab"/><w:numPr><w:ilvl w:val="0"/><w:numId w:val="%d"/></w:numPr><w:ind w:left="851" w:hanging="851"/>' % subsub_num(c, k), pre + runs(text) + post)
def p_list(text, numid, left, hanging):
    return P('<w:pStyle w:val="ListParagraph"/><w:numPr><w:ilvl w:val="0"/><w:numId w:val="%d"/></w:numPr><w:ind w:left="%d" w:hanging="%d"/>' % (numid, left, hanging), runs(text))
def p_sistematika(title):
    bab, judul = [s.strip() for s in title.split(' : ', 1)]
    return P('<w:numPr><w:ilvl w:val="0"/><w:numId w:val="12"/></w:numPr><w:tabs><w:tab w:val="left" w:pos="1418"/><w:tab w:val="left" w:pos="1985"/></w:tabs><w:ind w:left="426" w:hanging="426"/>',
             runs(bab) + '<w:r><w:tab/><w:t>:</w:t></w:r>' + TAB + runs(judul))
def p_sistematika_desc(text):
    return P('<w:ind w:left="1985" w:firstLine="0"/>', runs(text))
def p_judulbab(text='', pre='', bk=None):
    b1, b2 = bookmark(bk) if bk else ('', '')
    return P('<w:pStyle w:val="STTSJudulBab"/>', pre + b1 + (runs(text) if text else '') + b2)
def sect_par(sect, style='STTSJudulBab'):
    return P('<w:pStyle w:val="%s"/>%s' % (style, sect))

def inline_picture(rid, cx, cy, name):
    C.docpr += 1
    return ('<w:r><w:rPr><w:noProof/></w:rPr><w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0">'
            '<wp:extent cx="%d" cy="%d"/><wp:effectExtent l="0" t="0" r="0" b="0"/><wp:docPr id="%d" name="%s"/>'
            '<wp:cNvGraphicFramePr><a:graphicFrameLocks xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" noChangeAspect="1"/></wp:cNvGraphicFramePr>'
            '<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
            '<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:nvPicPr><pic:cNvPr id="0" name="%s"/><pic:cNvPicPr/></pic:nvPicPr>'
            '<pic:blipFill><a:blip r:embed="%s"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
            '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="%d" cy="%d"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic>'
            '</a:graphicData></a:graphic></wp:inline></w:drawing></w:r>') % (cx, cy, C.docpr, name, name, rid, cx, cy)

def rebuild_par(p_xml, parts):
    """Keep a template paragraph's pPr and first-run formatting, replace its runs.
    parts: list of str (text, may hold [ISI]/⟦⟧ marks) or the token '\\t'."""
    m = re.match(r'<w:p(?: [^>]*)?>(<w:pPr>.*?</w:pPr>)?(.*)</w:p>$', p_xml, re.S)
    ppr = m.group(1) or ''
    ppr = re.sub(r'<w:rPr>.*?</w:rPr>', '', ppr, flags=re.S)
    rm = re.search(r'<w:r>(?:<w:rPr>(.*?)</w:rPr>)?', m.group(2) or '', re.S)
    rpr = (rm.group(1) if rm and rm.group(1) else '')
    rpr = re.sub(r'<w:highlight [^>]*/>', '', rpr)
    out = []
    for part in parts:
        if part == '\t':
            out.append('<w:r>%s<w:tab/></w:r>' % ('<w:rPr>%s</w:rPr>' % rpr if rpr else ''))
        else:
            out.append(runs(part, rpr))
    return '<w:p>%s%s</w:p>' % (ppr, ''.join(out))

# ---------------------------------------------------------------- markdown parsing
def parse_md(path):
    lines = open(path, encoding='utf8').read().split('\n')
    blocks, title, i = [], [], 0
    while i < len(lines):
        ln = lines[i]
        if not ln.strip():
            i += 1; continue
        if ln.startswith('```'):
            i += 1
            while i < len(lines) and not lines[i].startswith('```'):
                i += 1
            i += 1; continue
        if ln.startswith('# '):
            title.append(ln[2:].strip()); i += 1; continue
        if ln.startswith('## '):
            blocks.append(('h2', re.sub(r'^\d+(\.\d+)*\s+', '', ln[3:].strip()))); i += 1; continue
        if ln.startswith('### '):
            blocks.append(('h3', re.sub(r'^\d+(\.\d+)*\s+', '', ln[4:].strip()))); i += 1; continue
        if ln.startswith('|'):
            rows = []
            while i < len(lines) and lines[i].startswith('|'):
                cells = [c.strip() for c in lines[i].strip().strip('|').split('|')]
                if not all(re.fullmatch(r':?-{2,}:?', c) for c in cells):
                    rows.append(cells)
                i += 1
            blocks.append(('table', rows)); continue
        m_num = re.match(r'^(\d+)\. (.*)$', ln)
        m_bul = re.match(r'^- (.*)$', ln)
        m_let = re.match(r'^([a-c])\. ([A-Z][^.]{0,40})$', ln)
        if m_num or m_bul or m_let:
            kind = 'num' if m_num else ('bul' if m_bul else 'let')
            first = (m_num.group(2) if m_num else m_bul.group(1) if m_bul else m_let.group(2))
            cont = []; i += 1
            while i < len(lines) and lines[i].strip() and re.match(r'^\s+\S', lines[i]):
                cont.append(lines[i].strip()); i += 1
            blocks.append((kind, first, ' '.join(cont))); continue
        para = [ln.strip()]; raw = [ln.rstrip()]; i += 1
        while i < len(lines) and lines[i].strip() and not re.match(r'^(#|\||```|\d+\. |- |[a-c]\. [A-Z])', lines[i]):
            para.append(lines[i].strip()); raw.append(lines[i].rstrip()); i += 1
        text = ' '.join(para)
        mc = re.fullmatch(r'(Algoritma|Segmen Program) (\d+\.\d+)', para[0])
        if mc and len(para) >= 3:
            body = [re.sub(r'^\d{2}: ?', '', l) for l in raw[2:]]
            blocks.append(('code', mc.group(1), mc.group(2), para[1], body)); continue
        mf = re.fullmatch(r'(.*\S)\s{3,}\((\d+\.\d+)\)', text)
        if text.startswith('[GAMBAR'):
            blocks.append(('fig', text))
        elif re.fullmatch(r'Gambar \d+\.\d+', para[0]) and len(para) >= 2:
            blocks.append(('cap', para[0], ' '.join(para[1:])))
        elif re.fullmatch(r'Tabel \d+\.\d+', para[0]) and len(para) >= 2:
            blocks.append(('tcap', para[0], ' '.join(para[1:])))
        elif mf and len(para) == 1:
            blocks.append(('formula', mf.group(1).strip(), mf.group(2)))
        else:
            blocks.append(('p', text))
    return title, blocks

ROMAN = {'I': 1, 'II': 2, 'III': 3, 'IV': 4, 'V': 5, 'VI': 6, 'VII': 7, 'VIII': 8}

# ---------------------------------------------------------------- tables and formulas
TBL_BORDERS = ('<w:tblBorders><w:top w:val="single" w:sz="4" w:space="0" w:color="auto"/><w:left w:val="single" w:sz="4" w:space="0" w:color="auto"/>'
               '<w:bottom w:val="single" w:sz="4" w:space="0" w:color="auto"/><w:right w:val="single" w:sz="4" w:space="0" w:color="auto"/>'
               '<w:insideH w:val="single" w:sz="4" w:space="0" w:color="auto"/><w:insideV w:val="single" w:sz="4" w:space="0" w:color="auto"/></w:tblBorders>')
def table_xml(rows):
    ncol = max(len(r) for r in rows)
    weights = []
    for ci in range(ncol):
        longest = max(len(r[ci]) if ci < len(r) else 0 for r in rows)
        weights.append(min(max(longest, 4), 40))
    total = 7938
    widths = [int(total * w / sum(weights)) for w in weights]
    widths[-1] += total - sum(widths)
    out = ['<w:tbl><w:tblPr><w:tblW w:w="%d" w:type="dxa"/><w:jc w:val="center"/>%s<w:tblLayout w:type="fixed"/>'
           '<w:tblLook w:val="04A0" w:firstRow="1" w:lastRow="0" w:firstColumn="1" w:lastColumn="0" w:noHBand="0" w:noVBand="1"/></w:tblPr>' % (total, TBL_BORDERS)]
    out.append('<w:tblGrid>%s</w:tblGrid>' % ''.join('<w:gridCol w:w="%d"/>' % w for w in widths))
    for ri, r in enumerate(rows):
        hdr = ri == 0
        out.append('<w:tr><w:trPr><w:cantSplit/><w:jc w:val="center"/>%s</w:trPr>' % ('<w:tblHeader/>' if hdr else ''))
        for ci in range(ncol):
            txt = r[ci] if ci < len(r) else ''
            out.append('<w:tc><w:tcPr><w:tcW w:w="%d" w:type="dxa"/><w:shd w:val="clear" w:color="auto" w:fill="%s"/></w:tcPr>' % (widths[ci], 'D9D9D9' if hdr else 'auto'))
            out.append(P('<w:pStyle w:val="%s"/><w:rPr><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr>' % ('STTSTabelHeader' if hdr else 'STTSTabelContent'),
                         runs(txt, '<w:sz w:val="24"/><w:szCs w:val="24"/>')))
            out.append('</w:tc>')
        out.append('</w:tr>')
    out.append('</w:tbl>')
    return ''.join(out)

MATH_RPR = '<w:rPr><w:rFonts w:ascii="Cambria Math" w:hAnsi="Cambria Math"/></w:rPr>'
def mr(text, upright=False):
    return '<m:r>%s%s<m:t xml:space="preserve">%s</m:t></m:r>' % ('<m:rPr><m:sty m:val="p"/></m:rPr>' if upright else '', MATH_RPR, escape(text))
def mfrac(num, den):
    return '<m:f><m:fPr><m:ctrlPr>%s</m:ctrlPr></m:fPr><m:num>%s</m:num><m:den>%s</m:den></m:f>' % (MATH_RPR, num, den)
OMML = {
    '2.1': mr('S=1−') + mfrac(mr('d'), mr('n')),
    '2.2': mr('Skor SUS', True) + mr('=') + mr('[') + mr('∑') + mr('(') + mr('skor ganjil', True) + mr('−1)+') + mr('∑') + mr('(5−') + mr('skor genap', True) + mr(')]×2,5'),
}
RUMUS_NAMES = {'2.1': 'Nilai Kemiripan Jawaban Typing', '2.2': 'Skor System Usability Scale', '5.1': 'Sisa Sesi yang Dapat Dipesan', '5.2': 'Nilai Bagian Tes'}
OMML['5.1'] = mr('Sisa dapat dipesan', True) + mr('=') + mr('sessionsRemaining', True) + mr('−') + mr('sessionsBooked', True)
OMML['5.2'] = mr('Nilai bagian', True) + mr('=') + mfrac(mr('poin diperoleh', True), mr('poin maksimal', True)) + mr('×100')
def p_formula(text, number):
    body = OMML.get(number)
    if body is None:
        body = mr(text)
    math = '<m:oMath>%s</m:oMath>' % body   # inline, the number follows in the same paragraph as in the template
    b1, b2 = bookmark('rumus_' + number.replace('.', '_'))
    C.rumus.append((number, RUMUS_NAMES.get(number, text), 'rumus_' + number.replace('.', '_')))
    return P('<w:pStyle w:val="STTSRumus"/><w:tabs><w:tab w:val="clear" w:pos="2552"/><w:tab w:val="clear" w:pos="7655"/><w:tab w:val="right" w:pos="7938"/></w:tabs><w:ind w:firstLine="1134"/>',
             b1 + math + TAB + runs('(%s)' % number) + b2)


# ---------------------------------------------------------------- algorithms and program segments (campus Tabel 8)
A_ALGO_ID = 22   # the template's "01:" numbering (decimalZero, Courier New 10) used by Algoritma 3.1
A_SEG_ID = 29    # the same numbering bound to the segment style (template numId 19)
def p_code(kind, number, title, lines):
    """Caption in the template style, then one numbered line per pseudocode or code line, then a blank line."""
    bk = ('algoritma_' if kind == 'Algoritma' else 'segmen_') + number.replace('.', '_')
    b1, b2 = bookmark(bk)
    cap_style = 'STTSAlgoritma' if kind == 'Algoritma' else 'STTSSegmenProgram'
    body_style = 'STTSAlgoritmaContent' if kind == 'Algoritma' else 'STTSSegmenProgramContent'
    out = [P('<w:pStyle w:val="%s"/><w:keepNext/>' % cap_style, b1 + runs('%s %s %s' % (kind, number, title)) + b2)]
    num = new_num(A_ALGO_ID if kind == 'Algoritma' else A_SEG_ID)
    for ln in lines:
        lead = len(ln) - len(ln.lstrip(' '))
        text = '\u00a0' * lead + ln.lstrip(' ')
        out.append(P('<w:pStyle w:val="%s"/><w:keepNext/><w:numPr><w:ilvl w:val="0"/><w:numId w:val="%d"/></w:numPr><w:ind w:left="567" w:hanging="567"/>' % (body_style, num), runs(text)))
    out.append(p_empty())
    (C.algoritma if kind == 'Algoritma' else C.segmen).append((number, title, bk))
    return out

# ---------------------------------------------------------------- chapter rendering
FIG_SIZE_CM = {'2.1': (13, 5.72), '2.2': (13, 5.2), '2.3': (13, 6.24), '2.4': (13, 5.46), '2.5': (13, 5.46), '2.6': (13, 6.5), '2.7': (13, 6.37), '2.8': (13, 6.5),   # docs/thesis/tools/make_bab2_figs.py, canvas 1000 px wide
               '3.1': (6.5, 13.5), '3.2': (10, 13.5), '3.3': (12, 8.1), '3.4': (12, 6.2), '3.5': (14, 10), '3.6': (14, 11.8), '3.7': (14, 12.3), '3.8': (14, 10.9),
               '4.1': (8, 11), '4.2': (12, 8.4), '4.3': (14, 3), '4.4': (14, 3),
               '5.1': (14, 9), '5.2': (14, 9.5), '5.3': (14, 9.5), '5.4': (14, 9.5), '5.5': (14, 10), '5.6': (14, 11), '5.7': (14, 11), '5.8': (14, 9.5), '5.9': (14, 10)}            # width, height in cm; other figures 14 x 8
# Bab VI screenshots (docs/thesis/tools/shots_bab6.mjs, 1280 x 776 after clean_shots.mjs): 12 cm wide lets two
# figures with their captions and a short paragraph each share one page (text height 22.7 cm).
for _n in range(1, 60):
    FIG_SIZE_CM.setdefault('6.%d' % _n, (12, 7.28))

def render_chapter(c, title, blocks, figure_png=None):
    out = []
    bk = 'bab%d' % c
    out.append(p_judulbab('BAB %s' % [k for k, v in ROMAN.items() if v == c][0], bk=bk))
    out.append(p_judulbab(title))
    out.append(p_judulbab())
    C.toc.append(('bab', 'BAB %s' % [k for k, v in ROMAN.items() if v == c][0], title, bk))
    k = j = 0
    prev = None; cur_num = None; cur_let = None; in_sis = False
    for b in blocks:
        kind = b[0]
        if kind == 'h2':
            k += 1; j = 0; in_sis = b[1].lower().startswith('sistematika')
            bkn = 'sub%d_%d' % (c, k)
            out += [p_empty(), p_sub(b[1], c, bkn)]
            C.toc.append(('sub', '%d.%d' % (c, k), b[1], bkn))
        elif kind == 'h3':
            j += 1
            bkn = 'sub%d_%d_%d' % (c, k, j)
            out += [p_empty(), p_subsub(b[1], c, k, bkn)]
            C.toc.append(('subsub', '%d.%d.%d' % (c, k, j), b[1], bkn))
        elif kind == 'p':
            out.append(p_body(b[1]))
        elif kind == 'num':
            if prev != 'num':
                cur_num = new_num(A_DEC_ID)
            out.append(p_list((b[1] + ' ' + b[2]).strip(), cur_num, 567, 567))
        elif kind == 'let':
            if cur_let is None or prev not in ('let', 'bul', 'p'):
                cur_let = new_num(20)
            out.append(p_list((b[1] + ' ' + b[2]).strip(), cur_let, 426, 426))
        elif kind == 'bul':
            if in_sis:
                out.append(p_sistematika(b[1]))
                if b[2]:
                    out.append(p_sistematika_desc(b[2]))
            else:
                out.append(p_list((b[1] + ' ' + b[2]).strip(), 12, 851, 425))
        elif kind == 'fig':
            out.append(P('<w:pStyle w:val="STTSGambar"/><w:spacing w:line="360" w:lineRule="auto"/>'))
            m = re.match(r'\[GAMBAR (\d+\.\d+):?\s*(.*)\]$', b[1], re.S)
            png = m and os.path.join(DOCS, 'word', 'fig_%s.png' % m.group(1).replace('.', '_'))
            if png and os.path.exists(png):
                rid = 'rIdFig_' + m.group(1).replace('.', '_')
                C.fig_files[rid] = png
                wcm, hcm = FIG_SIZE_CM.get(m.group(1), (14, 8))
                out.append(P('<w:pStyle w:val="STTSGambar"/>', inline_picture(rid, wcm * 360000, hcm * 360000, 'Gambar %s' % m.group(1))))
            else:
                out.append(p_style('STTSGambar', '[ISI: Gambar %s — %s]' % (m.group(1), m.group(2).strip()) if m else b[1]))
        elif kind == 'cap':
            number = b[1].split()[1]; bkn = 'gambar_' + number.replace('.', '_')
            b1, b2 = bookmark(bkn)
            out.append(P('<w:pStyle w:val="STTSGambar"/>', b1 + runs(b[1]) + b2))
            out.append(p_style('STTSGambar', b[2]))
            out.append(p_style('STTSGambar'))
            C.gambar.append((number, b[2], bkn))
        elif kind == 'tcap':
            number = b[1].split()[1]; bkn = 'tabel_' + number.replace('.', '_')
            b1, b2 = bookmark(bkn)
            out.append(P('<w:pStyle w:val="STTSTabel"/><w:keepNext/>', b1 + runs(b[1]) + b2))
            out.append(p_style('STTSTabel', b[2], '<w:keepNext/>'))
            C.tabel.append((number, b[2], bkn))
        elif kind == 'table':
            out.append(table_xml(b[1]))
            out.append(p_style('STTSTabel'))
        elif kind == 'formula':
            out.append(p_formula(b[1], b[2]))
        elif kind == 'code':
            out += p_code(*b[1:])
        prev = kind
    return out

# ---------------------------------------------------------------- skeleton chapters IV–VIII
SKELETON = {
    4: ('ANALISA SISTEM', '[ISI: paragraf pembuka Bab IV: bab ini menganalisis kebutuhan sistem berdasarkan fakta yang dikumpulkan di Easy Study.]', [
        ('Pengumpulan Fakta', '[ISI: cara pengumpulan fakta: wawancara dengan admin dan empat guru, pengamatan langsung, analisis dokumen (daftar murid di spreadsheet, daftar hadir, catatan nilai simulasi).]', [
            ('Wawancara', '[ISI: tanggal, narasumber (inisial), ringkasan jawaban per topik; transkrip lengkap di Lampiran G.]'),
            ('Analisis Dokumen', '[ISI: dokumen yang dipakai saat ini dan kelemahannya, dengan Gambar 4.x tangkapan layar yang disamarkan.]')]),
        ('Identifikasi Masalah', '[ISI: daftar masalah dari Tabel 3.4 yang dipetakan ke kebutuhan sistem (Tabel 4.1).]', []),
        ('Perbandingan dengan Aplikasi Sejenis', '[ISI: Teach \'n Go, HelloChinese, dan Tugas Akhir Jesslyn (2024): fitur yang dibandingkan dan apa yang diambil (Tabel 4.2).]', []),
        ('Spesifikasi Kebutuhan Sistem', '[ISI: kebutuhan fungsional per peran dan kebutuhan non-fungsional (keamanan kunci jawaban, konsistensi voucher, multiplatform) dalam Tabel 4.3 sampai 4.5.]', [
            ('Kebutuhan Admin', '[ISI]'), ('Kebutuhan Guru', '[ISI]'), ('Kebutuhan Murid', '[ISI]')]),
    ]),
    5: ('DESAIN SISTEM', '[ISI: paragraf pembuka Bab V: bab ini menjelaskan rancangan sistem baru dari proposal §IV dengan nama koleksi dan fungsi yang dipakai di kode.]', [
        ('Deskripsi Sistem Baru', '[ISI: gambaran umum aplikasi, tiga peran, platform, Firebase sebagai backend.]', []),
        ('Jadwal dan Sesi', '[ISI: perbedaan schedules (pola mingguan) dan class_sessions (kejadian per tanggal), pembuatan sesi 14 hari ke depan.]', []),
        ('Penjadwalan Guru dan Pengecekan Bentrok', '[ISI: aturan ketersediaan, pengecekan bentrok guru, ruang, dan murid dalam transaksi saveSchedule; guru pengganti. Algoritma 5.1 Pengecekan Bentrok Jadwal (scheduling.js: conflicts, overlaps); Algoritma 5.2 Pemesanan Sesi (bookingRefusal, termForBooking).]', []),
        ('Konsistensi Data Voucher', '[ISI: pemotongan sesi saat closeSession dalam satu transaksi, idempoten, voucher_history sebagai buku besar. Algoritma 5.3 Penutupan Sesi dan Pemotongan Voucher (closeSession).]', []),
        ('Tipe Soal dan Algoritma Penilaian', '[ISI: Listening, Reading, Typing; bentuk soal; penilaian di server (finishExercise, submitTestPart); pencocokan Typing dengan toleransi dan tinjauan guru. Algoritma 5.4 Pencocokan Jawaban Typing (typing_matcher.js: normalisasi, matchHanzi, matchPinyin); Algoritma 5.5 Penilaian Tes Simulasi HSK per Bagian (nilai per bagian dari 100, lulus 60 %, soal uraian ke antrean penilaian).]', []),
        ('Sistem Level dan Kenaikan Tingkat', '[ISI: HSK 1–6, ambang 60 %, minCodes, leaderboard per kode tes, persetujuan admin. Algoritma 5.6 Kenaikan Tingkat (promotion.js: countsAt, promotionState); Algoritma 5.7 Rekomendasi Tingkat Tes Penempatan (placement.js: lulus = tingkat kertas + 1, gagal = tingkat kertas).]', []),
        ('Laporan Progress', '[ISI: progress_summary, lima peringatan, pembaruan oleh trigger dan pekerjaan harian. Algoritma 5.8 Peringatan Progress Murid (progress.js: warningsOf; kehadiran 30 hari, rata-rata latihan 14 hari turun, tidak berlatih n hari, sisa sesi atau masa berlaku, dua tes gagal berturut-turut).]', []),
        ('Pemodelan Sistem Baru', '[ISI: use case dan activity diagram per peran (Gambar 5.x).]', [
            ('Use Case Diagram', '[ISI]'), ('Activity Diagram', '[ISI]')]),
        ('Arsitektur Sistem', '[ISI: Flutter (MVVM) – Firebase (Auth, Firestore, Storage, FCM, Functions, Hosting) – Midtrans; Gambar 5.x.]', []),
        ('Desain Basis Data', '[ISI: koleksi Firestore dan field utamanya (Tabel 5.x per koleksi).]', []),
        ('Aturan Akses', '[ISI: ringkasan Firestore Security Rules per koleksi dan peran.]', []),
        ('Daftar Cloud Functions', '[ISI: tabel fungsi: nama, pemicu, tugas.]', []),
        ('Desain Antarmuka', '[ISI: sitemap dan rancangan halaman utama per peran.]', []),
    ]),
    6: ('IMPLEMENTASI', '[ISI: paragraf pembuka Bab VI.]', [
        ('Implementasi Desain', '[ISI: satu tangkapan layar dan satu paragraf per halaman; sumber docs/screenshots/.]', [
            ('Halaman Umum', '[ISI: login, registrasi, halaman tunggu persetujuan, tes penempatan.]'),
            ('Halaman Admin', '[ISI: dashboard, pengguna dan persetujuan, bank soal dan kode tes, jadwal, sesi, voucher dan harga, pembayaran, promosi, laporan.]'),
            ('Halaman Guru', '[ISI: jadwal mengajar, pelaksanaan sesi dan absensi, paket latihan, sesi tes, antrean penilaian, progress murid.]'),
            ('Halaman Murid', '[ISI: beranda, pemesanan sesi, voucher dan pembayaran, latihan, tes, nilai dan leaderboard, progress.]')]),
        ('Implementasi Program', '[ISI: segmen program dengan style [STTS] Segmen Program, Courier New 10, bernomor per bab; tiap segmen paling banyak sekitar 25 baris dan selalu diikuti satu paragraf penjelasan; kode yang panjang dipindahkan ke Lampiran E.]', [
            ('Inisialisasi Aplikasi dan Pengalihan Peran', '[ISI: Segmen Program 6.1 inisialisasi Firebase di lib/main.dart; Segmen Program 6.2 pengalihan halaman menurut peran dan status akun (lib/app.dart).]'),
            ('Aturan Akses Firestore', '[ISI: Segmen Program 6.3 aturan koleksi exercise_results dan schedules (hanya fungsi yang menulis).]'),
            ('Penjadwalan dan Pemesanan Sesi', '[ISI: Segmen Program 6.4 fungsi conflicts dan overlaps (scheduling.js); Segmen Program 6.5 saveSchedule dengan transaksi dan schedule_locks; Segmen Program 6.6 bookSession dan bookingRefusal.]'),
            ('Penutupan Sesi dan Voucher', '[ISI: Segmen Program 6.7 closeSession: satu transaksi, dokumen voucher_history sebagai kunci idempoten, rekap guru.]'),
            ('Penilaian Latihan dan Tes', '[ISI: Segmen Program 6.8 normalisasi dan matchHanzi/matchPinyin (typing_matcher.js); Segmen Program 6.9 finishExercise: nilai per bagian dan antrean penilaian.]'),
            ('Kenaikan Tingkat', '[ISI: Segmen Program 6.10 countsAt dan promotionState (promotion.js) dalam trigger onTestResultWritten.]'),
            ('Pembayaran Midtrans', '[ISI: Segmen Program 6.11 createInvoice dan Snap token; Segmen Program 6.12 penanganan notifikasi pembayaran dan pembuatan term voucher (payments.js).]'),
            ('Laporan Progress', '[ISI: Segmen Program 6.13 warningsOf (progress.js); Segmen Program 6.14 grafik StudentProgressReport dengan fl_chart.]'),
            ('Pemutar Latihan di Flutter', '[ISI: Segmen Program 6.15 pengiriman jawaban sekali ke finishExercise dan tampilan ulasan.]')]),
    ]),
    7: ('UJI COBA', '[ISI: paragraf pembuka Bab VII: uji coba dilakukan pada [ISI: tanggal] di Easy Study dengan 35 responden.]', [
        ('Uji Coba Kompatibilitas', '[ISI: Chrome, Edge, Safari, Android, Safari iPhone (web), beberapa ukuran layar; Tabel 7.1.]', []),
        ('Black-box Testing', '[ISI: tabel per peran: kasus normal dan kasus ditolak; lengkap di Lampiran E.]', [
            ('Admin', '[ISI]'), ('Guru', '[ISI]'), ('Murid', '[ISI]')]),
        ('Validasi Fungsional', '[ISI: 24 skenario (TS, PN, LV, LB, PL, VC, MT, …) dengan hasil dan bukti; PN-01 200 jawaban.]', []),
        ('User-based Testing', '[ISI: lembar tugas per peran, waktu, keberhasilan.]', []),
        ('Hasil Kuesioner System Usability Scale', '[ISI: skor per responden (Lampiran D), rata-rata, interpretasi; target > 70.]', []),
    ]),
    8: ('PENUTUP', '[ISI: paragraf pembuka Bab VIII.]', [
        ('Kesimpulan', '[ISI: tepat lima butir, satu untuk setiap tujuan pada Bab I subbab 1.2 dengan urutan yang sama (permintaan pembimbing 2026-11-25), masing-masing dengan angka pembuktinya dari Bab VII (skenario lulus, akurasi pencocokan, rata-rata SUS).]', []),
        ('Saran', '[ISI: dari komentar responden dan fitur di luar lingkup (antarmuka Inggris, peran orang tua, materi, HSK 3.0, pembaca naskah).]', []),
    ]),
}
def render_skeleton(c):
    title, intro, subs = SKELETON[c]
    blocks = [('p', intro)]
    for sub, note, subsubs in subs:
        blocks.append(('h2', sub)); blocks.append(('p', note))
        for ss, nn in subsubs:
            blocks.append(('h3', ss)); blocks.append(('p', nn))
    return render_chapter(c, title, blocks)

# ---------------------------------------------------------------- front matter
def cover_table():
    t = raw(1)
    spec = {0: ['TUGAS AKHIR'], 2: [F['judul_lines'][0]], 3: [F['judul_lines'][1]],
            7: [F['nama']], 8: [F['nrp']], 9: ['PROGRAM SARJANA'], 10: ['PROGRAM STUDI %s' % F['prodi'].upper()],
            11: ['FAKULTAS %s' % F['fakultas'].upper()], 14: [F['tahun']]}
    pieces = re.split(r'(<w:p(?: [^>]*)?>.*?</w:p>)', t, flags=re.S)
    k = 0; out = []
    for pc in pieces:
        if re.match(r'<w:p(?: [^>]*)?>', pc, re.S) and pc.endswith('</w:p>'):
            out.append(rebuild_par(pc, spec[k]) if k in spec else pc)
            if k == 3:
                out.append(rebuild_par(pc, [F['judul_lines'][2]]))
            k += 1
        else:
            out.append(pc)
    return ''.join(out)

def pengesahan():
    out = []
    spec = {2: ['TUGAS AKHIR'], 4: [F['judul_lines'][0]], 5: [F['judul_lines'][1]], 8: [F['gelar']],
            13: ['Disetujui oleh Tim Penguji Tugas Akhir:'],
            14: [F['pembimbing'], '\t', '(Pembimbing)'], 15: [F['co'], '\t', '(Co-Pembimbing)'],
            16: [], 17: [], 18: [],   # owner removed the examiner lines in Word (2026-11-24); the paragraphs stay empty
            21: [F['bulan_sidang']]}
    for i in range(2, 22):
        p = raw(i)
        out.append(rebuild_par(p, spec[i]) if i in spec else p)
        if i == 5:
            out.append(rebuild_par(p, [F['judul_lines'][2]]))
    return out

def pernyataan():
    out = []
    spec = {26: ['Nama', '\t', ': ', F['nama']], 27: ['Fakultas/ Prodi', '\t', ': ', 'Prog Prof S1 Informatika'],   # owner's wording in Word (2026-11-24)
            28: ['NRP', '\t', ': ', F['nrp']],
            30: ['dengan ini menyatakan bahwa isi sebagian maupun keseluruhan Tugas Akhir dengan judul:'],
            32: [F['judul_lines'][0]], 33: [F['judul_lines'][1]],
            43: ['\t', 'Surabaya, ', F['tgl_pernyataan']], 44: ['\t', 'Yang Membuat Pernyataan,'], 50: [F['nama']], 51: ['\t', F['nrp']]}
    b1, b2 = bookmark('pernyataan')
    for i in range(22, 52):
        p = raw(i)
        q = rebuild_par(p, spec[i]) if i in spec else p
        if i == 22:
            q = q.replace('<w:r>', b1 + '<w:r>', 1).replace('</w:p>', b2 + '</w:p>')
        out.append(q)
        if i == 33:
            out.append(rebuild_par(p, [F['judul_lines'][2]]))
    C.toc.append(('front', '', 'SURAT PERNYATAAN KEASLIAN', 'pernyataan'))
    return out

ABSTRAK_ID = [
    'Easy Study adalah lembaga kursus bahasa Mandarin di Surabaya dengan empat guru yang mengajar kelas tatap muka dari tingkat HSK 1 sampai HSK 6. Sebelum tugas akhir ini dikerjakan, tidak ada jadwal guru dan kelas yang tertulis, sedangkan pendaftaran murid, kehadiran, pembayaran, sisa sesi paket kursus, latihan, dan nilai tes simulasi HSK dicatat secara manual dan terpisah melalui WhatsApp, spreadsheet, kertas, dan sebuah aplikasi web sederhana, sehingga pemakaian guru dan ruang tidak terpantau, data tersebar, dan perkembangan belajar murid sulit dipantau.',
    'Tugas akhir ini merancang dan membangun Aplikasi Multiplatform Sistem Kursus Bahasa Mandarin Easy Study menggunakan Flutter dengan Firebase sebagai backend. Aplikasi ini melayani tiga peran, yaitu admin, guru, dan murid, pada web, Android, dan iOS dari satu basis kode. Fitur utamanya adalah penjadwalan guru dengan pengecekan bentrok otomatis dan penunjukan guru pengganti, pemesanan sesi kelas dan absensi digital, voucher kursus yang berkurang secara otomatis dalam satu transaksi, latihan dan tes simulasi HSK daring bertipe Listening, Reading, dan Typing yang dinilai di sisi server melalui Cloud Functions, kenaikan tingkat HSK berdasarkan kelulusan tes beserta leaderboard, tes penempatan, laporan progress murid, dan pembayaran daring melalui Midtrans.',
    'Aplikasi diuji dengan pengujian otomatis pada Firebase Emulator Suite, black-box testing, validasi fungsional dengan 24 skenario, user-based testing, dan kuesioner System Usability Scale bersama 35 responden di Easy Study. Hasilnya, ⟦24⟧ dari 24 skenario lulus, pencocokan jawaban Typing mencapai akurasi ⟦100⟧ % pada ⟦200⟧ jawaban uji, dan rata-rata skor SUS sebesar ⟦75⟧ (di atas ambang 70), sehingga aplikasi dinilai layak dipakai untuk menggantikan proses manual di Easy Study.',
]
KATA_KUNCI = 'Kata kunci: Flutter, Firebase, kursus bahasa Mandarin, HSK, penjadwalan guru, voucher kursus, System Usability Scale'
ABSTRACT_EN = [
    'Easy Study is a Mandarin course centre in Surabaya with four teachers who teach face-to-face classes from HSK 1 to HSK 6. Before this final project there was no written teacher or class schedule, while student registration, attendance, payments, the remaining sessions of course packages, exercises and HSK mock-test scores were recorded manually and separately through WhatsApp, spreadsheets, paper and a simple web page, so the use of teachers and rooms was not tracked, data was scattered and student progress was hard to monitor.',
    'This final project designs and builds the Multiplatform Application for the Easy Study Mandarin Course System using Flutter with Firebase as the backend. The application serves three roles, namely admin, teacher and student, on web, Android and iOS from one code base. Its main features are teacher scheduling with automatic clash checking and substitute teachers, class session booking with digital attendance, course vouchers that are deducted automatically in one transaction, online HSK exercises and mock tests of the Listening, Reading and Typing types scored on the server through Cloud Functions, HSK level promotion based on passed tests with a leaderboard, a placement test, student progress reports and online payment through Midtrans.',
    'The application was tested with automated tests on the Firebase Emulator Suite, black-box testing, functional validation with 24 scenarios, user-based testing and the System Usability Scale questionnaire with 35 respondents at Easy Study. As a result, ⟦24⟧ of 24 scenarios passed, Typing answer matching reached an accuracy of ⟦100⟧ % on ⟦200⟧ test answers, and the mean SUS score was ⟦75⟧ (above the 70 threshold), so the application is considered fit to replace the manual process at Easy Study.',
]
KEYWORDS = 'Keywords: Flutter, Firebase, Mandarin course, HSK, teacher scheduling, course voucher, System Usability Scale'

def front_part(title, bk, paras, first=False):
    out = [p_judulbab(title, pre='' if first else PAGEBREAK, bk=bk), p_judulbab()]
    out += paras
    C.toc.append(('front', '', title, bk))
    return out

def kata_pengantar():
    out = []
    out.append(p_body('Puji syukur penulis panjatkan kepada Tuhan Yang Maha Esa atas rahmat dan karunia-Nya, sehingga penulis dapat menyelesaikan Tugas Akhir yang berjudul "%s". Dalam pengerjaan Tugas Akhir ini penulis tidak lepas dari bantuan dan dorongan berbagai pihak. Oleh karena itu, melalui kesempatan ini penulis mengucapkan terima kasih kepada:' % F['judul']))
    n = new_num(A_DEC_ID)
    for t in [
        'Kedua orang tua dan keluarga penulis, yang senantiasa memberikan dukungan selama proses studi hingga penyusunan Tugas Akhir.',
        'Yang terhormat Bapak %s selaku dosen pembimbing yang telah membimbing, memberikan pengarahan, kritik, dan saran kepada penulis sehingga Tugas Akhir ini dapat terselesaikan dengan baik.' % F['pembimbing'],
        'Yang terhormat Ibu %s selaku dosen co-pembimbing yang telah memberikan bimbingan dan masukan untuk menyelesaikan Tugas Akhir ini.' % F['co'],
        'Pemilik, admin, guru, dan murid Easy Study yang telah memberikan data, waktu, dan kesediaannya menjadi responden uji coba.',
        'Seluruh dosen pengajar Institut Sains dan Teknologi Terpadu Surabaya yang telah memberikan pengetahuan kepada penulis selama proses belajar mengajar.',
        'Seluruh teman dan mahasiswa yang saling memberikan dorongan, semangat, dan dukungan selama pengerjaan Tugas Akhir.',
    ]:
        out.append(p_list(t, n, 567, 567))
    out.append(p_body('Penulis berharap Tugas Akhir ini dapat bermanfaat bagi penulis maupun pembaca pada umumnya. Penulis menyadari bahwa Tugas Akhir ini masih jauh dari sempurna, sehingga penulis mengharapkan kritik dan saran yang membangun dari pembaca.'))
    out += [p_empty(), p_empty(), p_style('STTSKeteranganKataPengantar', 'Surabaya, %s' % F['bulan_kata_pengantar']), p_style('STTSKeteranganKataPengantar'), p_style('STTSKeteranganKataPengantar', 'Penulis')]
    return out

def toc_line(kind, number, title, page_xml):
    if kind == 'front':
        tabs = '<w:tab w:val="right" w:leader="dot" w:pos="7230"/><w:tab w:val="right" w:pos="7938"/>'
        body = runs(title) + TAB + TAB + page_xml
    elif kind == 'bab':
        tabs = '<w:tab w:val="left" w:pos="993"/><w:tab w:val="right" w:leader="dot" w:pos="7230"/><w:tab w:val="right" w:pos="7938"/>'
        body = runs(number) + TAB + runs(title) + TAB + TAB + page_xml
    elif kind == 'sub':
        tabs = '<w:tab w:val="left" w:pos="993"/><w:tab w:val="left" w:pos="1560"/><w:tab w:val="right" w:leader="dot" w:pos="7230"/><w:tab w:val="right" w:pos="7938"/>'
        body = TAB + runs(number) + TAB + runs(title) + TAB + TAB + page_xml
    elif kind == 'subsub':
        tabs = '<w:tab w:val="left" w:pos="993"/><w:tab w:val="left" w:pos="1560"/><w:tab w:val="left" w:pos="2268"/><w:tab w:val="right" w:leader="dot" w:pos="7230"/><w:tab w:val="right" w:pos="7938"/>'
        body = TAB + TAB + runs(number) + TAB + runs(title) + TAB + TAB + page_xml
    else:  # lists of figures etc.
        tabs = '<w:tab w:val="left" w:pos="709"/><w:tab w:val="right" w:leader="dot" w:pos="7230"/><w:tab w:val="right" w:pos="7938"/>'
        body = runs(number) + TAB + runs(title) + TAB + TAB + page_xml
    return P('<w:pStyle w:val="STTSNormalDaftarIsi"/><w:tabs>%s</w:tabs><w:ind w:left="%d" w:hanging="%d"/>' % (
        tabs, {'front': 0, 'bab': 993, 'sub': 1560, 'subsub': 2268}.get(kind, 709), {'front': 0, 'bab': 993, 'sub': 1560, 'subsub': 2268}.get(kind, 709)), body)

def daftar_isi():
    out = [p_style('STTSKeteranganDaftarIsi', 'Halaman')]
    out.append(toc_line('front', '', 'HALAMAN JUDUL', runs('i')))
    out.append(toc_line('front', '', 'HALAMAN PENGESAHAN', runs('ii')))
    for kind, number, title, bk in C.toc:
        out.append(toc_line(kind, number, title, pageref(bk)))
    for code, name in [('A', 'DIAGRAM UKURAN PENUH'), ('B', 'SEGMEN PROGRAM'), ('C', 'DAFTAR RESPONDEN'), ('D', 'JAWABAN KUESIONER SUS'),
                       ('E', 'TABEL BLACK-BOX TESTING'), ('F', 'DAFTAR SOAL'), ('G', 'CATATAN WAWANCARA')]:
        out.append(toc_line('front', '', '⟦LAMPIRAN %s %s⟧' % (code, name), runs('⟦%s-1⟧' % code)))
    return out

def daftar_list(label, items, empty_note):
    out = [P('<w:pStyle w:val="STTSKeteranganDaftar"/><w:tabs><w:tab w:val="right" w:pos="7938"/></w:tabs>', runs(label) + TAB + runs('Halaman'))]
    if not items:
        out.append(p_style('STTSNormalDaftarIsi', empty_note))
    for number, title, bk in items:
        out.append(toc_line('list', number, title, pageref(bk)))
    return out

# ---------------------------------------------------------------- back matter
def daftar_pustaka():
    out = [p_judulbab('DAFTAR PUSTAKA', bk='pustaka')]
    C.toc.append(('front', '', 'DAFTAR PUSTAKA', 'pustaka'))
    out.append(P('<w:pStyle w:val="STTSDarftarPustakaNormal"/><w:spacing w:line="360" w:lineRule="auto"/>'))
    text = open(os.path.join(DOCS, 'DAFTAR_PUSTAKA.md'), encoding='utf8').read()
    for m in re.finditer(r'^(\d+)\. (.*?)(?=\n\d+\. |\Z)', text, re.M | re.S):
        entry = ' '.join(m.group(2).split()).replace(' (*)', '').replace('(*)', '').strip()
        body = ''
        for seg in re.split(r'(\*[^*]+\*)', entry):
            if not seg:
                continue
            if seg.startswith('*') and seg.endswith('*'):
                body += runs(seg[1:-1], '<w:i/><w:iCs/>')
            else:
                body += runs(seg)
        out.append(P('<w:pStyle w:val="STTSDarftarPustakaNormal"/><w:ind w:left="567" w:hanging="567"/><w:jc w:val="both"/>', runs('[%s]' % m.group(1)) + TAB + body))
        out.append(p_style('STTSDarftarPustakaNormal'))
    return out

def riwayat_hidup():
    out = [p_judulbab('RIWAYAT HIDUP', bk='riwayat'), p_judulbab()]
    C.toc.append(('front', '', 'RIWAYAT HIDUP', 'riwayat'))
    photo = raw(400)
    photo = re.sub(r'r:embed="rId\d+"', 'r:embed="rIdFoto"', photo)
    photo = re.sub(r'<wp:docPr id="\d+"', '<wp:docPr id="199"', photo)
    if FOTO == _FOTO:                                   # keep the frame's height, take the photo's own proportion
        pw, ph = _png_size(FOTO)
        def fit(m):
            cy = int(m.group(3)); return '%s cx="%d" cy="%d"' % (m.group(1), round(cy * pw / ph), cy)
        photo = re.sub(r'(<wp:extent|<a:ext) cx="(\d+)" cy="(\d+)"', fit, photo)
    out.append(photo)
    t = raw(401)
    t = re.sub(r'<w:p(?: [^>]*)?>(?:(?!</w:p>).)*Ten Chittapon Leechaiyapornkul.*?</w:p>', lambda m: rebuild_par(m.group(0), [F['nama']]), t, flags=re.S)
    t = re.sub(r'<w:p(?: [^>]*)?>(?:(?!</w:p>).)*SMTown.*?</w:p>', lambda m: rebuild_par(m.group(0), [PRIV.get('alamat', '[ISI: alamat asal]')]), t, flags=re.S)
    t = re.sub(r'<w:p(?: [^>]*)?>(?:(?!</w:p>).)*Bangkok, 28 Februari 1996.*?</w:p>', lambda m: rebuild_par(m.group(0), [PRIV.get('ttl', '[ISI: tempat, tanggal lahir]')]), t, flags=re.S)
    out.append(t)
    out.append(p_judulbab())
    out.append(raw(403))
    for years, school in [tuple(x) for x in PRIV.get('sekolah', [['[ISI: tahun]', '[ISI: SD]'], ['[ISI: tahun]', '[ISI: SMP]'], ['[ISI: tahun]', '[ISI: SMA]']])] + [('2021 – ⟦2027⟧', 'Institut Sains dan Teknologi Terpadu Surabaya, Surabaya')]:   # owner 2026-11-25: started in 2021
        out.append(P('<w:pStyle w:val="ListParagraph"/><w:numPr><w:ilvl w:val="0"/><w:numId w:val="12"/></w:numPr><w:tabs><w:tab w:val="left" w:pos="2835"/></w:tabs><w:ind w:left="426" w:hanging="426"/>', runs(years) + TAB + runs(school)))
    out.append(p_body('(Program Studi S1 Informatika)', '<w:ind w:left="2835" w:firstLine="0"/>'))
    out.append(p_empty())
    out.append(rebuild_par(raw(403), ['Pengalaman Kerja:']))
    for years, job in [tuple(x) for x in PRIV.get('kerja', [['[ISI: tahun]', '[ISI: pekerjaan atau tulis "–" bila belum ada]']])]:
        out.append(P('<w:pStyle w:val="ListParagraph"/><w:numPr><w:ilvl w:val="0"/><w:numId w:val="12"/></w:numPr><w:tabs><w:tab w:val="left" w:pos="426"/><w:tab w:val="left" w:pos="3686"/></w:tabs><w:ind w:left="3686" w:hanging="3686"/>', runs(years) + TAB + runs(job)))
    return out

# ---------------------------------------------------------------- assemble
chapters = []   # (xml list) built first so the lists know every bookmark
md = {1: 'BAB_I_PENDAHULUAN.md', 2: 'BAB_II_TEORI_PENUNJANG.md', 3: 'BAB_III_PROSES_BISNIS.md', 4: 'BAB_IV_ANALISA_SISTEM.md', 5: 'BAB_V_DESAIN_SISTEM.md',
      6: 'BAB_VI_IMPLEMENTASI.md'}
chapter_xml = {}
for c in range(1, 9):
    if c in md:
        title, blocks = parse_md(os.path.join(DOCS, md[c]))
        assert ROMAN[title[0].split()[1]] == c, title
        chapter_xml[c] = render_chapter(c, title[1], blocks)
    else:
        chapter_xml[c] = render_skeleton(c)
pustaka_xml = daftar_pustaka()
riwayat_xml = riwayat_hidup()

body = []
body.append(cover_table())
body += pengesahan()                                   # ends with the cover section break
body += pernyataan()
body += front_part('ABSTRAK', 'abstrak', [p_style('STTSNormalAbstrak', t) for t in ABSTRAK_ID] + [p_style('STTSNormalAbstrak'), p_style('STTSNormalAbstrak', KATA_KUNCI, '<w:ind w:firstLine="0"/>')])
body += front_part('ABSTRACT', 'abstract', [p_style('STTSNormalAbstrak', t) for t in ABSTRACT_EN] + [p_style('STTSNormalAbstrak'), p_style('STTSNormalAbstrak', KEYWORDS, '<w:ind w:firstLine="0"/>')])
body += front_part('KATA PENGANTAR', 'kata_pengantar', kata_pengantar())
# the lists are built after every chapter bookmark exists; their own entries come first in the order of the book
front_lists = [('DAFTAR ISI', 'daftar_isi'), ('DAFTAR GAMBAR', 'daftar_gambar'), ('DAFTAR TABEL', 'daftar_tabel'),
               ('DAFTAR ALGORITMA', 'daftar_algoritma'), ('DAFTAR SEGMEN PROGRAM', 'daftar_segmen'), ('DAFTAR RUMUS', 'daftar_rumus')]
# TOC order: front parts (already appended: pernyataan, abstrak, abstract, kata pengantar), then the lists, then chapters, pustaka, riwayat
chapter_toc = [e for e in C.toc if e[0] in ('bab', 'sub', 'subsub')]
front_toc = [e for e in C.toc if e[0] == 'front' and e[3] not in ('pustaka', 'riwayat')]
back_toc = [e for e in C.toc if e[3] in ('pustaka', 'riwayat')]
C.toc = front_toc + [('front', '', t, b) for t, b in front_lists] + chapter_toc + back_toc
body += front_part('DAFTAR ISI', 'daftar_isi', daftar_isi())
body += front_part('DAFTAR GAMBAR', 'daftar_gambar', daftar_list('Gambar', C.gambar, ''))
body += front_part('DAFTAR TABEL', 'daftar_tabel', daftar_list('Tabel', C.tabel, ''))
body += front_part('DAFTAR ALGORITMA', 'daftar_algoritma', daftar_list('Algoritma', C.algoritma, '[ISI: terisi otomatis setelah algoritma Bab V ditulis.]'))
body += front_part('DAFTAR SEGMEN PROGRAM', 'daftar_segmen', daftar_list('Segmen Program', C.segmen, '[ISI: terisi otomatis setelah segmen program Bab VI ditulis.]'))
body += front_part('DAFTAR RUMUS', 'daftar_rumus', daftar_list('Rumus', C.rumus, ''))
body.append(sect_par(SECT_FRONT, 'STTSNormalDaftarIsi'))
for c in range(1, 9):
    body += chapter_xml[c]
    body.append(sect_par(SECT_BAB1 if c == 1 else SECT_BAB))
body += pustaka_xml
body.append(sect_par(SECT_BAB))
body += riwayat_xml

document = HEAD + ''.join(body) + SECT_END + '</w:body></w:document>'
files['word/document.xml'] = document.encode('utf8')

# numbering
pos = numxml.index('<w:num ')
numxml = numxml[:pos] + ''.join(C.abstract_nums) + numxml[pos:]
numxml = numxml.replace('</w:numbering>', ''.join(C.nums) + '</w:numbering>')
files['word/numbering.xml'] = numxml.encode('utf8')

# relationships: keep what the document references, add the figures
rels = files['word/_rels/document.xml.rels'].decode('utf8')
used = set(re.findall(r'r:(?:embed|id|link)="(rId\d+)"', document))
def keep(m):
    rid = re.search(r'Id="([^"]+)"', m.group(0)).group(1)
    typ = re.search(r'Type="[^"]*/([a-zA-Z]+)"', m.group(0)).group(1)
    if typ in ('image', 'hdphoto') and rid not in used:
        files.pop('word/' + re.search(r'Target="([^"]+)"', m.group(0)).group(1), None)
        return ''
    return m.group(0)
rels = re.sub(r'<Relationship [^>]*/>', keep, rels)
add = ''
for rid, png in C.fig_files.items():
    name = os.path.basename(png)
    files['word/media/' + name] = open(png, 'rb').read()
    add += '<Relationship Id="%s" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/%s"/>' % (rid, name)
files['word/media/foto_placeholder.png'] = open(FOTO, 'rb').read()   # the media name stays; the bytes are the private photo for a local build
add += '<Relationship Id="rIdFoto" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/foto_placeholder.png"/>'
files['word/_rels/document.xml.rels'] = rels.replace('</Relationships>', add + '</Relationships>').encode('utf8')

# footnotes, settings, content type, title
fn = files['word/footnotes.xml'].decode('utf8')
files['word/footnotes.xml'] = re.sub(r'<w:footnote w:id="[1-9]\d*".*?</w:footnote>', '', fn, flags=re.S).encode('utf8')
st = files['word/settings.xml'].decode('utf8')
if 'w:updateFields' not in st:
    st = st.replace('<w:hdrShapeDefaults>', '<w:updateFields w:val="true"/><w:hdrShapeDefaults>', 1)
files['word/settings.xml'] = st.encode('utf8')
files['[Content_Types].xml'] = files['[Content_Types].xml'].decode('utf8').replace('wordprocessingml.template.main+xml', 'wordprocessingml.document.main+xml').encode('utf8')
core = files['docProps/core.xml'].decode('utf8')
core = re.sub(r'<dc:title>.*?</dc:title>', '', core)
core = core.replace('<dc:creator>', '<dc:title>%s</dc:title><dc:creator>' % escape(F['judul'].upper()), 1)
files['docProps/core.xml'] = core.encode('utf8')

os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
with zipfile.ZipFile(OUT, 'w', zipfile.ZIP_DEFLATED) as zo:
    zo.writestr('[Content_Types].xml', files.pop('[Content_Types].xml'))
    for n, data in files.items():
        zo.writestr(n, data)
print('body elements', len(body), '| toc', len(C.toc), '| gambar', len(C.gambar), '| tabel', len(C.tabel), '| rumus', len(C.rumus), '| bookmarks', C.bk, '->', OUT)
