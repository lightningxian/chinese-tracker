"""Build one thesis chapter .docx from the ISTTS template and a markdown draft.
usage: build_bab.py template.dotx chapter.md out.docx [figure.png]
Stdlib only. Keeps the template's styles, numbering, headers and footers;
replaces the body with the chapter; strips unused media and sample footnotes.
"""
import sys, re, zipfile, os, html
from xml.sax.saxutils import escape

tpl, mdpath, out = sys.argv[1], sys.argv[2], sys.argv[3]
figpng = sys.argv[4] if len(sys.argv) > 4 else None

z = zipfile.ZipFile(tpl)
files = {n: z.read(n) for n in z.namelist()}
doc = files['word/document.xml'].decode('utf8')

# ---------- pieces of the template we keep ----------
head = doc[:doc.index('<w:body>') + len('<w:body>')]
m = re.search(r'<w:sectPr w:rsidR="00204CC0" w:rsidSect="00C22F25">.*?</w:sectPr>', doc, re.S)
assert m, 'Bab I sectPr not found'
sect = re.sub(r' w:rsid\w+="[^"]*"', '', m.group(0))
sect = re.sub(r'<w:pgNumType w:start="1"\s*/>', '<w:pgNumType w:start="%s"/>' % os.environ.get('PAGE_START', '1'), sect)
assert 'xmlns:r=' in head and 'xmlns:wp=' in head, 'missing namespaces'

# ---------- run / paragraph builders ----------
ISI = re.compile(r'(\[ISI:[^\]]*\])')
def runs(text, rpr=''):
    out = []
    for seg in ISI.split(text):
        if not seg: continue
        hl = '<w:highlight w:val="yellow"/>' if ISI.fullmatch(seg) else ''
        r = (rpr + hl)
        out.append('<w:r>%s<w:t xml:space="preserve">%s</w:t></w:r>' % ('<w:rPr>%s</w:rPr>' % r if r else '', escape(seg)))
    return ''.join(out)
def P(ppr='', body=''):
    return '<w:p>%s%s</w:p>' % ('<w:pPr>%s</w:pPr>' % ppr if ppr else '', body)
def p_style(style, text=''):
    return P('<w:pStyle w:val="%s"/>' % style, runs(text) if text else '')
def p_body(text, ind=''):
    return P(ind, runs(text))
def p_empty(): return '<w:p/>'
def p_sub(text):   # 1.x heading, auto-numbered by num 11 ("1.%1")
    return P('<w:pStyle w:val="STTSJudulSubBab"/><w:numPr><w:ilvl w:val="0"/><w:numId w:val="11"/></w:numPr><w:ind w:hanging="720"/>', runs(text))
def p_subsub(text, numid):  # 1.3.x heading
    return P('<w:pStyle w:val="STTSJudulSubBab"/><w:numPr><w:ilvl w:val="0"/><w:numId w:val="%d"/></w:numPr><w:ind w:left="851" w:hanging="851"/>' % numid, runs(text))
def p_list(text, numid, left, hanging, ilvl=0):
    return P('<w:pStyle w:val="ListParagraph"/><w:numPr><w:ilvl w:val="%d"/><w:numId w:val="%d"/></w:numPr><w:ind w:left="%d" w:hanging="%d"/>' % (ilvl, numid, left, hanging), runs(text))
def p_sistematika(title):
    bab, judul = [s.strip() for s in title.split(' : ', 1)]
    body = runs(bab) + '<w:r><w:tab/><w:t>:</w:t></w:r><w:r><w:tab/></w:r>' + runs(judul)
    return P('<w:numPr><w:ilvl w:val="0"/><w:numId w:val="12"/></w:numPr><w:tabs><w:tab w:val="left" w:pos="1418"/><w:tab w:val="left" w:pos="1985"/></w:tabs><w:ind w:left="426" w:hanging="426"/>', body)
def p_sistematika_desc(text):
    return P('<w:ind w:left="1985" w:firstLine="0"/>', runs(text))
def p_figure(rid, cx, cy, name, docpr_id=101):
    d = ('<w:r><w:rPr><w:noProof/></w:rPr><w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0">'
         '<wp:extent cx="%d" cy="%d"/><wp:effectExtent l="0" t="0" r="0" b="0"/>'
         '<wp:docPr id="%d" name="%s"/><wp:cNvGraphicFramePr><a:graphicFrameLocks xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" noChangeAspect="1"/></wp:cNvGraphicFramePr>'
         '<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
         '<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:nvPicPr><pic:cNvPr id="0" name="%s"/><pic:cNvPicPr/></pic:nvPicPr>'
         '<pic:blipFill><a:blip r:embed="%s"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
         '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="%d" cy="%d"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic>'
         '</a:graphicData></a:graphic></wp:inline></w:drawing></w:r>') % (cx, cy, docpr_id, name, name, rid, cx, cy)
    return P('<w:pStyle w:val="STTSGambar"/>', d)

# ---------- parse the markdown draft ----------
lines = open(mdpath, encoding='utf8').read().split('\n')
blocks = []   # (kind, payload)
i = 0
title_lines = []
while i < len(lines):
    ln = lines[i]
    if not ln.strip(): i += 1; continue
    if ln.startswith('# '):
        title_lines.append(ln[2:].strip()); i += 1; continue
    if ln.startswith('## '):
        t = re.sub(r'^\d+(\.\d+)*\s+', '', ln[3:].strip()); blocks.append(('h2', t)); i += 1; continue
    if ln.startswith('### '):
        t = re.sub(r'^\d+(\.\d+)*\s+', '', ln[4:].strip()); blocks.append(('h3', t)); i += 1; continue
    m_num = re.match(r'^(\d+)\. (.*)$', ln)
    m_bul = re.match(r'^- (.*)$', ln)
    m_let = re.match(r'^([a-z])\. (\S.*)$', ln)
    if m_num or m_bul or m_let:
        kind = 'num' if m_num else ('bul' if m_bul else 'let')
        first = (m_num or m_bul or m_let).group(m_num and 2 or 1) if not m_let else m_let.group(2)
        if m_num: first = m_num.group(2)
        if m_bul: first = m_bul.group(1)
        cont = []
        i += 1
        while i < len(lines) and lines[i].strip() and re.match(r'^\s+\S', lines[i]):
            cont.append(lines[i].strip()); i += 1
        blocks.append((kind, first, ' '.join(cont)))
        continue
    # paragraph
    para = [ln.strip()]; i += 1
    while i < len(lines) and lines[i].strip() and not re.match(r'^(#|\d+\. |- |[a-z]\. \S)', lines[i]):
        para.append(lines[i].strip()); i += 1
    text = ' '.join(para)
    if text.startswith('[GAMBAR'):
        blocks.append(('fig', text))
    elif re.match(r'^Gambar \d+\.\d+\b', para[0]) and len(para) >= 2:
        blocks.append(('cap', para[0], ' '.join(para[1:])))
    else:
        blocks.append(('p', text))

# ---------- numbering instances ----------
NUM_SUBSUB = 100
num_lists = []          # one restart per numbered list
LET_NUM = 120
chapter_no = int(re.search(r'\d+', re.sub(r'BAB\s+([IVX]+)', lambda m: str({'I':1,'II':2,'III':3,'IV':4,'V':5,'VI':6,'VII':7,'VIII':8}[m.group(1)]), title_lines[0])).group(0))

body = []
body += [p_style('STTSJudulBab', title_lines[0]), p_style('STTSJudulBab', title_lines[1]), p_style('STTSJudulBab')]
cur_h2 = 0; cur_h3 = 0; in_sistematika = False
prev_kind = None; cur_num = None
for b in blocks:
    kind = b[0]
    if kind in ('h2', 'h3'):
        body.append(p_empty())
        if kind == 'h2':
            cur_h2 += 1; cur_h3 = 0
            in_sistematika = b[1].lower().startswith('sistematika')
            body.append(p_sub(b[1]))
        else:
            cur_h3 += 1
            body.append(p_subsub(b[1], NUM_SUBSUB + cur_h2))   # one num per parent sub-bab
    elif kind == 'p':
        body.append(p_body(b[1]))
    elif kind == 'num':
        if prev_kind != 'num':
            cur_num = 101 + len(num_lists); num_lists.append(cur_num)
        body.append(p_list((b[1] + ' ' + b[2]).strip(), cur_num, 567, 567))
    elif kind == 'let':
        body.append(p_list((b[1] + ' ' + b[2]).strip(), LET_NUM, 426, 426))
    elif kind == 'bul':
        if in_sistematika:
            body.append(p_sistematika(b[1]))
            if b[2]: body.append(p_sistematika_desc(b[2]))
        else:
            body.append(p_list((b[1] + ' ' + b[2]).strip(), 12, 851, 425))
    elif kind == 'fig':
        if figpng:
            body.append(P('<w:pStyle w:val="STTSGambar"/><w:spacing w:line="360" w:lineRule="auto"/>'))
            body.append(p_figure('rId100', 5040000, 2880000, 'Gambar %d.1' % chapter_no))
        else:
            body.append(p_body(b[1].replace('[GAMBAR', '[ISI: GAMBAR')))
    elif kind == 'cap':
        body.append(p_style('STTSGambar', b[1]))
        body.append(p_style('STTSGambar', b[2]))
        body.append(p_style('STTSGambar'))
    prev_kind = kind

newdoc = head + ''.join(body) + sect + '</w:body></w:document>'
files['word/document.xml'] = newdoc.encode('utf8')

# ---------- numbering: sub-sub headings per sub-bab, restarting decimal lists, letter list ----------
numxml = files['word/numbering.xml'].decode('utf8')
def abstract(aid):
    mm = re.search(r'<w:abstractNum w:abstractNumId="%s"[ >].*?</w:abstractNum>' % aid, numxml, re.S); assert mm; return mm.group(0)
add_abs = []; add_num = []
a28 = abstract('28')
for k in range(1, cur_h2 + 1):
    aid = 40 + k
    a = a28.replace('w:abstractNumId="28"', 'w:abstractNumId="%d"' % aid).replace('<w:nsid w:val="6A087431"', '<w:nsid w:val="6A0874%02X"' % (0x40 + k)).replace('w:val="2.1.%1"', 'w:val="%d.%d.%%1"' % (chapter_no, k))
    add_abs.append(a); add_num.append('<w:num w:numId="%d"><w:abstractNumId w:val="%d"/></w:num>' % (NUM_SUBSUB + k, aid))
a20 = abstract('20')
adec = a20.replace('w:abstractNumId="20"', 'w:abstractNumId="60"').replace('<w:nsid w:val="', '<w:nsid w:val="7A', 1)
adec = re.sub(r'(<w:lvl w:ilvl="0"[^>]*>.*?<w:numFmt w:val=")lowerLetter(")', r'\1decimal\2', adec, count=1, flags=re.S)
adec = re.sub(r'<w:nsid w:val="7A([0-9A-F]{8})"', lambda m: '<w:nsid w:val="%s"' % ('7A' + m.group(1)[2:]), adec)
add_abs.append(adec)
for n in num_lists:
    add_num.append('<w:num w:numId="%d"><w:abstractNumId w:val="60"/><w:lvlOverride w:ilvl="0"><w:startOverride w:val="1"/></w:lvlOverride></w:num>' % n)
add_num.append('<w:num w:numId="%d"><w:abstractNumId w:val="20"/><w:lvlOverride w:ilvl="0"><w:startOverride w:val="1"/></w:lvlOverride></w:num>' % LET_NUM)
pos = numxml.index('<w:num ')
numxml = numxml[:pos] + ''.join(add_abs) + numxml[pos:]
numxml = numxml.replace('</w:numbering>', ''.join(add_num) + '</w:numbering>')
files['word/numbering.xml'] = numxml.encode('utf8')

# ---------- relationships: drop unused pictures, add the figure ----------
rels = files['word/_rels/document.xml.rels'].decode('utf8')
dropped = re.findall(r'<Relationship [^>]*Type="[^"]*/(?:image|hdphoto)"[^>]*Target="([^"]+)"[^>]*/>', rels)
rels = re.sub(r'<Relationship [^>]*Type="[^"]*/(?:image|hdphoto)"[^>]*/>', '', rels)
for t in dropped: files.pop('word/' + t, None)
if figpng:
    files['word/media/fig_%d_1.png' % chapter_no] = open(figpng, 'rb').read()
    rels = rels.replace('</Relationships>', '<Relationship Id="rId100" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/fig_%d_1.png"/></Relationships>' % chapter_no)
files['word/_rels/document.xml.rels'] = rels.encode('utf8')

# ---------- sample footnotes out, template -> document ----------
fn = files['word/footnotes.xml'].decode('utf8')
fn = re.sub(r'<w:footnote w:id="[1-9]\d*".*?</w:footnote>', '', fn, flags=re.S)
files['word/footnotes.xml'] = fn.encode('utf8')
ct = files['[Content_Types].xml'].decode('utf8').replace('wordprocessingml.template.main+xml', 'wordprocessingml.document.main+xml')
files['[Content_Types].xml'] = ct.encode('utf8')
core = files['docProps/core.xml'].decode('utf8')
core = re.sub(r'<dc:title>.*?</dc:title>', '', core).replace('</cp:coreProperties>', '<dc:title>%s %s</dc:title></cp:coreProperties>' % (title_lines[0], title_lines[1]))
if '<dc:title>' not in core: core = core.replace('<dc:creator>', '<dc:title>%s %s</dc:title><dc:creator>' % (title_lines[0], title_lines[1]), 1)
files['docProps/core.xml'] = core.encode('utf8')

os.makedirs(os.path.dirname(out) or '.', exist_ok=True)
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as zo:
    zo.writestr('[Content_Types].xml', files.pop('[Content_Types].xml'))
    for n, data in files.items(): zo.writestr(n, data)
print('blocks', len(blocks), 'paragraphs', len(body), 'numbered lists', num_lists, 'sub-bab', cur_h2, '->', out)
