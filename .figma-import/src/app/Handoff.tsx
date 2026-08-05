/**
 * Easy Study — Design Handoff
 * Live design specification for developers.
 * Access via the "Design handoff" link in Teacher Profile.
 */

import logoPencil from "../imports/Pensil.png";
import logoFull from "../imports/Logo_ES.png";
import logoPill from "../imports/Papan.png";
import { Check, ChevronRight, Copy, AlertCircle, Clock, Users, BookOpen, Calendar, TrendingUp, Construction } from "lucide-react";

/* ─── Tokens (mirrored from App.tsx) ─── */
const T = {
  navy:          "#1B2A4A",
  navyLight:     "#2A3F66",
  teal:          "#2D6A7E",
  tealLight:     "#3D8A9E",
  surface:       "#F5F6F8",
  card:          "#FFFFFF",
  textPrimary:   "#1A1D26",
  textSecondary: "#5C6370",
  border:        "#E2E5EB",
  success:       "#2E7D5A",
  error:         "#B53A3A",
  yellow:        "#F5B800",
  brandGreen:    "#00A651",
  brandTeal:     "#006B54",
};

/* ─── Shared layout ─── */
function Section({ title, subtitle, children }: { title: string; subtitle?: string; children: React.ReactNode }) {
  return (
    <section className="mb-16">
      <div className="mb-6 pb-4 border-b" style={{ borderColor: T.border }}>
        <h2 className="font-bold text-2xl" style={{ color: T.navy }}>{title}</h2>
        {subtitle && <p className="text-sm mt-1" style={{ color: T.textSecondary }}>{subtitle}</p>}
      </div>
      {children}
    </section>
  );
}

function Label({ children }: { children: React.ReactNode }) {
  return <p className="text-xs font-semibold uppercase tracking-wider mt-3 mb-1.5" style={{ color: T.textSecondary }}>{children}</p>;
}

function SpecTag({ children }: { children: React.ReactNode }) {
  return (
    <span className="inline-block text-xs px-2 py-0.5 rounded font-mono" style={{ backgroundColor: `${T.navy}10`, color: T.navy }}>
      {children}
    </span>
  );
}

function CopyHex({ hex }: { hex: string }) {
  return (
    <button onClick={() => navigator.clipboard?.writeText(hex)}
      className="flex items-center gap-1 text-xs font-mono hover:opacity-70 transition-opacity"
      style={{ color: T.textSecondary }}>
      {hex} <Copy size={10} />
    </button>
  );
}

/* ═══════════════════════════════════════════
   SECTIONS
═══════════════════════════════════════════ */

function BrandSection() {
  return (
    <Section title="Brand" subtitle="Easy Study · 易华文教中心 · Mandarin Education Center & China Education Consultant">
      <div className="grid grid-cols-3 gap-6">
        {/* Logo on black */}
        <div className="rounded-2xl p-8 flex flex-col items-center gap-4" style={{ backgroundColor: "#000" }}>
          <img src={logoFull} alt="Logo full" className="h-24 w-auto object-contain" />
          <span className="text-xs" style={{ color: "rgba(255,255,255,0.4)" }}>Logo_ES.png — auth / marketing</span>
        </div>
        {/* Mascot on navy */}
        <div className="rounded-2xl p-8 flex flex-col items-center gap-4" style={{ backgroundColor: T.navy }}>
          <div className="flex items-center gap-3">
            <img src={logoPencil} alt="Pensil" className="h-12 w-auto object-contain" />
            <div>
              <div className="font-bold text-white text-base leading-tight">Easy Study</div>
              <div className="text-xs" style={{ color: "rgba(255,255,255,0.5)", fontFamily: "'Noto Sans SC', sans-serif" }}>易华文教中心</div>
            </div>
          </div>
          <span className="text-xs" style={{ color: "rgba(255,255,255,0.4)" }}>Pensil.png — sidebar / app bar</span>
        </div>
        {/* Pill on white */}
        <div className="rounded-2xl p-8 flex flex-col items-center gap-4 border" style={{ backgroundColor: "#fff", borderColor: T.border }}>
          <img src={logoPill} alt="Papan" className="h-12 w-auto object-contain" />
          <span className="text-xs" style={{ color: T.textSecondary }}>Papan.png — standalone pill mark</span>
        </div>
      </div>
    </Section>
  );
}

function ColorsSection() {
  const groups = [
    {
      label: "App UI — Primary",
      colors: [
        { name: "Navy",          token: "--navy",          hex: T.navy,          on: "#fff", usage: "App bars, headings, teacher buttons" },
        { name: "Navy Light",    token: "--navy-light",    hex: T.navyLight,     on: "#fff", usage: "Hover / secondary navy surfaces" },
        { name: "Teal",          token: "--teal",          hex: T.teal,          on: "#fff", usage: "Student accents, links, HSK badges, nav indicator" },
        { name: "Teal Light",    token: "--teal-light",    hex: T.tealLight,     on: "#fff", usage: "Soft teal badges, hover" },
      ],
    },
    {
      label: "Surfaces & Text",
      colors: [
        { name: "Surface",       token: "--surface",       hex: T.surface,       on: T.textPrimary, usage: "Page / scaffold background" },
        { name: "Card",          token: "--card",          hex: T.card,          on: T.textPrimary, usage: "Cards, inputs, bottom nav" },
        { name: "Text Primary",  token: "--text-primary",  hex: T.textPrimary,   on: "#fff", usage: "Body copy, titles" },
        { name: "Text Secondary",token: "--text-secondary",hex: T.textSecondary, on: "#fff", usage: "Subtitles, hints, captions" },
        { name: "Border",        token: "--border",        hex: T.border,        on: T.textPrimary, usage: "Card borders, dividers, input outlines" },
      ],
    },
    {
      label: "Semantic",
      colors: [
        { name: "Success",       token: "--success",       hex: T.success,       on: "#fff", usage: "Correct answers, positive feedback" },
        { name: "Error",         token: "--error",         hex: T.error,         on: "#fff", usage: "Errors, overdue alerts, destructive actions" },
      ],
    },
    {
      label: "Brand / Logo only",
      colors: [
        { name: "Brand Yellow",  token: "--brand-yellow",  hex: T.yellow,        on: "#000", usage: "EASY STUDY pill, pencil body" },
        { name: "Brand Green",   token: "--brand-green",   hex: T.brandGreen,    on: "#fff", usage: "Chinese calligraphy text" },
        { name: "Brand Teal",    token: "--brand-teal",    hex: T.brandTeal,     on: "#fff", usage: "EASY STUDY text inside pill, pencil tip" },
      ],
    },
  ];

  return (
    <Section title="Color palette" subtitle="Light mode only (v1). No dark mode.">
      <div className="space-y-8">
        {groups.map(g => (
          <div key={g.label}>
            <Label>{g.label}</Label>
            <div className="grid grid-cols-5 gap-3">
              {g.colors.map(c => (
                <div key={c.hex + c.name} className="rounded-xl overflow-hidden border" style={{ borderColor: T.border }}>
                  <div className="h-16 flex items-center justify-center" style={{ backgroundColor: c.hex }}>
                    <span className="text-xs font-bold opacity-60" style={{ color: c.on }}>{c.name.split(" ")[0]}</span>
                  </div>
                  <div className="p-2.5 bg-white">
                    <div className="font-semibold text-xs mb-0.5" style={{ color: T.textPrimary }}>{c.name}</div>
                    <CopyHex hex={c.hex} />
                    <div className="text-xs mt-1 leading-tight" style={{ color: T.textSecondary }}>{c.usage}</div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </Section>
  );
}

function TypographySection() {
  const scale = [
    { name: "Headline",       size: "28px", weight: "700", color: T.navy,          sample: "Welcome back" },
    { name: "App bar title",  size: "20px", weight: "600", color: "#fff",          sample: "Easy Study", bg: T.navy },
    { name: "Section header", size: "16px", weight: "700", color: T.navy,          sample: "Needs attention" },
    { name: "Card title",     size: "16px", weight: "600", color: T.textPrimary,   sample: "HSK 2 Grammar — Unit 3" },
    { name: "Body",           size: "14px", weight: "400", color: T.textPrimary,   sample: "Students arrange word segments into a correct sentence." },
    { name: "Caption / nav",  size: "12px", weight: "400", color: T.textSecondary, sample: "Term 1 · 5 of 8 lessons completed" },
  ];

  return (
    <Section title="Typography" subtitle="Plus Jakarta Sans (Latin/UI) + Noto Sans SC (Chinese). Both loaded via Google Fonts.">
      {/* Font stacks */}
      <div className="grid grid-cols-2 gap-4 mb-8">
        <div className="p-5 rounded-xl border" style={{ borderColor: T.border }}>
          <div className="text-xs font-semibold mb-2" style={{ color: T.textSecondary }}>Latin / UI</div>
          <div className="font-bold text-3xl mb-1" style={{ fontFamily: "'Plus Jakarta Sans', sans-serif", color: T.navy }}>Plus Jakarta Sans</div>
          <div className="text-sm" style={{ color: T.textSecondary }}>Weights: 400 · 500 · 600 · 700</div>
          <div className="mt-3 text-sm" style={{ fontFamily: "'Plus Jakarta Sans', sans-serif" }}>Aa Bb Cc 0123456789</div>
        </div>
        <div className="p-5 rounded-xl border" style={{ borderColor: T.border }}>
          <div className="text-xs font-semibold mb-2" style={{ color: T.textSecondary }}>Chinese (CJK)</div>
          <div className="font-bold text-3xl mb-1" style={{ fontFamily: "'Noto Sans SC', sans-serif", color: T.teal }}>Noto Sans SC</div>
          <div className="text-sm" style={{ color: T.textSecondary }}>Weights: 400 · 600 · 700</div>
          <div className="mt-3 text-lg" style={{ fontFamily: "'Noto Sans SC', sans-serif" }}>南方的天气很热 · 组词成句 · 对话配对</div>
        </div>
      </div>

      {/* Scale */}
      <div className="rounded-xl border overflow-hidden" style={{ borderColor: T.border }}>
        <div className="grid text-xs font-bold px-5 py-3" style={{ gridTemplateColumns: "160px 60px 60px 1fr", color: T.textSecondary, backgroundColor: `${T.navy}08` }}>
          <span>Role</span><span>Size</span><span>Weight</span><span>Sample</span>
        </div>
        {scale.map((row, i) => (
          <div key={row.name} className="grid items-center px-5 py-3 border-t" style={{ gridTemplateColumns: "160px 60px 60px 1fr", borderColor: T.border, backgroundColor: i % 2 === 0 ? "#fff" : `${T.surface}88` }}>
            <span className="text-xs font-semibold" style={{ color: T.textSecondary }}>{row.name}</span>
            <SpecTag>{row.size}</SpecTag>
            <SpecTag>{row.weight}</SpecTag>
            <span style={{ fontSize: row.size, fontWeight: row.weight, color: row.color, backgroundColor: row.bg, padding: row.bg ? "2px 8px" : undefined, borderRadius: row.bg ? 4 : undefined, fontFamily: "'Plus Jakarta Sans', sans-serif" }}>
              {row.sample}
            </span>
          </div>
        ))}
      </div>
    </Section>
  );
}

function SpacingSection() {
  const scale = [2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64];
  return (
    <Section title="Spacing" subtitle="8pt base grid. All spacing multiples of 4px minimum, 8px preferred.">
      <div className="flex flex-wrap items-end gap-4">
        {scale.map(px => (
          <div key={px} className="flex flex-col items-center gap-2">
            <div className="rounded" style={{ width: px, height: px, backgroundColor: T.teal, minWidth: 2, minHeight: 2 }} />
            <span className="text-xs font-mono" style={{ color: T.textSecondary }}>{px}px</span>
          </div>
        ))}
      </div>
      <div className="mt-6 grid grid-cols-3 gap-4 text-sm">
        {[
          { label: "Page padding",        value: "20px (mobile) · 40px (desktop)" },
          { label: "Card padding",        value: "16px" },
          { label: "Card gap",            value: "12–16px" },
          { label: "Max content width",   value: "960px (desktop) · 420px (auth)" },
          { label: "Sidebar width",       value: "240px (fixed)" },
          { label: "Mobile bottom nav",   value: "64px height" },
          { label: "Top bar height",      value: "56px" },
          { label: "App bar (mobile)",    value: "56px" },
          { label: "Button tap target",   value: "48px min height" },
        ].map(({ label, value }) => (
          <div key={label} className="p-3 rounded-lg" style={{ backgroundColor: T.surface }}>
            <div className="text-xs font-semibold mb-0.5" style={{ color: T.textSecondary }}>{label}</div>
            <div className="text-sm font-medium" style={{ color: T.textPrimary }}>{value}</div>
          </div>
        ))}
      </div>
    </Section>
  );
}

function ComponentsSection() {
  return (
    <Section title="Components" subtitle="All components use no drop-shadow — border only. 12px card radius.">
      <div className="space-y-10">

        {/* Buttons */}
        <div>
          <Label>Buttons</Label>
          <div className="p-6 rounded-xl border flex flex-wrap gap-4 items-center" style={{ borderColor: T.border }}>
            <button className="px-4 py-2.5 rounded-lg font-semibold text-white text-sm" style={{ backgroundColor: T.navy }}>Navy (Teacher primary)</button>
            <button className="px-4 py-2.5 rounded-lg font-semibold text-white text-sm" style={{ backgroundColor: T.teal }}>Teal (Student primary)</button>
            <button className="px-4 py-2.5 rounded-lg font-semibold text-sm border" style={{ borderColor: T.navy, color: T.navy }}>Secondary outlined</button>
            <button className="px-4 py-2.5 rounded-lg font-semibold text-white text-sm" style={{ backgroundColor: T.error }}>Destructive</button>
            <button className="flex items-center gap-2 px-4 py-2.5 rounded-lg font-semibold text-white text-sm opacity-60 cursor-not-allowed" style={{ backgroundColor: T.teal }}>
              <div className="w-4 h-4 rounded-full border-2 border-t-transparent animate-spin" style={{ borderColor: "white", borderTopColor: "transparent" }} />
              Loading…
            </button>
          </div>
          <div className="flex gap-4 mt-2 flex-wrap text-xs" style={{ color: T.textSecondary }}>
            <span>Radius: <SpecTag>8px</SpecTag></span>
            <span>Padding: <SpecTag>10–14px vertical · 16px horizontal</SpecTag></span>
            <span>Font: <SpecTag>600 · 14px</SpecTag></span>
          </div>
        </div>

        {/* Badges */}
        <div>
          <Label>HSK badges & Status pills</Label>
          <div className="p-6 rounded-xl border flex flex-wrap gap-3 items-center" style={{ borderColor: T.border }}>
            {[1,2,3,4,5,6].map(l => (
              <span key={l} className="px-2 py-0.5 rounded text-white font-semibold" style={{ backgroundColor: T.teal, fontSize: 11 }}>HSK {l}</span>
            ))}
            <div className="w-px h-5 mx-2" style={{ backgroundColor: T.border }} />
            {[
              { label: "Published",   bg: "#E8F5EE", color: "#2E7D5A" },
              { label: "Draft",       bg: "#F0F0F3", color: "#5C6370" },
              { label: "Upcoming",    bg: "#E5F0F4", color: "#2D6A7E" },
              { label: "Concluded",   bg: "#E8F5EE", color: "#2E7D5A" },
              { label: "Not started", bg: "#F0F0F3", color: "#5C6370" },
              { label: "In progress", bg: "#E5F0F4", color: "#2D6A7E" },
              { label: "Done",        bg: "#E8F5EE", color: "#2E7D5A" },
            ].map(s => (
              <span key={s.label} className="px-2 py-0.5 rounded-full font-semibold" style={{ backgroundColor: s.bg, color: s.color, fontSize: 11 }}>{s.label}</span>
            ))}
          </div>
          <div className="flex gap-4 mt-2 text-xs flex-wrap" style={{ color: T.textSecondary }}>
            <span>HSK badge radius: <SpecTag>4px</SpecTag></span>
            <span>Status pill radius: <SpecTag>999px</SpecTag></span>
            <span>Font size: <SpecTag>11px · 600</SpecTag></span>
          </div>
        </div>

        {/* Card */}
        <div>
          <Label>Cards</Label>
          <div className="grid grid-cols-3 gap-4">
            {/* Default */}
            <div>
              <div className="text-xs mb-2 font-medium" style={{ color: T.textSecondary }}>Default</div>
              <div className="bg-white rounded-xl border p-4" style={{ borderColor: T.border }}>
                <div className="font-semibold text-sm mb-1" style={{ color: T.textPrimary }}>HSK 2 Grammar — Unit 3</div>
                <div className="flex items-center gap-2">
                  <span className="text-xs" style={{ color: T.textSecondary }}>Multiple choice · 5 questions</span>
                  <span className="px-2 py-0.5 rounded text-white font-semibold" style={{ backgroundColor: T.teal, fontSize: 11 }}>HSK 2</span>
                </div>
              </div>
            </div>
            {/* Alert accent */}
            <div>
              <div className="text-xs mb-2 font-medium" style={{ color: T.textSecondary }}>Alert accent bar</div>
              <div className="bg-white rounded-xl border p-4 flex gap-3" style={{ borderColor: T.border }}>
                <div className="w-1 self-stretch rounded-full flex-shrink-0" style={{ backgroundColor: T.error }} />
                <div>
                  <div className="font-semibold text-sm" style={{ color: T.textPrimary }}>Wang Fang — HSK 2 overdue</div>
                  <div className="text-xs" style={{ color: T.textSecondary }}>Due 3 days ago · Multiple choice</div>
                </div>
              </div>
            </div>
            {/* Teal upload tint */}
            <div>
              <div className="text-xs mb-2 font-medium" style={{ color: T.textSecondary }}>Teal upload tint</div>
              <div className="rounded-xl border-2 p-4" style={{ borderColor: `${T.teal}30`, backgroundColor: `${T.teal}05` }}>
                <div className="font-semibold text-sm mb-1" style={{ color: T.teal }}>Import from worksheet</div>
                <div className="text-xs" style={{ color: T.textSecondary }}>Upload PDF, DOCX, or image</div>
              </div>
            </div>
          </div>
          <div className="flex gap-4 mt-2 text-xs flex-wrap" style={{ color: T.textSecondary }}>
            <span>Background: <SpecTag>#FFFFFF</SpecTag></span>
            <span>Radius: <SpecTag>12px</SpecTag></span>
            <span>Border: <SpecTag>1px #E2E5EB</SpecTag></span>
            <span>Padding: <SpecTag>16px</SpecTag></span>
            <span>Shadow: <SpecTag>none</SpecTag></span>
          </div>
        </div>

        {/* Input */}
        <div>
          <Label>Input fields</Label>
          <div className="p-6 rounded-xl border grid grid-cols-3 gap-4" style={{ borderColor: T.border }}>
            <div>
              <div className="text-xs font-semibold mb-1" style={{ color: T.textPrimary }}>Default</div>
              <input className="w-full px-3 py-2.5 rounded-lg border text-sm outline-none" style={{ borderColor: T.border }} placeholder="Placeholder text" />
            </div>
            <div>
              <div className="text-xs font-semibold mb-1" style={{ color: T.textPrimary }}>Focus</div>
              <input className="w-full px-3 py-2.5 rounded-lg text-sm outline-none" style={{ border: `1.5px solid ${T.teal}` }} placeholder="Focused state" defaultValue="Input value" />
            </div>
            <div>
              <div className="text-xs font-semibold mb-1" style={{ color: T.error }}>Error</div>
              <input className="w-full px-3 py-2.5 rounded-lg text-sm outline-none" style={{ border: `1.5px solid ${T.error}` }} defaultValue="Wrong value" />
              <p className="text-xs mt-1 font-medium" style={{ color: T.error }}>This field is required</p>
            </div>
          </div>
          <div className="flex gap-4 mt-2 text-xs flex-wrap" style={{ color: T.textSecondary }}>
            <span>Background: <SpecTag>#FFFFFF</SpecTag></span>
            <span>Radius: <SpecTag>10px</SpecTag></span>
            <span>Border default: <SpecTag>1px #E2E5EB</SpecTag></span>
            <span>Border focus: <SpecTag>1.5px #2D6A7E</SpecTag></span>
            <span>Border error: <SpecTag>1.5px #B53A3A</SpecTag></span>
          </div>
        </div>

        {/* Avatar */}
        <div>
          <Label>Avatars</Label>
          <div className="p-6 rounded-xl border flex items-end gap-6" style={{ borderColor: T.border }}>
            {[{ size: 72, label: "72px" }, { size: 64, label: "64px" }, { size: 44, label: "44px" }, { size: 36, label: "36px" }, { size: 32, label: "32px" }].map(({ size, label }) => (
              <div key={size} className="flex flex-col items-center gap-2">
                <div className="rounded-full flex items-center justify-center text-white font-semibold"
                  style={{ width: size, height: size, backgroundColor: T.navy, fontSize: size * 0.33 }}>WF</div>
                <span className="text-xs" style={{ color: T.textSecondary }}>{label}</span>
              </div>
            ))}
            <div className="flex flex-col items-center gap-2">
              <div className="rounded-full flex items-center justify-center text-white font-semibold"
                style={{ width: 44, height: 44, backgroundColor: T.teal, fontSize: 15 }}>LM</div>
              <span className="text-xs" style={{ color: T.textSecondary }}>Student (teal)</span>
            </div>
          </div>
        </div>

        {/* Progress */}
        <div>
          <Label>Progress indicators</Label>
          <div className="p-6 rounded-xl border grid grid-cols-2 gap-6" style={{ borderColor: T.border }}>
            <div>
              <div className="text-xs font-semibold mb-3" style={{ color: T.textSecondary }}>Linear bar</div>
              <div className="space-y-3">
                {[{ label: "37%", pct: 37 }, { label: "62%", pct: 62 }, { label: "100%", pct: 100 }].map(({ label, pct }) => (
                  <div key={pct}>
                    <div className="flex justify-between text-xs mb-1" style={{ color: T.textSecondary }}>
                      <span>Lesson progress</span><span>{label}</span>
                    </div>
                    <div className="h-2 rounded-full overflow-hidden" style={{ backgroundColor: T.border }}>
                      <div className="h-full rounded-full" style={{ width: `${pct}%`, backgroundColor: pct === 100 ? T.success : T.teal }} />
                    </div>
                  </div>
                ))}
              </div>
              <div className="flex gap-3 mt-3 text-xs flex-wrap" style={{ color: T.textSecondary }}>
                <span>Height: <SpecTag>6–8px</SpecTag></span>
                <span>Radius: <SpecTag>999px</SpecTag></span>
                <span>Fill: <SpecTag>Teal / Success</SpecTag></span>
              </div>
            </div>
            <div>
              <div className="text-xs font-semibold mb-3" style={{ color: T.textSecondary }}>Circular ring (term)</div>
              {(() => {
                const size = 80, stroke = 8, r = (size - stroke) / 2;
                const circ = 2 * Math.PI * r;
                return (
                  <div className="flex items-center gap-6">
                    <div className="relative inline-flex items-center justify-center">
                      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
                        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={T.border} strokeWidth={stroke} />
                        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={T.teal} strokeWidth={stroke}
                          strokeDasharray={circ} strokeDashoffset={circ * 0.375}
                          strokeLinecap="round" transform={`rotate(-90 ${size/2} ${size/2})`} />
                      </svg>
                      <div className="absolute text-center">
                        <div className="font-bold text-sm" style={{ color: T.navy }}>5/8</div>
                        <div style={{ color: T.textSecondary, fontSize: 9 }}>lessons</div>
                      </div>
                    </div>
                    <div className="text-xs space-y-1" style={{ color: T.textSecondary }}>
                      <div>Track: <SpecTag>{T.border}</SpecTag></div>
                      <div>Fill: <SpecTag>{T.teal}</SpecTag></div>
                      <div>Stroke: <SpecTag>8–9px</SpecTag></div>
                      <div>Cap: <SpecTag>round</SpecTag></div>
                    </div>
                  </div>
                );
              })()}
            </div>
          </div>
        </div>

        {/* Empty states */}
        <div>
          <Label>Empty state pattern</Label>
          <div className="p-6 rounded-xl border grid grid-cols-3 gap-4" style={{ borderColor: T.border }}>
            {[
              { icon: Users,       title: "No students yet",  sub: "Students appear after they register…" },
              { icon: BookOpen,    title: "No exercises yet",  sub: "Tap New exercise to get started…" },
              { icon: TrendingUp,  title: "No progress yet",  sub: "Complete a lesson or quiz…" },
            ].map(({ icon: Icon, title, sub }) => (
              <div key={title} className="flex flex-col items-center text-center py-8 px-4 bg-white rounded-xl border" style={{ borderColor: T.border }}>
                <Icon size={48} style={{ color: T.textSecondary }} className="mb-3" />
                <p className="font-semibold text-sm mb-1" style={{ color: T.navy }}>{title}</p>
                <p className="text-xs leading-relaxed" style={{ color: T.textSecondary }}>{sub}</p>
              </div>
            ))}
          </div>
          <div className="flex gap-4 mt-2 text-xs flex-wrap" style={{ color: T.textSecondary }}>
            <span>Icon size: <SpecTag>48px</SpecTag></span>
            <span>Icon color: <SpecTag>Text secondary</SpecTag></span>
            <span>Title: <SpecTag>16px · 600 · Navy</SpecTag></span>
            <span>Subtitle: <SpecTag>14px · 400 · Text secondary</SpecTag></span>
            <span>Padding: <SpecTag>32px</SpecTag></span>
          </div>
        </div>

        {/* Snackbars */}
        <div>
          <Label>Snackbars</Label>
          <div className="p-6 rounded-xl border space-y-3" style={{ borderColor: T.border }}>
            <div className="flex items-center justify-between px-4 py-3 rounded-xl text-white text-sm font-medium max-w-sm" style={{ backgroundColor: T.error }}>
              <span>Incorrect email or password</span>
              <button className="ml-3 opacity-70">✕</button>
            </div>
            <div className="flex items-center justify-between px-4 py-3 rounded-xl text-white text-sm font-medium max-w-sm" style={{ backgroundColor: T.success }}>
              <span>Exercise published successfully</span>
              <button className="ml-3 opacity-70">✕</button>
            </div>
          </div>
          <div className="flex gap-4 mt-2 text-xs flex-wrap" style={{ color: T.textSecondary }}>
            <span>Position: <SpecTag>bottom center · fixed</SpecTag></span>
            <span>Radius: <SpecTag>12px</SpecTag></span>
            <span>Auto-dismiss: <SpecTag>3000ms</SpecTag></span>
          </div>
        </div>

      </div>
    </Section>
  );
}

function LayoutSection() {
  return (
    <Section title="Layout" subtitle="Desktop sidebar shell + responsive mobile bottom nav.">
      <div className="grid grid-cols-2 gap-6">
        {/* Desktop */}
        <div className="rounded-xl border overflow-hidden" style={{ borderColor: T.border }}>
          <div className="text-xs font-semibold px-4 py-2.5 border-b" style={{ borderColor: T.border, backgroundColor: T.surface, color: T.textSecondary }}>
            Web desktop — 1440×900
          </div>
          <div className="flex" style={{ height: 200 }}>
            <div className="flex-shrink-0 flex flex-col py-3 px-2" style={{ width: 80, backgroundColor: T.navy }}>
              {["Dashboard","Students","Exercises","Classes","Profile"].map((t, i) => (
                <div key={t} className="px-2 py-1.5 rounded text-center mb-0.5" style={{ backgroundColor: i === 0 ? "rgba(45,106,126,0.28)" : "transparent" }}>
                  <div className="text-xs" style={{ color: i === 0 ? "#fff" : "rgba(255,255,255,0.4)", fontSize: 9 }}>{t}</div>
                </div>
              ))}
            </div>
            <div className="flex-1 flex flex-col">
              <div className="flex items-center px-3 border-b" style={{ height: 36, backgroundColor: "#fff", borderColor: T.border }}>
                <span className="font-bold text-xs" style={{ color: T.navy }}>Dashboard</span>
              </div>
              <div className="flex-1 p-2" style={{ backgroundColor: T.surface }}>
                <div className="grid grid-cols-3 gap-1.5">
                  {["12 Students","3 Exercises","5 Classes"].map(s => (
                    <div key={s} className="bg-white rounded-lg border p-2" style={{ borderColor: T.border }}>
                      <div className="text-xs font-bold" style={{ color: T.navy, fontSize: 8 }}>{s}</div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
          <div className="px-4 py-2.5 space-y-1 text-xs" style={{ color: T.textSecondary }}>
            <div>Sidebar: <SpecTag>240px fixed · Navy #1B2A4A</SpecTag></div>
            <div>Content: <SpecTag>max-width 960px · 40px padding · Surface bg</SpecTag></div>
            <div>Top bar: <SpecTag>56px · white · border-bottom</SpecTag></div>
          </div>
        </div>

        {/* Mobile */}
        <div className="rounded-xl border overflow-hidden" style={{ borderColor: T.border }}>
          <div className="text-xs font-semibold px-4 py-2.5 border-b" style={{ borderColor: T.border, backgroundColor: T.surface, color: T.textSecondary }}>
            Mobile — 390×844 (&lt;900px viewport)
          </div>
          <div className="flex flex-col" style={{ height: 200 }}>
            <div className="flex items-center justify-between px-3" style={{ height: 40, backgroundColor: T.navy }}>
              <span className="text-xs font-bold text-white">Easy Study</span>
              <span className="text-xs font-bold text-white">Dashboard</span>
              <span className="text-white text-xs">🔔</span>
            </div>
            <div className="flex-1" style={{ backgroundColor: T.surface }} />
            <div className="flex border-t bg-white" style={{ height: 48, borderColor: T.border }}>
              {["Home","Classes","Lessons","Progress","Profile"].map((t, i) => (
                <div key={t} className="flex-1 flex flex-col items-center justify-center" style={{ color: i === 0 ? T.teal : T.textSecondary }}>
                  <div className="w-3 h-0.5 rounded mb-0.5" style={{ backgroundColor: i === 0 ? T.teal : "transparent" }} />
                  <span style={{ fontSize: 7, fontWeight: i === 0 ? 600 : 400 }}>{t}</span>
                </div>
              ))}
            </div>
          </div>
          <div className="px-4 py-2.5 space-y-1 text-xs" style={{ color: T.textSecondary }}>
            <div>App bar: <SpecTag>56px · Navy · logo + title + bell</SpecTag></div>
            <div>Bottom nav: <SpecTag>64px · white · 5 tabs</SpecTag></div>
            <div>Active indicator: <SpecTag>Teal · pill behind icon</SpecTag></div>
          </div>
        </div>
      </div>
    </Section>
  );
}

function ScreenInventorySection() {
  const screens = [
    { id: "A1", label: "Auth", name: "Test login",           route: "/login?mode=test",         role: "Both"    },
    { id: "A2", label: "Auth", name: "Login",                route: "/login",                   role: "Both"    },
    { id: "A3", label: "Auth", name: "Register — teacher",   route: "/register?role=teacher",   role: "Teacher" },
    { id: "A4", label: "Auth", name: "Register — student",   route: "/register?role=student",   role: "Student" },
    { id: "A5", label: "Auth", name: "Complete profile",     route: "/complete-profile",        role: "Both"    },
    { id: "B1", label: "Teacher tab", name: "Dashboard",     route: "/teacher/dashboard",       role: "Teacher" },
    { id: "B2", label: "Teacher tab", name: "Students",      route: "/teacher/students",        role: "Teacher" },
    { id: "B3", label: "Teacher tab", name: "Exercises",     route: "/teacher/exercises",       role: "Teacher" },
    { id: "B4", label: "Teacher tab", name: "Classes",       route: "/teacher/classes",         role: "Teacher" },
    { id: "B5", label: "Teacher tab", name: "Profile",       route: "/teacher/profile",         role: "Teacher" },
    { id: "T1", label: "Teacher screen", name: "Student detail",   route: "/teacher/students/:id",  role: "Teacher" },
    { id: "T2", label: "Teacher screen", name: "Exercise form",    route: "/teacher/exercises/new", role: "Teacher" },
    { id: "T3", label: "Teacher screen", name: "Class form",       route: "/teacher/classes/new",   role: "Teacher" },
    { id: "T4", label: "Teacher screen", name: "Class detail",     route: "/teacher/classes/:id",   role: "Teacher" },
    { id: "E1", label: "Student tab", name: "Home",          route: "/student/home",            role: "Student" },
    { id: "E2", label: "Student tab", name: "My Classes",    route: "/student/classes",         role: "Student" },
    { id: "E3", label: "Student tab", name: "Lessons",       route: "/student/lessons",         role: "Student" },
    { id: "E4", label: "Student tab", name: "Progress",      route: "/student/progress",        role: "Student" },
    { id: "E5", label: "Student tab", name: "Profile",       route: "/student/profile",         role: "Student" },
    { id: "S1", label: "Student screen", name: "Exercise — MC",       route: "/student/exercise/:id",  role: "Student" },
    { id: "S2", label: "Student screen", name: "Exercise — Compose",  route: "/student/exercise/:id",  role: "Student" },
    { id: "S3", label: "Student screen", name: "Exercise — Matching", route: "/student/exercise/:id",  role: "Student" },
    { id: "S4", label: "Student screen", name: "Exercise — Coming soon", route: "/student/exercise/:id", role: "Student" },
    { id: "S5", label: "Student screen", name: "Lesson detail",       route: "/student/lessons/:id",   role: "Student" },
    { id: "S6", label: "Student screen", name: "Quiz",                route: "/student/quiz/:lessonId", role: "Student" },
    { id: "S6b",label: "Student screen", name: "Quiz score summary",  route: "/student/quiz/:id/score", role: "Student" },
    { id: "S7", label: "Student screen", name: "Class detail",        route: "/student/classes/:id",   role: "Student" },
    { id: "D1", label: "Dialog", name: "Assign exercise",     route: "Modal over Exercises tab",  role: "Teacher" },
    { id: "D2", label: "Dialog", name: "Worksheet import",    route: "Modal over Exercise form",  role: "Teacher" },
    { id: "D3", label: "Dialog", name: "Import review",       route: "Full screen after D2",      role: "Teacher" },
    { id: "D4", label: "Dialog", name: "Delete exercise",     route: "Modal from exercise card",  role: "Teacher" },
    { id: "D5", label: "Dialog", name: "Conclude class",      route: "Modal from class detail",   role: "Teacher" },
    { id: "D6", label: "Dialog", name: "Add class term",      route: "Modal from student detail", role: "Teacher" },
    { id: "D7", label: "Dialog", name: "Join class",          route: "Modal from student home",   role: "Student" },
    { id: "D8", label: "Dialog", name: "Leave class confirm", route: "Modal from S7",             role: "Student" },
  ];

  const roleColor = (role: string) => role === "Teacher" ? T.navy : role === "Student" ? T.teal : T.textSecondary;

  return (
    <Section title="Screen inventory" subtitle={`${screens.length} screens, tabs, and dialogs across Teacher and Student roles.`}>
      <div className="rounded-xl border overflow-hidden" style={{ borderColor: T.border }}>
        <div className="grid text-xs font-bold px-4 py-3 border-b"
          style={{ gridTemplateColumns: "48px 140px 1fr 1fr 80px", color: T.textSecondary, borderColor: T.border, backgroundColor: `${T.navy}08` }}>
          <span>ID</span><span>Category</span><span>Screen</span><span>Route / trigger</span><span>Role</span>
        </div>
        {screens.map((s, i) => (
          <div key={s.id} className="grid items-center px-4 py-2.5 border-b last:border-0 text-sm"
            style={{ gridTemplateColumns: "48px 140px 1fr 1fr 80px", borderColor: T.border, backgroundColor: i % 2 === 0 ? "#fff" : `${T.surface}88` }}>
            <span className="font-bold text-xs" style={{ color: T.navy }}>{s.id}</span>
            <span className="text-xs" style={{ color: T.textSecondary }}>{s.label}</span>
            <span className="font-medium text-sm" style={{ color: T.textPrimary }}>{s.name}</span>
            <span className="text-xs font-mono" style={{ color: T.textSecondary }}>{s.route}</span>
            <span className="text-xs font-semibold px-2 py-0.5 rounded-full text-white" style={{ backgroundColor: roleColor(s.role), fontSize: 10 }}>{s.role}</span>
          </div>
        ))}
      </div>
    </Section>
  );
}

function ExerciseTypesSection() {
  const types = [
    { id: 1, name: "Multiple choice",             cn: "选择题",  status: "live",   teacher: "A–D options + correct radio", student: "Tap card → correct/wrong states" },
    { id: 2, name: "Compose sentences",           cn: "组词成句", status: "live",   teacher: "Segment chips per question",   student: "Tap segments to fill answer zone" },
    { id: 3, name: "Matching",                    cn: "对话配对", status: "live",   teacher: "Prompt list + answer bank",    student: "Tap prompt → tap answer to link" },
    { id: 4, name: "Reading cloze",               cn: "选词填空", status: "import only", teacher: "Auto-detected on import", student: "Coming soon empty state" },
    { id: 5, name: "Picture + keyword sentence",  cn: "图文造句", status: "import only", teacher: "Auto-detected on import", student: "Coming soon empty state" },
  ];
  const statusColor = (s: string) => s === "live" ? T.success : T.textSecondary;
  const statusBg = (s: string) => s === "live" ? `${T.success}18` : T.surface;

  return (
    <Section title="Exercise types" subtitle="3 live · 2 import-only (detected from worksheet, not editable until Flutter implements editors).">
      <div className="rounded-xl border overflow-hidden" style={{ borderColor: T.border }}>
        <div className="grid text-xs font-bold px-4 py-3 border-b"
          style={{ gridTemplateColumns: "32px 180px 100px 1fr 1fr 100px", color: T.textSecondary, borderColor: T.border, backgroundColor: `${T.navy}08` }}>
          <span>#</span><span>Type</span><span>Chinese</span><span>Teacher editor</span><span>Student player</span><span>Status</span>
        </div>
        {types.map((t, i) => (
          <div key={t.id} className="grid items-center px-4 py-3 border-b last:border-0 text-sm"
            style={{ gridTemplateColumns: "32px 180px 100px 1fr 1fr 100px", borderColor: T.border, backgroundColor: i % 2 === 0 ? "#fff" : `${T.surface}88` }}>
            <span className="text-xs font-bold" style={{ color: T.navy }}>{t.id}</span>
            <span className="font-semibold text-sm" style={{ color: T.textPrimary }}>{t.name}</span>
            <span className="text-sm" style={{ color: T.textSecondary, fontFamily: "'Noto Sans SC', sans-serif" }}>{t.cn}</span>
            <span className="text-xs" style={{ color: T.textSecondary }}>{t.teacher}</span>
            <span className="text-xs" style={{ color: T.textSecondary }}>{t.student}</span>
            <span className="text-xs font-semibold px-2 py-0.5 rounded-full capitalize" style={{ backgroundColor: statusBg(t.status), color: statusColor(t.status) }}>
              {t.status}
            </span>
          </div>
        ))}
      </div>
    </Section>
  );
}

function ChineseRenderingSection() {
  return (
    <Section title="Chinese character rendering" subtitle="Always use Noto Sans SC for any CJK content. Never use Plus Jakarta Sans for Chinese — characters fall back to system default.">
      <div className="grid grid-cols-2 gap-6">
        <div className="p-6 rounded-xl border space-y-4" style={{ borderColor: T.border }}>
          <div className="text-xs font-semibold mb-2" style={{ color: T.textSecondary }}>Exercise prompt — Noto Sans SC 18px</div>
          <div className="p-4 rounded-xl bg-white border text-center" style={{ borderColor: T.border }}>
            <div className="text-xl font-semibold mb-1" style={{ fontFamily: "'Noto Sans SC', sans-serif", color: T.textPrimary }}>南方的天气很（ ）</div>
            <div className="text-sm italic" style={{ color: T.textSecondary }}>Southern weather is very ___</div>
          </div>
          <div className="p-4 rounded-xl bg-white border" style={{ borderColor: T.border }}>
            <div className="text-xs font-semibold mb-2" style={{ color: T.textSecondary }}>Word bank chips — 组词成句</div>
            <div className="flex gap-2 flex-wrap">
              {["南方的", "夏天", "热极了"].map(seg => (
                <span key={seg} className="px-3 py-1.5 rounded-xl border-2 font-bold text-sm" style={{ borderColor: T.teal, fontFamily: "'Noto Sans SC', sans-serif" }}>{seg}</span>
              ))}
            </div>
          </div>
        </div>
        <div className="p-6 rounded-xl border space-y-4" style={{ borderColor: T.border }}>
          <div className="text-xs font-semibold mb-2" style={{ color: T.textSecondary }}>Vocabulary card</div>
          <div className="space-y-2">
            {[
              { zh: "你好",   py: "nǐ hǎo",   en: "Hello"      },
              { zh: "谢谢",   py: "xièxie",  en: "Thank you"  },
              { zh: "再见",   py: "zàijiàn", en: "Goodbye"    },
            ].map(v => (
              <div key={v.zh} className="flex items-center gap-3 p-3 rounded-xl" style={{ backgroundColor: `${T.teal}08`, border: `1px solid ${T.teal}20` }}>
                <span className="font-bold text-lg" style={{ color: T.navy, fontFamily: "'Noto Sans SC', sans-serif" }}>{v.zh}</span>
                <span className="text-xs italic flex-1" style={{ color: T.textSecondary }}>({v.py})</span>
                <span className="text-sm font-medium" style={{ color: T.textPrimary }}>— {v.en}</span>
              </div>
            ))}
          </div>
          <div className="text-xs leading-relaxed space-y-1" style={{ color: T.textSecondary }}>
            <div>Font: <SpecTag>Noto Sans SC</SpecTag> always for 中文</div>
            <div>Line height: <SpecTag>1.5</SpecTag> for mixed Latin + CJK</div>
            <div>Exercise size: <SpecTag>16–18px</SpecTag></div>
            <div>Quiz display: <SpecTag>28–36px · Bold · Teal</SpecTag></div>
          </div>
        </div>
      </div>
    </Section>
  );
}

/* ═══════════════════════════════════════════
   ROOT HANDOFF EXPORT
═══════════════════════════════════════════ */

export default function Handoff() {
  const sections = [
    { id: "brand",      label: "Brand"            },
    { id: "colors",     label: "Colors"           },
    { id: "typography", label: "Typography"       },
    { id: "spacing",    label: "Spacing"          },
    { id: "components", label: "Components"       },
    { id: "layout",     label: "Layout"           },
    { id: "screens",    label: "Screen inventory" },
    { id: "exercises",  label: "Exercise types"   },
    { id: "chinese",    label: "Chinese rendering"},
  ];

  return (
    <div style={{ fontFamily: "'Plus Jakarta Sans', sans-serif", backgroundColor: T.surface, minHeight: "100vh" }}>
      {/* Header */}
      <div className="sticky top-0 z-10 border-b bg-white" style={{ borderColor: T.border }}>
        <div className="max-w-6xl mx-auto px-10 flex items-center justify-between" style={{ height: 60 }}>
          <div className="flex items-center gap-3">
            <img src={logoPencil} alt="Easy Study" className="object-contain" style={{ height: 28 }} />
            <div>
              <span className="font-bold text-sm" style={{ color: T.navy }}>Easy Study</span>
              <span className="text-xs ml-2 px-2 py-0.5 rounded font-semibold text-white" style={{ backgroundColor: T.teal, fontSize: 10 }}>Design Handoff</span>
            </div>
          </div>
          <nav className="flex items-center gap-1">
            {sections.map(s => (
              <a key={s.id} href={`#${s.id}`}
                className="px-3 py-1.5 rounded-lg text-xs font-medium hover:bg-gray-100 transition-colors"
                style={{ color: T.textSecondary }}>
                {s.label}
              </a>
            ))}
          </nav>
        </div>
      </div>

      {/* Hero */}
      <div className="border-b" style={{ backgroundColor: T.navy }}>
        <div className="max-w-6xl mx-auto px-10 py-12 grid grid-cols-2 gap-10 items-center">
          <div>
            <div className="text-xs font-bold uppercase tracking-widest mb-3" style={{ color: T.teal }}>Design Handoff v1.2</div>
            <h1 className="font-bold text-4xl text-white mb-2">Easy Study</h1>
            <div className="text-lg mb-4" style={{ color: "rgba(255,255,255,0.65)", fontFamily: "'Noto Sans SC', sans-serif" }}>易华文教中心</div>
            <p className="text-sm leading-relaxed" style={{ color: "rgba(255,255,255,0.55)" }}>
              Professional Chinese tutoring LMS for adult learners and solo tutors.
              Desktop sidebar + mobile bottom nav. Navy/Teal palette. Plus Jakarta Sans + Noto Sans SC.
            </p>
            <div className="flex items-center gap-3 mt-6 flex-wrap">
              {[{ label: "Screens",    value: "35" }, { label: "Components", value: "20+" }, { label: "Dialogs", value: "8" }, { label: "Ex. types", value: "5" }].map(({ label, value }) => (
                <div key={label} className="px-4 py-2 rounded-xl" style={{ backgroundColor: "rgba(255,255,255,0.08)" }}>
                  <div className="font-bold text-lg text-white leading-none">{value}</div>
                  <div className="text-xs" style={{ color: "rgba(255,255,255,0.5)" }}>{label}</div>
                </div>
              ))}
            </div>
          </div>
          <div className="flex justify-center">
            <img src={logoFull} alt="Easy Study full logo" className="h-32 w-auto object-contain rounded-2xl p-4 bg-white shadow-2xl" />
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-6xl mx-auto px-10 py-12">
        <div id="brand"><BrandSection /></div>
        <div id="colors"><ColorsSection /></div>
        <div id="typography"><TypographySection /></div>
        <div id="spacing"><SpacingSection /></div>
        <div id="components"><ComponentsSection /></div>
        <div id="layout"><LayoutSection /></div>
        <div id="screens"><ScreenInventorySection /></div>
        <div id="exercises"><ExerciseTypesSection /></div>
        <div id="chinese"><ChineseRenderingSection /></div>
      </div>

      {/* Footer */}
      <div className="border-t py-8 text-center" style={{ borderColor: T.border }}>
        <p className="text-sm" style={{ color: T.textSecondary }}>
          Easy Study Design Handoff · v1.2 · Jun 2026 · Generated from <code className="text-xs px-1.5 py-0.5 rounded" style={{ backgroundColor: T.surface }}>App.tsx</code>
        </p>
        <p className="text-xs mt-1" style={{ color: T.border }}>
          Figma Make file: <code>8LDbnO1nfJCZX74gGssbRB</code> · Flutter repo: <code>chinese-tracker</code>
        </p>
      </div>
    </div>
  );
}
