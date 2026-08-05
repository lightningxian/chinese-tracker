import { useState, useEffect } from "react";
import logoFull from "../imports/Logo_ES.png";
import logoPencil from "../imports/Pensil.png";
import Handoff from "./Handoff";
import {
  BarChart, Bar, XAxis, YAxis, ResponsiveContainer,
} from "recharts";
import {
  Home, Users, BookOpen, Calendar, User, Bell, LogOut,
  ChevronRight, Search, Plus, MoreVertical, Clock, AlertCircle,
  TrendingUp, Copy, Video, FileText, Trash2, Check, ArrowLeft,
  Eye, EyeOff, Upload, X, CheckCircle, Construction, Lock,
  Edit, RotateCcw, Info, Ticket, BarChart3, Play, Pause, Volume2,
  Headphones, ShieldCheck, GraduationCap, DollarSign, UserCheck, Award,
} from "lucide-react";

/* ─── Brand tokens ─── */
const NAVY = "#1B2A4A";
const NAVY_LIGHT = "#2A3F66";
const TEAL = "#2D6A7E";
const SURFACE = "#F5F6F8";
const TEXT_PRIMARY = "#1A1D26";
const TEXT_SECONDARY = "#5C6370";
const BORDER = "#E2E5EB";
const SUCCESS = "#2E7D5A";
const ERROR = "#B53A3A";
const YELLOW = "#F5B800";

/* ─── Roles ─── */
type Role = "admin" | "guru" | "murid";
const ROLE_LABEL: Record<Role, string> = { admin: "Admin", guru: "Guru", murid: "Murid" };

/* ─── Navigation types ─── */
type AuthMode = "test" | "login" | "register-guru" | "register-murid";

type Screen =
  | { type: "studentDetail"; studentId: number }
  | { type: "exerciseForm"; exerciseId?: number }
  | { type: "classForm"; classId?: number }
  | { type: "classDetail"; classId: number }
  | { type: "studentClassDetail"; classId: number }
  | { type: "importReview"; exerciseId?: number }
  | { type: "completeProfile"; role: Role }
  | { type: "exercisePlay"; exerciseId: number }
  | { type: "lessonDetail"; lessonNum: number }
  | { type: "quiz"; lessonNum: number }
  | { type: "quizScore"; lessonNum: number; score: number; total: number }
  | { type: "notifications" };

type GuruTab   = "dashboard" | "students" | "classes" | "exercises" | "profile";
type MuridTab  = "home" | "myClasses" | "lessons" | "progress" | "profile";
type AdminTab  = "dashboard" | "users" | "exercises" | "classes" | "vouchers" | "reports" | "profile";

/* ─── Mobile hook ─── */
function useIsMobile() {
  const [mobile, setMobile] = useState(() => window.innerWidth < 900);
  useEffect(() => {
    const fn = () => setMobile(window.innerWidth < 900);
    window.addEventListener("resize", fn);
    return () => window.removeEventListener("resize", fn);
  }, []);
  return mobile;
}

/* ─── Static data ─── */
const weekData = [
  { day: "Mon", sessions: 4 }, { day: "Tue", sessions: 6 },
  { day: "Wed", sessions: 2 }, { day: "Thu", sessions: 8 },
  { day: "Fri", sessions: 5 }, { day: "Sat", sessions: 3 },
  { day: "Sun", sessions: 1 },
];

const students = [
  { id: 1, name: "Wang Fang",    initials: "WF", hsk: 2, term: 1, lessons: 5,  total: 8,  sessions: 6,  lastSeen: "Dec 18", joined: "Nov 10, 2024", score: 80 },
  { id: 2, name: "Li Ming",      initials: "LM", hsk: 3, term: 1, lessons: 3,  total: 8,  sessions: 10, lastSeen: "Dec 20", joined: "Nov 2, 2024",  score: 82 },
  { id: 3, name: "Ahmad Hassan", initials: "AH", hsk: 1, term: 2, lessons: 6,  total: 16, sessions: 4,  lastSeen: "Dec 5",  joined: "Oct 15, 2024", score: 67 },
  { id: 4, name: "Priya Sharma", initials: "PS", hsk: 4, term: 1, lessons: 7,  total: 8,  sessions: 2,  lastSeen: "Dec 19", joined: "Nov 20, 2024", score: 91 },
  { id: 5, name: "Carlos Mendez",initials: "CM", hsk: 2, term: 1, lessons: 2,  total: 8,  sessions: 8,  lastSeen: "Dec 21", joined: "Nov 5, 2024",  score: 74 },
  { id: 6, name: "Yuki Tanaka",  initials: "YT", hsk: 5, term: 2, lessons: 12, total: 16, sessions: 6,  lastSeen: "Dec 17", joined: "Sep 1, 2024",  score: 88 },
];

const exercises = [
  { id: 1, title: "HSK 2 Grammar — Unit 3",          type: "Multiple choice",   questions: 5,  hsk: 2, status: "published", assigned: 3, due: "Dec 20" },
  { id: 2, title: "Reading Comprehension — Markets",  type: "Compose sentences", questions: 3,  hsk: 3, status: "published", assigned: 2, due: null },
  { id: 3, title: "Dialogue Matching — Family",       type: "Matching",          questions: 6,  hsk: 1, status: "draft",     assigned: 0, due: null },
  { id: 4, title: "HSK 4 Vocabulary Sprint",          type: "Multiple choice",   questions: 10, hsk: 4, status: "draft",     assigned: 0, due: null },
  { id: 5, title: "HSK 3 Listening — Directions",     type: "Listening",         questions: 4,  hsk: 3, status: "published", assigned: 2, due: "Dec 28" },
];

/* Admin — users, vouchers, notifications, trends */
const adminUsers = [
  { id: 1, name: "Teacher Ng",    initials: "TN", role: "Guru",  email: "teacher.ng@easystudy.com", active: true,  students: 12, joined: "Aug 2, 2024" },
  { id: 2, name: "Ms. Rahmawati", initials: "MR", role: "Guru",  email: "rahma@easystudy.com",      active: true,  students: 8,  joined: "Sep 12, 2024" },
  { id: 3, name: "Wang Fang",     initials: "WF", role: "Murid", email: "wang.fang@mail.com",       active: true,  students: 0,  joined: "Nov 10, 2024" },
  { id: 4, name: "Li Ming",       initials: "LM", role: "Murid", email: "li.ming@mail.com",         active: true,  students: 0,  joined: "Nov 2, 2024" },
  { id: 5, name: "Ahmad Hassan",  initials: "AH", role: "Murid", email: "ahmad.h@mail.com",         active: false, students: 0,  joined: "Oct 15, 2024" },
  { id: 6, name: "Budi Santoso",  initials: "BS", role: "Guru",  email: "budi.s@easystudy.com",     active: false, students: 0,  joined: "Jul 1, 2024" },
];

const vouchers = [
  { id: 1, code: "ES-8SESS-A1", type: "8 sessions",  status: "active",   issuedTo: "Wang Fang",  issuedOn: "Nov 10, 2024", remaining: 6 },
  { id: 2, code: "ES-16SESS-B2",type: "16 sessions", status: "active",   issuedTo: "Li Ming",    issuedOn: "Nov 2, 2024",  remaining: 10 },
  { id: 3, code: "ES-8SESS-C3", type: "8 sessions",  status: "low",      issuedTo: "Priya Sharma",issuedOn: "Nov 20, 2024", remaining: 2 },
  { id: 4, code: "ES-16SESS-D4",type: "16 sessions", status: "depleted", issuedTo: "Ahmad Hassan",issuedOn: "Oct 15, 2024", remaining: 0 },
  { id: 5, code: "ES-8SESS-E5", type: "8 sessions",  status: "unissued", issuedTo: null,          issuedOn: null,           remaining: 8 },
];

const monthlyStudents = [
  { m: "Jul", v: 3 }, { m: "Aug", v: 5 }, { m: "Sep", v: 8 },
  { m: "Oct", v: 6 }, { m: "Nov", v: 11 }, { m: "Dec", v: 9 },
];
const monthlyIncome = [
  { m: "Jul", v: 4.2 }, { m: "Aug", v: 6.8 }, { m: "Sep", v: 9.1 },
  { m: "Oct", v: 7.5 }, { m: "Nov", v: 12.3 }, { m: "Dec", v: 10.6 },
];

const notifications = [
  { id: 1, kind: "registration", title: "New murid registered", body: "Carlos Mendez signed up with Teacher Ng's invite code.", day: "Today", time: "09:12", read: false },
  { id: 2, kind: "grading",      title: "Grading complete",     body: "Li Ming scored 90% on Greetings Quiz.",                  day: "Today", time: "08:40", read: false },
  { id: 3, kind: "session",      title: "Upcoming class",       body: "HSK 2 — Grammar Review starts in 1 hour.",               day: "Today", time: "08:00", read: false },
  { id: 4, kind: "registration", title: "Guru approved",        body: "Ms. Rahmawati's account was approved by Admin.",         day: "Yesterday", time: "16:20", read: true },
  { id: 5, kind: "grading",      title: "Grading complete",     body: "Wang Fang scored 80% on HSK 2 Grammar.",                 day: "Yesterday", time: "11:05", read: true },
  { id: 6, kind: "session",      title: "Class reminder",       body: "HSK 1 — Foundations concluded. Attendance credited.",    day: "Dec 20", time: "09:45", read: true },
];

const classes = [
  { id: 1, title: "HSK 2 — Grammar Review",    date: "Mon 23 Dec", time: "10:00 AM", duration: 60, students: 4, status: "upcoming",  link: "https://zoom.us/j/123" },
  { id: 2, title: "HSK 3 — Speaking Practice", date: "Wed 25 Dec", time: "2:00 PM",  duration: 60, students: 3, status: "upcoming",  link: null },
  { id: 3, title: "HSK 1 — Foundations",       date: "Fri 20 Dec", time: "9:00 AM",  duration: 45, students: 2, status: "concluded", link: null },
  { id: 4, title: "HSK 4 — Advanced Reading",  date: "Thu 19 Dec", time: "11:00 AM", duration: 90, students: 3, status: "concluded", link: null },
];

const mcQuestions = [
  { q: "南方的天气很（ ）",   hint: "Southern weather is very ___",         options: ["热", "冷", "好", "大"],          answer: 0 },
  { q: "他每天（ ）去学校",   hint: "He ___ goes to school every day",      options: ["走路", "跑步", "骑车", "开车"],  answer: 2 },
  { q: "这本书（ ）？",       hint: "How much is this book?",               options: ["多少钱", "什么时候", "在哪里", "怎么样"], answer: 0 },
  { q: "我（ ）喜欢吃饺子",   hint: "I really like eating dumplings",       options: ["非常", "有点", "不太", "已经"],  answer: 0 },
  { q: "明天（ ）下雨",       hint: "It ___ rain tomorrow",                 options: ["可能", "一定", "已经", "还是"],  answer: 0 },
];

const quizQuestions = [
  { q: "What does 谢谢 mean?",    chinese: "谢谢",       options: ["Thank you", "Hello", "Goodbye", "Please"],          answer: 0 },
  { q: "What does 你好 mean?",    chinese: "你好",       options: ["Thank you", "Hello", "Goodbye", "Excuse me"],       answer: 1 },
  { q: "What does 再见 mean?",    chinese: "再见",       options: ["See you later", "Hello", "Thank you", "Sorry"],     answer: 0 },
  { q: "Which means 'I'?",       chinese: "我/你/他/她", options: ["我", "你", "他", "她"],                              answer: 0 },
  { q: "What does 对不起 mean?",  chinese: "对不起",     options: ["You're welcome", "Sorry", "Goodbye", "Please"],     answer: 1 },
];

/* ═══════════════════════════════════════════
   SHARED ATOMS
═══════════════════════════════════════════ */

function HskBadge({ level }: { level: number }) {
  return (
    <span className="inline-flex items-center px-2 py-0.5 rounded text-white font-semibold"
      style={{ backgroundColor: TEAL, fontSize: 11 }}>HSK {level}</span>
  );
}

function StatusPill({ status }: { status: string }) {
  const map: Record<string, { bg: string; color: string; label: string }> = {
    published:   { bg: "#E8F5EE", color: SUCCESS,        label: "Published"   },
    draft:       { bg: "#F0F0F3", color: TEXT_SECONDARY, label: "Draft"       },
    upcoming:    { bg: "#E5F0F4", color: TEAL,           label: "Upcoming"    },
    concluded:   { bg: "#E8F5EE", color: SUCCESS,        label: "Concluded"   },
    not_started: { bg: "#F0F0F3", color: TEXT_SECONDARY, label: "Not started" },
    in_progress: { bg: "#E5F0F4", color: TEAL,           label: "In progress" },
    done:        { bg: "#E8F5EE", color: SUCCESS,        label: "Done"        },
  };
  const s = map[status] ?? map.draft;
  return (
    <span className="inline-flex items-center px-2 py-0.5 rounded-full font-semibold"
      style={{ backgroundColor: s.bg, color: s.color, fontSize: 11 }}>{s.label}</span>
  );
}

function Avatar({ initials, size = 36, color = NAVY }: { initials: string; size?: number; color?: string }) {
  return (
    <div className="flex items-center justify-center rounded-full text-white font-semibold flex-shrink-0"
      style={{ width: size, height: size, backgroundColor: color, fontSize: size * 0.35 }}>{initials}</div>
  );
}

function Card({ children, className = "", onClick }: { children: React.ReactNode; className?: string; onClick?: () => void }) {
  return (
    <div onClick={onClick}
      className={`bg-white rounded-xl border p-4 ${className} ${onClick ? "cursor-pointer hover:shadow-sm transition-shadow" : ""}`}
      style={{ borderColor: BORDER }}>{children}</div>
  );
}

function SectionHeader({ title, action }: { title: string; action?: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between mb-3">
      <h3 className="font-bold" style={{ color: NAVY, fontSize: 15 }}>{title}</h3>
      {action}
    </div>
  );
}

function TealLink({ children, onClick }: { children: React.ReactNode; onClick?: () => void }) {
  return (
    <button onClick={onClick} className="text-sm font-semibold hover:underline" style={{ color: TEAL }}>{children}</button>
  );
}

function NavyBtn({ children, onClick, small, full }: { children: React.ReactNode; onClick?: () => void; small?: boolean; full?: boolean }) {
  return (
    <button onClick={onClick}
      className={`rounded-lg font-semibold text-white transition-all hover:opacity-90 active:scale-95 ${small ? "px-3 py-1.5 text-xs" : "px-4 py-2.5 text-sm"} ${full ? "w-full" : ""}`}
      style={{ backgroundColor: NAVY }}>{children}</button>
  );
}

function TealBtn({ children, onClick, full }: { children: React.ReactNode; onClick?: () => void; full?: boolean }) {
  return (
    <button onClick={onClick}
      className={`rounded-lg font-semibold text-white transition-all hover:opacity-90 active:scale-95 px-4 py-2.5 text-sm ${full ? "w-full" : ""}`}
      style={{ backgroundColor: TEAL }}>{children}</button>
  );
}

function OutlineBtn({ children, onClick, danger }: { children: React.ReactNode; onClick?: () => void; danger?: boolean }) {
  const color = danger ? ERROR : NAVY;
  return (
    <button onClick={onClick}
      className="px-4 py-2.5 rounded-lg text-sm font-semibold border transition-all hover:opacity-80"
      style={{ borderColor: color, color }}>{children}</button>
  );
}

function EmptyState({ icon: Icon, title, subtitle, cta }: { icon: React.ElementType; title: string; subtitle: string; cta?: React.ReactNode }) {
  return (
    <div className="flex flex-col items-center justify-center py-16 px-6 text-center">
      <Icon size={48} style={{ color: TEXT_SECONDARY }} className="mb-4" />
      <p className="font-semibold text-base mb-1" style={{ color: NAVY }}>{title}</p>
      <p className="text-sm max-w-xs leading-relaxed" style={{ color: TEXT_SECONDARY }}>{subtitle}</p>
      {cta && <div className="mt-4">{cta}</div>}
    </div>
  );
}

function InputField({ label, type = "text", placeholder, value, onChange, right }: {
  label: string; type?: string; placeholder?: string;
  value?: string; onChange?: (v: string) => void; right?: React.ReactNode;
}) {
  return (
    <div>
      <label className="block text-xs font-semibold mb-1" style={{ color: TEXT_PRIMARY }}>{label}</label>
      <div className="relative">
        <input type={type} placeholder={placeholder} value={value} onChange={e => onChange?.(e.target.value)}
          className="w-full px-3 py-2.5 rounded-lg border bg-white text-sm outline-none"
          style={{ borderColor: BORDER, color: TEXT_PRIMARY, paddingRight: right ? 40 : undefined }} />
        {right && <div className="absolute right-3 top-1/2 -translate-y-1/2">{right}</div>}
      </div>
    </div>
  );
}

function Modal({ onClose, children, wide }: { onClose: () => void; children: React.ReactNode; wide?: boolean }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center" style={{ backgroundColor: "rgba(0,0,0,0.5)" }} onClick={onClose}>
      <div className={`bg-white rounded-2xl shadow-2xl p-6 mx-4 ${wide ? "w-full max-w-xl" : "w-full max-w-sm"}`} onClick={e => e.stopPropagation()}>
        {children}
      </div>
    </div>
  );
}

function Snackbar({ message, type = "error", onClose }: { message: string; type?: "error" | "success"; onClose: () => void }) {
  useEffect(() => { const t = setTimeout(onClose, 3000); return () => clearTimeout(t); }, [onClose]);
  return (
    <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 flex items-center gap-3 px-5 py-3 rounded-xl shadow-lg text-white text-sm font-medium"
      style={{ backgroundColor: type === "error" ? ERROR : SUCCESS }}>
      {message}<button onClick={onClose}><X size={14} /></button>
    </div>
  );
}

function Ring({ value, total, size = 80, stroke = 8 }: { value: number; total: number; size?: number; stroke?: number }) {
  const r = (size - stroke) / 2;
  const circ = 2 * Math.PI * r;
  return (
    <div className="relative inline-flex items-center justify-center">
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={BORDER} strokeWidth={stroke} />
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={TEAL} strokeWidth={stroke}
          strokeDasharray={circ} strokeDashoffset={circ * (1 - value / total)}
          strokeLinecap="round" transform={`rotate(-90 ${size/2} ${size/2})`} />
      </svg>
      <div className="absolute text-center">
        <div className="font-bold" style={{ color: NAVY, fontSize: size * 0.18 }}>{value}/{total}</div>
        <div style={{ color: TEXT_SECONDARY, fontSize: size * 0.11 }}>lessons</div>
      </div>
    </div>
  );
}

function PushedBar({ title, onBack, right }: { title: string; onBack: () => void; right?: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between px-6 h-14 flex-shrink-0 border-b bg-white" style={{ borderColor: BORDER }}>
      <div className="flex items-center gap-3">
        <button onClick={onBack} className="p-1.5 rounded-lg hover:bg-gray-100 transition-colors">
          <ArrowLeft size={18} style={{ color: NAVY }} />
        </button>
        <span className="font-bold text-base" style={{ color: NAVY }}>{title}</span>
      </div>
      {right}
    </div>
  );
}

/* ═══════════════════════════════════════════
   AUTH SCREEN
═══════════════════════════════════════════ */

function AuthScreen({ onLogin }: { onLogin: (role: Role, firstTime?: boolean) => void }) {
  const [mode, setMode] = useState<AuthMode>("test");
  const [showPw, setShowPw] = useState(false);
  const [loading, setLoading] = useState(false);
  const [snack, setSnack] = useState<string | null>(null);

  const fakeLogin = (role: Role, firstTime = false) => {
    setLoading(true);
    setTimeout(() => { setLoading(false); onLogin(role, firstTime); }, 800);
  };

  return (
    <div className="h-screen w-full flex flex-col items-center justify-center" style={{ backgroundColor: "#000" }}>
      {snack && <Snackbar message={snack} onClose={() => setSnack(null)} />}
      <div className="flex flex-col items-center mb-8">
        <div className="bg-white rounded-2xl px-6 py-4 shadow-lg">
          <img src={logoFull} alt="Easy Study — 易华文教中心" className="h-20 w-auto object-contain" />
        </div>
      </div>

      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-sm mx-4 overflow-hidden">
        <div className="flex border-b" style={{ borderColor: BORDER }}>
          {(["test", "login"] as const).map(m => (
            <button key={m} onClick={() => setMode(m)}
              className="flex-1 py-3 text-sm font-semibold transition-colors"
              style={{ color: mode === m ? NAVY : TEXT_SECONDARY, borderBottom: mode === m ? `2px solid ${TEAL}` : "2px solid transparent" }}>
              {m === "test" ? "Test login" : "Sign in"}
            </button>
          ))}
        </div>

        <div className="p-6">
          {mode === "test" && (
            <div>
              <p className="text-sm mb-5" style={{ color: TEXT_SECONDARY }}>Dev mode — choose a role to preview the app.</p>
              <div className="space-y-3">
                {([{ role: "admin" as const, label: "Admin", desc: "Users, exercises, vouchers, reports", icon: ShieldCheck, color: "#7A4FBF" },
                   { role: "guru" as const, label: "Guru", desc: "Students, classes, attendance", icon: GraduationCap, color: NAVY },
                   { role: "murid" as const, label: "Murid", desc: "Classes, exercises, progress", icon: BookOpen, color: TEAL }]).map(({ role, label, desc, icon: Icon, color }) => (
                  <button key={role} onClick={() => fakeLogin(role)} disabled={loading}
                    className="w-full flex items-center gap-3 p-4 rounded-xl border-2 transition-all hover:shadow-sm text-left"
                    style={{ borderColor: color }}>
                    <div className="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0" style={{ backgroundColor: `${color}15` }}>
                      <Icon size={18} style={{ color }} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="font-bold text-sm" style={{ color }}>{label}</div>
                      <div className="text-xs" style={{ color: TEXT_SECONDARY }}>{desc}</div>
                    </div>
                    <ChevronRight size={16} style={{ color: TEXT_SECONDARY }} />
                  </button>
                ))}
              </div>
              {loading && <div className="flex justify-center mt-4"><div className="w-5 h-5 rounded-full border-2 border-t-transparent animate-spin" style={{ borderColor: TEAL, borderTopColor: "transparent" }} /></div>}
            </div>
          )}

          {mode === "login" && (
            <div className="space-y-4">
              <div>
                <h2 className="font-bold text-xl mb-0.5" style={{ color: NAVY }}>Welcome back</h2>
                <p className="text-sm" style={{ color: TEXT_SECONDARY }}>Sign in to continue</p>
              </div>
              <InputField label="Email" type="email" placeholder="you@example.com" />
              <InputField label="Password" type={showPw ? "text" : "password"} placeholder="••••••••"
                right={<button onClick={() => setShowPw(v => !v)}>{showPw ? <EyeOff size={15} style={{ color: TEXT_SECONDARY }} /> : <Eye size={15} style={{ color: TEXT_SECONDARY }} />}</button>} />
              <div className="flex justify-end"><TealLink>Forgot password?</TealLink></div>
              <NavyBtn full onClick={() => setSnack("Incorrect email or password")}>Sign in</NavyBtn>
              <div className="flex items-center gap-3">
                <div className="flex-1 h-px" style={{ backgroundColor: BORDER }} />
                <span className="text-xs" style={{ color: TEXT_SECONDARY }}>or</span>
                <div className="flex-1 h-px" style={{ backgroundColor: BORDER }} />
              </div>
              <button className="w-full py-2.5 rounded-lg font-semibold text-sm border transition-all hover:bg-gray-50 flex items-center justify-center gap-2"
                style={{ borderColor: BORDER, color: TEXT_PRIMARY }}>
                <span className="font-bold">G</span> Continue with Google
              </button>
              <p className="text-center text-xs" style={{ color: TEXT_SECONDARY }}>
                Don&apos;t have an account?{" "}
                <button onClick={() => setMode("register-guru")} className="font-semibold" style={{ color: TEAL }}>Register</button>
              </p>
            </div>
          )}

          {(mode === "register-guru" || mode === "register-murid") && (
            <div className="space-y-4">
              <h2 className="font-bold text-xl" style={{ color: NAVY }}>
                {mode === "register-guru" ? "Create your account" : "Join Easy Study"}
              </h2>
              <div className="grid grid-cols-2 gap-2">
                {(["register-guru", "register-murid"] as AuthMode[]).map(r => {
                  const active = mode === r;
                  const c = r === "register-guru" ? NAVY : TEAL;
                  return (
                    <button key={r} onClick={() => setMode(r)}
                      className="py-3 px-2 rounded-xl border-2 text-xs font-semibold transition-all"
                      style={{ borderColor: active ? c : BORDER, color: active ? c : TEXT_SECONDARY, backgroundColor: active ? `${c}10` : "#fff" }}>
                      {r === "register-guru" ? "🎓 Guru" : "📚 Murid"}
                    </button>
                  );
                })}
              </div>
              <InputField label="Full name" placeholder="Your name" />
              <InputField label="Email" type="email" placeholder="you@example.com" />
              <InputField label="Password" type="password" placeholder="••••••••" />
              {mode === "register-murid" && <>
                <InputField label="Teacher invite code" placeholder="6-character code" />
                <div>
                  <label className="block text-xs font-semibold mb-1" style={{ color: TEXT_PRIMARY }}>HSK level</label>
                  <select className="w-full px-3 py-2.5 rounded-lg border bg-white text-sm outline-none" style={{ borderColor: BORDER }}>
                    {[1,2,3,4,5,6].map(l => <option key={l}>HSK {l}</option>)}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold mb-1" style={{ color: TEXT_PRIMARY }}>Lessons per term</label>
                  <div className="flex gap-2">
                    {["8 lessons", "16 lessons"].map(o => (
                      <button key={o} className="flex-1 py-2 rounded-lg border text-sm font-semibold" style={{ borderColor: BORDER, color: TEXT_SECONDARY }}>{o}</button>
                    ))}
                  </div>
                </div>
              </>}
              <button onClick={() => fakeLogin(mode === "register-guru" ? "guru" : "murid", true)}
                className="w-full py-2.5 rounded-lg font-semibold text-white text-sm hover:opacity-90"
                style={{ backgroundColor: mode === "register-guru" ? NAVY : TEAL }}>
                {mode === "register-guru" ? "Create guru account" : "Join as murid"}
              </button>
              <p className="text-center text-xs" style={{ color: TEXT_SECONDARY }}>
                Already have an account?{" "}
                <button onClick={() => setMode("login")} className="font-semibold" style={{ color: TEAL }}>Sign in</button>
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════
   SIDEBAR + TOP BAR
═══════════════════════════════════════════ */

const guruNav = [
  { id: "dashboard" as GuruTab, label: "Dashboard", icon: Home },
  { id: "students"  as GuruTab, label: "Students",  icon: Users },
  { id: "classes"   as GuruTab, label: "Classes",   icon: Calendar },
  { id: "exercises" as GuruTab, label: "Exercises", icon: BookOpen },
  { id: "profile"   as GuruTab, label: "Profile",   icon: User },
];
const muridNav = [
  { id: "home"      as MuridTab, label: "Home",       icon: Home },
  { id: "myClasses" as MuridTab, label: "My Classes", icon: Calendar },
  { id: "lessons"   as MuridTab, label: "Lessons",    icon: BookOpen },
  { id: "progress"  as MuridTab, label: "Progress",   icon: TrendingUp },
  { id: "profile"   as MuridTab, label: "Profile",    icon: User },
];
const adminNav = [
  { id: "dashboard" as AdminTab, label: "Dashboard", icon: Home },
  { id: "users"     as AdminTab, label: "Users",     icon: Users },
  { id: "exercises" as AdminTab, label: "Exercises", icon: BookOpen },
  { id: "classes"   as AdminTab, label: "Classes",   icon: Calendar },
  { id: "vouchers"  as AdminTab, label: "Vouchers",  icon: Ticket },
  { id: "reports"   as AdminTab, label: "Reports",   icon: BarChart3 },
  { id: "profile"   as AdminTab, label: "Profile",   icon: User },
];

const USER_BY_ROLE: Record<Role, { name: string; initials: string; accent: string; hsk?: number }> = {
  admin: { name: "Admin Chen", initials: "AC", accent: "#7A4FBF" },
  guru:  { name: "Teacher Ng", initials: "TN", accent: NAVY_LIGHT },
  murid: { name: "Li Ming",    initials: "LM", accent: TEAL, hsk: 3 },
};

function Sidebar({ activeTab, setTab, nav, role, onSignOut, onRoleSwitch }: {
  activeTab: string; setTab: (t: string) => void; nav: { id: string; label: string; icon: React.ElementType }[];
  role: Role; onSignOut: () => void; onRoleSwitch: () => void;
}) {
  const u = USER_BY_ROLE[role];
  return (
    <aside className="flex flex-col h-full flex-shrink-0" style={{ backgroundColor: NAVY, width: 240 }}>
      <div className="px-5 pt-6 pb-4 border-b" style={{ borderColor: "rgba(255,255,255,0.1)" }}>
        <div className="flex items-center gap-2.5 mb-4">
          <img src={logoPencil} alt="Easy Study mascot" className="object-contain flex-shrink-0" style={{ height: 28, width: "auto" }} />
          <div>
            <div className="font-bold text-white text-sm leading-tight">Easy Study</div>
            <div className="text-xs leading-tight" style={{ color: "rgba(255,255,255,0.5)", fontFamily: "'Noto Sans SC', sans-serif" }}>易华文教中心</div>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Avatar initials={u.initials} size={32} color={u.accent} />
          <div className="min-w-0">
            <div className="text-white text-xs font-semibold truncate">{u.name}</div>
            <div className="flex items-center gap-1.5 mt-0.5">
              <span className="text-xs px-1.5 py-0.5 rounded font-medium"
                style={{ backgroundColor: "rgba(255,255,255,0.1)", color: "rgba(255,255,255,0.65)", fontSize: 10 }}>{ROLE_LABEL[role]}</span>
              {u.hsk && <HskBadge level={u.hsk} />}
            </div>
          </div>
        </div>
      </div>

      <nav className="flex-1 px-3 py-3 space-y-0.5 overflow-y-auto">
        {nav.map(({ id, label, icon: Icon }) => {
          const active = activeTab === id;
          return (
            <button key={id} onClick={() => setTab(id)}
              className="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all text-left"
              style={{ backgroundColor: active ? "rgba(45,106,126,0.28)" : "transparent", color: active ? "#fff" : "rgba(255,255,255,0.52)", borderLeft: active ? `3px solid ${TEAL}` : "3px solid transparent" }}>
              <Icon size={16} />{label}
            </button>
          );
        })}
      </nav>

      <div className="px-3 pb-4 pt-2 space-y-1 border-t" style={{ borderColor: "rgba(255,255,255,0.08)" }}>
        <button onClick={onRoleSwitch}
          className="w-full flex items-center gap-2.5 px-3 py-2 rounded-lg text-xs font-medium"
          style={{ color: "rgba(255,255,255,0.45)", backgroundColor: "rgba(255,255,255,0.05)" }}>
          <User size={13} />Switch role (demo)
        </button>
        <button onClick={onSignOut}
          className="w-full flex items-center gap-2.5 px-3 py-2 rounded-lg text-xs font-medium hover:bg-red-900/20"
          style={{ color: ERROR }}>
          <LogOut size={13} />Sign out
        </button>
      </div>
    </aside>
  );
}

function TopBar({ title, action, role, unread, onBell }: { title: string; action?: React.ReactNode; role: Role; unread: number; onBell: () => void }) {
  const u = USER_BY_ROLE[role];
  return (
    <div className="flex items-center justify-between px-8 h-14 bg-white border-b flex-shrink-0" style={{ borderColor: BORDER }}>
      <h1 className="font-bold text-base" style={{ color: NAVY }}>{title}</h1>
      <div className="flex items-center gap-3">
        {action}
        <button onClick={onBell} className="relative p-1.5 rounded-lg hover:bg-gray-100 transition-colors">
          <Bell size={18} style={{ color: TEXT_SECONDARY }} />
          {unread > 0 && (
            <span className="absolute -top-0.5 -right-0.5 min-w-4 h-4 px-1 flex items-center justify-center rounded-full text-white font-bold" style={{ backgroundColor: ERROR, fontSize: 9 }}>{unread}</span>
          )}
        </button>
        <Avatar initials={u.initials} size={32} color={u.accent} />
        <div>
          <div className="text-xs font-semibold" style={{ color: TEXT_PRIMARY }}>{u.name}</div>
          <div className="text-xs" style={{ color: TEXT_SECONDARY }}>Good morning</div>
        </div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════
   TEACHER TAB SCREENS
═══════════════════════════════════════════ */

function TeacherDashboard({ push }: { push: (s: Screen) => void }) {
  const today = new Date().getDay();
  return (
    <div className="p-8 overflow-y-auto flex-1">
      <div className="grid grid-cols-3 gap-6 max-w-5xl">
        <div className="col-span-2 space-y-6">
          <div className="grid grid-cols-3 gap-4">
            {[{ label: "Students", value: "12", icon: Users, color: TEAL },
              { label: "Active exercises", value: "3", icon: BookOpen, color: NAVY },
              { label: "Classes this term", value: "5", icon: Calendar, color: NAVY_LIGHT }]
              .map(({ label, value, icon: Icon, color }) => (
              <Card key={label} className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0" style={{ backgroundColor: `${color}18` }}>
                  <Icon size={18} style={{ color }} />
                </div>
                <div>
                  <div className="font-bold text-2xl leading-none" style={{ color: NAVY }}>{value}</div>
                  <div className="text-xs mt-0.5" style={{ color: TEXT_SECONDARY }}>{label}</div>
                </div>
              </Card>
            ))}
          </div>

          <Card>
            <SectionHeader title="This week" />
            <div className="h-28">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={weekData.map((d, i) => ({ ...d, fill: i === today - 1 ? NAVY : `${TEAL}8C` }))} barSize={24}>
                  <XAxis dataKey="day" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: TEXT_SECONDARY }} />
                  <YAxis hide />
                  <Bar dataKey="sessions" radius={[4, 4, 0, 0]} isAnimationActive={false} />
                </BarChart>
              </ResponsiveContainer>
            </div>
            <p className="text-xs mt-2" style={{ color: TEXT_SECONDARY }}>4 students active · 2 exercises completed</p>
          </Card>

          <div>
            <SectionHeader title="Needs attention"
              action={<span className="px-2 py-0.5 rounded-full text-xs font-bold text-white" style={{ backgroundColor: ERROR }}>3</span>} />
            <div className="space-y-3">
              {[{ accent: ERROR, icon: AlertCircle, title: "Wang Fang — HSK 2 Practice overdue", sub: "Due 3 days ago · Multiple choice", id: 1 },
                { accent: TEAL,  icon: Clock,        title: "Li Ming — 2 sessions remaining",     sub: "Term ends Dec 30",               id: 2 },
                { accent: TEXT_SECONDARY, icon: User, title: "Ahmad Hassan — No activity in 14 days", sub: "Last seen Nov 15",           id: 3 }]
                .map(({ accent, icon: Icon, title, sub, id }) => (
                <Card key={title} onClick={() => push({ type: "studentDetail", studentId: id })} className="flex items-center gap-3 !p-3 group">
                  <div className="w-1 self-stretch rounded-full flex-shrink-0" style={{ backgroundColor: accent }} />
                  <Icon size={18} style={{ color: accent }} className="flex-shrink-0" />
                  <div className="flex-1 min-w-0">
                    <div className="text-sm font-semibold truncate" style={{ color: TEXT_PRIMARY }}>{title}</div>
                    <div className="text-xs" style={{ color: TEXT_SECONDARY }}>{sub}</div>
                  </div>
                  <ChevronRight size={16} style={{ color: TEXT_SECONDARY }} className="flex-shrink-0 group-hover:translate-x-0.5 transition-transform" />
                </Card>
              ))}
            </div>
          </div>
        </div>

        <div className="space-y-6">
          <Card>
            <SectionHeader title="Quick actions" />
            <div className="space-y-2">
              <NavyBtn full onClick={() => push({ type: "exerciseForm" })}>
                <div className="flex items-center gap-2 justify-center"><Plus size={14} />New exercise</div>
              </NavyBtn>
              <button onClick={() => push({ type: "classForm" })}
                className="w-full flex items-center gap-2 justify-center px-4 py-2.5 rounded-lg text-sm font-semibold border hover:bg-gray-50"
                style={{ borderColor: NAVY, color: NAVY }}>
                <Calendar size={14} />New class
              </button>
            </div>
          </Card>
          <Card>
            <SectionHeader title="Recent activity" action={<TealLink>See all</TealLink>} />
            <div className="space-y-3">
              {students.slice(0, 4).map(s => (
                <div key={s.id} className="flex items-center gap-2 cursor-pointer" onClick={() => push({ type: "studentDetail", studentId: s.id })}>
                  <Avatar initials={s.initials} size={30} />
                  <div className="flex-1 min-w-0">
                    <div className="text-xs font-semibold truncate" style={{ color: TEXT_PRIMARY }}>{s.name}</div>
                    <div className="text-xs" style={{ color: TEXT_SECONDARY }}>{s.lastSeen}</div>
                  </div>
                  <HskBadge level={s.hsk} />
                </div>
              ))}
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}

function TeacherStudents({ push }: { push: (s: Screen) => void }) {
  const [search, setSearch] = useState("");
  const filtered = students.filter(s => s.name.toLowerCase().includes(search.toLowerCase()));
  return (
    <div className="p-8 overflow-y-auto flex-1">
      <div className="max-w-4xl space-y-4">
        <div className="flex items-center gap-3">
          <div className="relative flex-1 max-w-sm">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2" style={{ color: TEXT_SECONDARY }} />
            <input type="text" placeholder="Search students…" value={search} onChange={e => setSearch(e.target.value)}
              className="w-full pl-9 pr-4 py-2 rounded-lg border bg-white text-sm outline-none" style={{ borderColor: BORDER, fontSize: 13 }} />
          </div>
          <span className="text-sm font-semibold px-2.5 py-1 rounded-full text-white" style={{ backgroundColor: NAVY, fontSize: 12 }}>{filtered.length} students</span>
        </div>
        <Card className="!p-0 overflow-hidden">
          <div className="grid text-xs font-bold px-4 py-3 border-b"
            style={{ gridTemplateColumns: "2fr 80px 160px 100px 80px 100px", color: TEXT_SECONDARY, borderColor: BORDER, backgroundColor: `${NAVY}08` }}>
            <span>Name</span><span>Level</span><span>Term progress</span><span>Sessions</span><span>Last active</span><span />
          </div>
          {filtered.length === 0
            ? <EmptyState icon={Users} title="No students found" subtitle="Try adjusting your search." />
            : filtered.map((s, i) => (
              <div key={s.id} onClick={() => push({ type: "studentDetail", studentId: s.id })}
                className="grid items-center px-4 py-3 border-b last:border-0 hover:bg-gray-50 transition-colors cursor-pointer"
                style={{ gridTemplateColumns: "2fr 80px 160px 100px 80px 100px", borderColor: BORDER, backgroundColor: i % 2 === 0 ? "#fff" : `${SURFACE}88` }}>
                <div className="flex items-center gap-2.5"><Avatar initials={s.initials} size={34} /><span className="font-semibold text-sm" style={{ color: TEXT_PRIMARY }}>{s.name}</span></div>
                <div><HskBadge level={s.hsk} /></div>
                <div className="flex items-center gap-2">
                  <div className="h-1.5 rounded-full flex-1 overflow-hidden" style={{ backgroundColor: BORDER }}>
                    <div className="h-full rounded-full" style={{ width: `${(s.lessons / s.total) * 100}%`, backgroundColor: TEAL }} />
                  </div>
                  <span className="text-xs" style={{ color: TEXT_SECONDARY }}>{s.lessons}/{s.total}</span>
                </div>
                <div><span className="text-xs font-semibold px-2 py-1 rounded-full" style={{ backgroundColor: `${TEAL}18`, color: TEAL }}>{s.sessions} left</span></div>
                <span className="text-xs" style={{ color: TEXT_SECONDARY }}>{s.lastSeen}</span>
                <div className="flex justify-end"><TealLink>View →</TealLink></div>
              </div>
            ))}
        </Card>
      </div>
    </div>
  );
}

function TeacherExercises({ push, fullCrud = false }: { push: (s: Screen) => void; fullCrud?: boolean }) {
  const [filter, setFilter] = useState<"all" | "published" | "draft">("all");
  const [assignId, setAssignId] = useState<number | null>(null);
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const filtered = exercises.filter(e => filter === "all" || e.status === filter);
  return (
    <div className="p-8 overflow-y-auto flex-1">
      {assignId !== null && <AssignDialog exerciseId={assignId} onClose={() => setAssignId(null)} />}
      {deleteId !== null && <DeleteExerciseDialog exerciseId={deleteId} onClose={() => setDeleteId(null)} />}
      <div className="max-w-3xl space-y-4">
        {!fullCrud && (
          <div className="flex items-center gap-2 p-3 rounded-xl" style={{ backgroundColor: `${TEAL}0D`, border: `1px solid ${TEAL}30` }}>
            <Info size={14} style={{ color: TEAL }} className="flex-shrink-0" />
            <span className="text-xs" style={{ color: TEXT_SECONDARY }}>Guru can assign exercises to students. Exercise creation and editing is managed by Admin.</span>
          </div>
        )}
        <div className="flex items-center gap-2">
          {(["all", "published", "draft"] as const).map(f => (
            <button key={f} onClick={() => setFilter(f)}
              className="px-4 py-1.5 rounded-full text-sm font-semibold capitalize transition-all"
              style={{ backgroundColor: filter === f ? NAVY : "#fff", color: filter === f ? "#fff" : TEXT_SECONDARY, border: `1px solid ${filter === f ? NAVY : BORDER}` }}>
              {f}
            </button>
          ))}
          <div className="flex-1" />
          {fullCrud && <NavyBtn onClick={() => push({ type: "exerciseForm" })}><div className="flex items-center gap-1.5"><Plus size={13} />New exercise</div></NavyBtn>}
        </div>
        {filtered.length === 0
          ? <Card><EmptyState icon={BookOpen} title="No exercises yet" subtitle={fullCrud ? "Tap New exercise to create practice, then assign it to students." : "Admin has not published any exercises yet."} /></Card>
          : <div className="space-y-3">
            {filtered.map(ex => (
              <Card key={ex.id} className="group">
                <div className="flex items-start justify-between mb-2">
                  <div className="flex-1 min-w-0 pr-3">
                    <div className="font-semibold text-sm mb-1" style={{ color: TEXT_PRIMARY }}>{ex.title}</div>
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-xs" style={{ color: TEXT_SECONDARY }}>{ex.type} · {ex.questions} questions</span>
                      <HskBadge level={ex.hsk} />
                    </div>
                  </div>
                  <div className="flex items-center gap-2 flex-shrink-0">
                    <StatusPill status={ex.status} />
                    {fullCrud && <button onClick={() => setDeleteId(ex.id)} className="p-1 rounded hover:bg-gray-100 opacity-0 group-hover:opacity-100"><MoreVertical size={15} style={{ color: TEXT_SECONDARY }} /></button>}
                  </div>
                </div>
                <div className="flex items-center justify-between pt-2 border-t" style={{ borderColor: BORDER }}>
                  <span className="text-xs" style={{ color: TEXT_SECONDARY }}>
                    {ex.assigned > 0 ? `Assigned to ${ex.assigned} students` : "Not assigned yet"}{ex.due ? ` · Due ${ex.due}` : ""}
                  </span>
                  <div className="flex items-center gap-2">
                    <TealLink onClick={() => setAssignId(ex.id)}>Assign</TealLink>
                    {fullCrud && <>
                      <span style={{ color: BORDER }}>·</span>
                      <TealLink onClick={() => push({ type: "exerciseForm", exerciseId: ex.id })}>Edit</TealLink>
                    </>}
                  </div>
                </div>
              </Card>
            ))}
          </div>}
      </div>
    </div>
  );
}

function TeacherClasses({ push, crossTeacher = false }: { push: (s: Screen) => void; crossTeacher?: boolean }) {
  const [showPast, setShowPast] = useState(false);
  const upcoming = classes.filter(c => c.status === "upcoming");
  const past     = classes.filter(c => c.status === "concluded");
  return (
    <div className="p-8 overflow-y-auto flex-1">
      <div className="max-w-2xl space-y-6">
        <div className="flex justify-end">
          <NavyBtn onClick={() => push({ type: "classForm" })}><div className="flex items-center gap-1.5"><Plus size={13} />New class</div></NavyBtn>
        </div>
        <div>
          <SectionHeader title="Upcoming" />
          {upcoming.length === 0
            ? <Card><EmptyState icon={Calendar} title="No active classes" subtitle="Tap New class to create a session students can join." /></Card>
            : <div className="space-y-3">
              {upcoming.map(cls => (
                <Card key={cls.id}>
                  <div className="flex items-start gap-3">
                    <div className="px-2.5 py-1.5 rounded-lg text-white text-xs font-bold flex-shrink-0 text-center leading-tight" style={{ backgroundColor: TEAL }}>
                      {cls.date.split(" ").map((l, i) => <div key={i}>{l}</div>)}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between mb-1">
                        <span className="font-semibold text-sm" style={{ color: TEXT_PRIMARY }}>{cls.title}</span>
                        <StatusPill status={cls.status} />
                      </div>
                      <div className="flex items-center gap-3 text-xs" style={{ color: TEXT_SECONDARY }}>
                        <span>{cls.time} · {cls.duration} min</span>
                        <span className="flex items-center gap-1"><Users size={11} />{cls.students} joined</span>
                      </div>
                      {cls.link && <div className="mt-1"><TealLink><span className="flex items-center gap-1"><Video size={11} />Join on Zoom</span></TealLink></div>}
                    </div>
                  </div>
                  <div className="flex items-center gap-3 pt-3 mt-3 border-t" style={{ borderColor: BORDER }}>
                    <TealLink onClick={() => push({ type: "classDetail", classId: cls.id })}>View detail</TealLink>
                    <TealLink onClick={() => push({ type: "classForm", classId: cls.id })}>Edit</TealLink>
                    <button className="ml-auto p-1 rounded hover:bg-red-50"><Trash2 size={14} style={{ color: ERROR }} /></button>
                  </div>
                </Card>
              ))}
            </div>}
        </div>
        <div>
          <div className="flex items-center gap-2 mb-3 cursor-pointer" onClick={() => setShowPast(v => !v)}>
            <h3 className="font-bold" style={{ color: NAVY, fontSize: 15 }}>Past classes</h3>
            <span className="text-xs px-2 py-0.5 rounded-full" style={{ backgroundColor: SURFACE, color: TEXT_SECONDARY }}>{past.length}</span>
            <ChevronRight size={14} style={{ color: TEXT_SECONDARY, transform: showPast ? "rotate(90deg)" : undefined, transition: "transform 0.2s" }} />
          </div>
          {showPast && <div className="space-y-3">
            {past.map(cls => (
              <Card key={cls.id} className="opacity-70" onClick={() => push({ type: "classDetail", classId: cls.id })}>
                <div className="flex items-center justify-between">
                  <div>
                    <div className="font-semibold text-sm mb-0.5" style={{ color: TEXT_SECONDARY }}>{cls.title}</div>
                    <div className="text-xs" style={{ color: TEXT_SECONDARY }}>{cls.date} · {cls.time}</div>
                  </div>
                  <StatusPill status="concluded" />
                </div>
              </Card>
            ))}
          </div>}
        </div>
      </div>
    </div>
  );
}

function TeacherProfile({ onSignOut, push, onHandoff, roleLabel = "Guru" }: { onSignOut: () => void; push?: (s: Screen) => void; onHandoff?: () => void; roleLabel?: string }) {
  const [showStates, setShowStates] = useState(false);
  if (showStates) return <StatesReferencePage onBack={() => setShowStates(false)} />;
  const isAdmin = roleLabel === "Admin";
  const name = isAdmin ? "Admin Chen" : "Teacher Ng";
  const email = isAdmin ? "admin.chen@easystudy.com" : "teacher.ng@easystudy.com";
  const initials = isAdmin ? "AC" : "TN";
  const accent = isAdmin ? "#7A4FBF" : NAVY;
  return (
    <div className="p-8 overflow-y-auto flex-1">
      <div className="max-w-lg space-y-4">
        <Card><div className="flex items-center gap-4">
          <Avatar initials={initials} size={64} color={accent} />
          <div>
            <div className="font-bold text-lg" style={{ color: NAVY }}>{name}</div>
            <span className="inline-block text-xs px-2 py-0.5 rounded font-semibold text-white mt-1" style={{ backgroundColor: accent }}>{roleLabel}</span>
            <div className="text-xs mt-1" style={{ color: TEXT_SECONDARY }}>{email}</div>
          </div>
        </div></Card>
        {!isAdmin && (
          <Card>
            <div className="text-xs mb-1" style={{ color: TEXT_SECONDARY }}>Your invite code</div>
            <div className="flex items-center justify-between">
              <div className="font-bold text-3xl tracking-wider" style={{ color: NAVY, fontFamily: "monospace" }}>ABC123</div>
              <button className="flex items-center gap-1.5 text-sm font-semibold px-3 py-1.5 rounded-lg hover:bg-teal-50" style={{ color: TEAL }}>
                <Copy size={14} />Copy code
              </button>
            </div>
            <p className="text-xs mt-1" style={{ color: TEXT_SECONDARY }}>Share this code with murid when they register</p>
          </Card>
        )}
        <Card className="!p-0 overflow-hidden">
          {[{ icon: User, label: "Edit profile" }, { icon: Bell, label: "Notifications" }, { icon: FileText, label: "Help & support" }].map(({ icon: Icon, label }) => (
            <button key={label} className="w-full flex items-center justify-between px-4 py-3.5 hover:bg-gray-50 border-b last:border-0" style={{ borderColor: BORDER }}>
              <div className="flex items-center gap-3"><Icon size={16} style={{ color: TEXT_SECONDARY }} /><span className="text-sm font-medium" style={{ color: TEXT_PRIMARY }}>{label}</span></div>
              <ChevronRight size={16} style={{ color: TEXT_SECONDARY }} />
            </button>
          ))}
        </Card>
        <button onClick={() => setShowStates(true)}
          className="w-full flex items-center justify-between px-4 py-3 rounded-xl border text-sm font-medium hover:bg-gray-50"
          style={{ borderColor: BORDER, color: TEXT_SECONDARY }}>
          <span>🧪 UI States reference</span>
          <ChevronRight size={16} />
        </button>
        <button onClick={onHandoff}
          className="w-full flex items-center justify-between px-4 py-3 rounded-xl border text-sm font-semibold hover:bg-gray-50"
          style={{ borderColor: TEAL, color: TEAL }}>
          <span>📐 Design handoff</span>
          <ChevronRight size={16} />
        </button>
        <button onClick={onSignOut} className="w-full py-3 text-sm font-semibold rounded-xl border-2 hover:bg-red-50" style={{ color: ERROR, borderColor: `${ERROR}30` }}>Sign out</button>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════
   TEACHER PUSHED SCREENS
═══════════════════════════════════════════ */

function StudentDetailScreen({ studentId, onBack }: { studentId: number; onBack: () => void }) {
  const s = students.find(x => x.id === studentId)!;
  const [addTermOpen, setAddTermOpen] = useState(false);
  const lessonDots = Array.from({ length: 8 }, (_, i) => ({
    num: i + 1,
    status: i < s.lessons ? "done" : i === s.lessons ? "progress" : "not_started",
  }));
  return (
    <div className="flex flex-col flex-1 overflow-hidden">
      {addTermOpen && <AddClassTermDialog onClose={() => setAddTermOpen(false)} />}
      <PushedBar title="Student profile" onBack={onBack} right={<TealLink>Export PDF</TealLink>} />
      <div className="p-8 overflow-y-auto flex-1">
        <div className="max-w-2xl space-y-5">
          <Card><div className="flex items-center gap-4">
            <Avatar initials={s.initials} size={64} />
            <div>
              <div className="font-bold text-xl" style={{ color: NAVY }}>{s.name}</div>
              <div className="flex items-center gap-2 mt-1"><HskBadge level={s.hsk} /></div>
              <div className="text-xs mt-1" style={{ color: TEXT_SECONDARY }}>Term 1 · {s.lessons} of {s.total} lessons completed</div>
              <div className="text-xs" style={{ color: TEXT_SECONDARY }}>Joined {s.joined}</div>
            </div>
          </div></Card>

          <Card>
            <SectionHeader title="Class term" action={<TealLink onClick={() => setAddTermOpen(true)}>Add term</TealLink>} />
            <div className="flex items-center gap-2 mb-2">
              <span className="font-bold text-sm px-2.5 py-1 rounded text-white" style={{ backgroundColor: NAVY }}>16 sessions</span>
              <span className="text-sm font-semibold" style={{ color: TEXT_PRIMARY }}>{s.sessions} remaining</span>
            </div>
            <div className="text-xs mb-2" style={{ color: TEXT_SECONDARY }}>Nov 1 – Dec 31, 2024</div>
            <div className="h-2 rounded-full overflow-hidden" style={{ backgroundColor: BORDER }}>
              <div className="h-full rounded-full" style={{ width: `${((16 - s.sessions) / 16) * 100}%`, backgroundColor: TEAL }} />
            </div>
          </Card>

          <Card>
            <SectionHeader title="Lesson progress" />
            <div className="grid grid-cols-4 gap-2">
              {lessonDots.map(l => (
                <div key={l.num} className="h-10 rounded-lg flex items-center justify-center font-bold text-sm"
                  style={{ backgroundColor: l.status === "done" ? NAVY : l.status === "progress" ? `${TEAL}20` : SURFACE, color: l.status === "done" ? "#fff" : l.status === "progress" ? TEAL : TEXT_SECONDARY, border: l.status === "progress" ? `2px solid ${TEAL}` : `1px solid ${BORDER}` }}>
                  {l.status === "done" ? <Check size={14} /> : l.num}
                </div>
              ))}
            </div>
          </Card>

          <Card>
            <SectionHeader title="Practice results" />
            <div className="space-y-3">
              {[{ title: "HSK 2 Grammar — Unit 3", score: s.score, overdue: s.id === 1 }, { title: "Reading Comprehension", score: null, overdue: false }].map(r => (
                <div key={r.title} className="flex items-center justify-between py-2 border-b last:border-0" style={{ borderColor: BORDER }}>
                  <div>
                    <div className="text-sm font-medium" style={{ color: TEXT_PRIMARY }}>{r.title}</div>
                    {r.overdue && <div className="text-xs font-semibold" style={{ color: ERROR }}>3 days overdue</div>}
                  </div>
                  {r.score != null
                    ? <span className="font-bold text-sm px-2.5 py-1 rounded-lg" style={{ backgroundColor: r.score >= 70 ? `${SUCCESS}18` : `${ERROR}18`, color: r.score >= 70 ? SUCCESS : ERROR }}>{r.score}%</span>
                    : <span className="text-xs" style={{ color: TEXT_SECONDARY }}>Not started</span>}
                </div>
              ))}
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}

function ExerciseFormScreen({ exerciseId, onBack, push }: { exerciseId?: number; onBack: () => void; push: (s: Screen) => void }) {
  const ex = exerciseId ? exercises.find(e => e.id === exerciseId) : null;
  const [exType, setExType] = useState(ex?.type ?? "Multiple choice");
  const [title, setTitle] = useState(ex?.title ?? "");
  const [importing, setImporting] = useState(false);
  const [importDone, setImportDone] = useState(false);
  const [snack, setSnack] = useState<string | null>(null);

  const [answerMode, setAnswerMode] = useState<"MC" | "Typing">("MC");
  const [manualReview, setManualReview] = useState(true);

  const typeDesc: Record<string, string> = {
    "Multiple choice":   "Students pick one answer from A–D options",
    "Compose sentences": "Students arrange word segments into a sentence (组词成句)",
    "Matching":          "Students match prompts to answers (对话配对)",
    "Listening":         "Students listen to audio, then answer (听力)",
    "Reading cloze":     "Students fill blanks from a word bank (选词填空)",
    "Picture + keyword": "Students write a sentence using a keyword and image",
  };

  const handleType = (t: string) => {
    if (t === "Reading cloze" || t === "Picture + keyword")
      setSnack(`${t} is recognized on import but not editable yet. Use Compose sentences or Matching for now.`);
    setExType(t);
  };

  const comingSoon = exType === "Reading cloze" || exType === "Picture + keyword";
  const isListening = exType === "Listening";

  return (
    <div className="flex flex-col flex-1 overflow-hidden">
      {snack && <Snackbar message={snack} onClose={() => setSnack(null)} />}
      {importing && <WorksheetImportDialog onClose={() => { setImporting(false); setImportDone(true); push({ type: "importReview", exerciseId }); }} />}
      <PushedBar title={exerciseId ? "Edit exercise" : "New exercise"} onBack={onBack}
        right={<div className="flex gap-2"><OutlineBtn>Save draft</OutlineBtn><NavyBtn>Publish</NavyBtn></div>} />
      <div className="p-8 overflow-y-auto flex-1">
        <div className="max-w-3xl grid grid-cols-3 gap-6">
          <div className="col-span-2 space-y-4">
            <Card>
              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold mb-1" style={{ color: TEXT_PRIMARY }}>Exercise type</label>
                  <select value={exType} onChange={e => handleType(e.target.value)}
                    className="w-full px-3 py-2.5 rounded-lg border bg-white text-sm outline-none" style={{ borderColor: BORDER }}>
                    {Object.keys(typeDesc).map(t => <option key={t}>{t}</option>)}
                  </select>
                  <p className="text-xs mt-1" style={{ color: TEXT_SECONDARY }}>{typeDesc[exType]}</p>
                </div>
                <InputField label="Title" placeholder="e.g. HSK 2 Grammar — Unit 3" value={title} onChange={setTitle} />
                <div>
                  <label className="block text-xs font-semibold mb-1" style={{ color: TEXT_PRIMARY }}>HSK level</label>
                  <div className="flex items-center gap-2">
                    <select className="flex-1 px-3 py-2.5 rounded-lg border bg-white text-sm outline-none" style={{ borderColor: BORDER }}>
                      {[1,2,3,4,5,6].map(l => <option key={l}>HSK {l}</option>)}
                    </select>
                    <HskBadge level={2} />
                  </div>
                </div>
                <div>
                  <label className="block text-xs font-semibold mb-1" style={{ color: TEXT_PRIMARY }}>Instructions (optional)</label>
                  <textarea rows={3} placeholder="e.g. Circle the correct answer"
                    className="w-full px-3 py-2.5 rounded-lg border bg-white text-sm outline-none resize-none" style={{ borderColor: BORDER }} />
                </div>
              </div>
            </Card>

            {isListening && (
              <Card>
                <SectionHeader title="Audio" />
                <div className="space-y-3">
                  <div className="flex items-center gap-3 p-4 rounded-xl border-2 border-dashed" style={{ borderColor: TEAL }}>
                    <div className="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0" style={{ backgroundColor: `${TEAL}18` }}>
                      <Headphones size={18} style={{ color: TEAL }} />
                    </div>
                    <div className="flex-1">
                      <div className="text-sm font-semibold" style={{ color: TEXT_PRIMARY }}>HSK3_directions.mp3</div>
                      <div className="text-xs" style={{ color: TEXT_SECONDARY }}>Upload mp3 / m4a · 0:42</div>
                    </div>
                    <OutlineBtn>Replace</OutlineBtn>
                  </div>
                  {/* Waveform preview */}
                  <div className="flex items-center gap-0.5 h-12 px-2 rounded-lg" style={{ backgroundColor: SURFACE }}>
                    {Array.from({ length: 48 }).map((_, i) => (
                      <div key={i} className="flex-1 rounded-full" style={{ height: `${20 + Math.abs(Math.sin(i * 0.7)) * 70}%`, backgroundColor: i < 16 ? TEAL : `${TEAL}55` }} />
                    ))}
                  </div>
                  <div>
                    <label className="block text-xs font-semibold mb-1" style={{ color: TEXT_PRIMARY }}>Answer mode</label>
                    <div className="flex gap-2">
                      {(["MC", "Typing"] as const).map(m => (
                        <button key={m} onClick={() => setAnswerMode(m)}
                          className="flex-1 py-2 rounded-lg border-2 text-sm font-semibold transition-all"
                          style={{ backgroundColor: answerMode === m ? TEAL : "#fff", color: answerMode === m ? "#fff" : TEXT_SECONDARY, borderColor: answerMode === m ? TEAL : BORDER }}>
                          {m === "MC" ? "Multiple choice" : "Typing"}
                        </button>
                      ))}
                    </div>
                  </div>
                  {answerMode === "Typing" && (
                    <label className="flex items-center justify-between cursor-pointer p-2.5 rounded-lg" style={{ backgroundColor: SURFACE }}>
                      <span className="text-sm" style={{ color: TEXT_PRIMARY }}>Manual-review fallback for typed answers</span>
                      <div onClick={() => setManualReview(v => !v)} className="w-10 h-5 rounded-full relative transition-colors" style={{ backgroundColor: manualReview ? TEAL : BORDER }}>
                        <div className="w-4 h-4 bg-white rounded-full absolute top-0.5 shadow transition-all" style={{ left: manualReview ? 22 : 2 }} />
                      </div>
                    </label>
                  )}
                  <InputField label="Prompt text" placeholder="e.g. 根据录音，选择正确的方向 (Listen and pick the correct direction)" />
                </div>
              </Card>
            )}

            {comingSoon
              ? <Card className="border-2" style={{ borderColor: `${ERROR}40`, backgroundColor: `${ERROR}05` }}>
                <div className="flex items-start gap-3">
                  <Construction size={20} style={{ color: ERROR }} className="flex-shrink-0 mt-0.5" />
                  <div>
                    <div className="font-semibold text-sm mb-1" style={{ color: ERROR }}>Editor coming soon</div>
                    <div className="text-xs" style={{ color: TEXT_SECONDARY }}>This type is detected on worksheet import but cannot be manually edited yet.</div>
                  </div>
                </div>
              </Card>
              : isListening
              ? null
              : <Card>
                <SectionHeader title="Questions" action={<span className="text-xs px-2 py-0.5 rounded-full font-bold text-white" style={{ backgroundColor: TEAL }}>2</span>} />
                <div className="space-y-4">
                  {exType === "Multiple choice" && mcQuestions.slice(0, 2).map((q, qi) => (
                    <div key={qi} className="p-3 rounded-lg border space-y-2" style={{ borderColor: BORDER }}>
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-bold px-1.5 py-0.5 rounded text-white" style={{ backgroundColor: NAVY }}>Q{qi+1}</span>
                        <input defaultValue={q.q} className="flex-1 text-sm outline-none bg-transparent" style={{ fontFamily: "'Noto Sans SC', sans-serif" }} />
                        <button><Trash2 size={13} style={{ color: TEXT_SECONDARY }} /></button>
                      </div>
                      {["A","B","C","D"].map((lt, oi) => (
                        <div key={lt} className="flex items-center gap-2">
                          <span className="w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold text-white flex-shrink-0"
                            style={{ backgroundColor: oi === q.answer ? TEAL : TEXT_SECONDARY }}>{lt}</span>
                          <input defaultValue={q.options[oi]} className="flex-1 text-sm outline-none bg-transparent" style={{ fontFamily: "'Noto Sans SC', sans-serif" }} />
                          <input type="radio" name={`correct-${qi}`} defaultChecked={oi === q.answer} style={{ accentColor: TEAL }} />
                        </div>
                      ))}
                    </div>
                  ))}
                  {exType === "Compose sentences" && (
                    <div className="p-3 rounded-lg border space-y-2" style={{ borderColor: BORDER }}>
                      <div className="flex items-center gap-2 mb-2">
                        <span className="text-xs font-bold px-1.5 py-0.5 rounded text-white" style={{ backgroundColor: NAVY }}>Q1</span>
                        <span className="text-xs" style={{ color: TEXT_SECONDARY }}>Arrange segments into a correct sentence</span>
                      </div>
                      <div className="flex flex-wrap gap-2">
                        {["南方的", "夏天", "热极了"].map(seg => (
                          <span key={seg} className="px-3 py-1.5 rounded-lg border-2 text-sm font-bold"
                            style={{ borderColor: TEAL, color: TEXT_PRIMARY, fontFamily: "'Noto Sans SC', sans-serif" }}>{seg}</span>
                        ))}
                        <button className="px-3 py-1.5 rounded-lg text-xs" style={{ border: `1px dashed ${BORDER}`, color: TEXT_SECONDARY }}>+ Segment</button>
                      </div>
                    </div>
                  )}
                  {exType === "Matching" && (
                    <div className="p-3 rounded-lg border" style={{ borderColor: BORDER }}>
                      <div className="grid grid-cols-2 gap-3">
                        <div>
                          <div className="text-xs font-semibold mb-2" style={{ color: TEXT_SECONDARY }}>Prompts</div>
                          {["你叫什么名字？", "你好吗？"].map((p, i) => (
                            <div key={i} className="flex items-center gap-2 mb-2">
                              <span className="w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold text-white" style={{ backgroundColor: NAVY }}>{i+1}</span>
                              <input defaultValue={p} className="flex-1 text-xs border rounded px-2 py-1 outline-none" style={{ borderColor: BORDER, fontFamily: "'Noto Sans SC', sans-serif" }} />
                            </div>
                          ))}
                        </div>
                        <div>
                          <div className="text-xs font-semibold mb-2" style={{ color: TEXT_SECONDARY }}>Answers</div>
                          {["我叫李明。", "我很好，谢谢。"].map((a, i) => (
                            <div key={i} className="flex items-center gap-2 mb-2">
                              <span className="w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold text-white" style={{ backgroundColor: TEAL }}>{String.fromCharCode(65+i)}</span>
                              <input defaultValue={a} className="flex-1 text-xs border rounded px-2 py-1 outline-none" style={{ borderColor: BORDER, fontFamily: "'Noto Sans SC', sans-serif" }} />
                            </div>
                          ))}
                        </div>
                      </div>
                    </div>
                  )}
                  <button className="flex items-center gap-1.5 text-sm font-semibold" style={{ color: TEAL }}><Plus size={14} />Add question</button>
                </div>
              </Card>}
          </div>

          <div className="space-y-4">
            <Card className="border-2" style={{ borderColor: `${TEAL}30`, backgroundColor: `${TEAL}05` }}>
              <div className="flex items-center gap-2 mb-2"><Upload size={16} style={{ color: TEAL }} /><span className="font-semibold text-sm" style={{ color: TEAL }}>Import from worksheet</span></div>
              <p className="text-xs mb-3" style={{ color: TEXT_SECONDARY }}>Upload a PDF, Word doc, or image. Questions are read on your device.</p>
              {importDone
                ? <div className="flex items-center gap-2 text-xs font-semibold" style={{ color: SUCCESS }}><CheckCircle size={14} />3 questions imported</div>
                : <OutlineBtn onClick={() => setImporting(true)}>Choose file</OutlineBtn>}
              <div className="flex gap-1 mt-2 flex-wrap">
                {["PDF","DOCX","JPG","PNG"].map(f => <span key={f} className="text-xs px-1.5 py-0.5 rounded" style={{ backgroundColor: SURFACE, color: TEXT_SECONDARY }}>{f}</span>)}
              </div>
            </Card>
            <Card>
              <div className="text-xs font-semibold mb-1" style={{ color: TEXT_SECONDARY }}>Assign to students</div>
              <div className="text-sm font-bold mb-1" style={{ color: NAVY }}>3 students selected</div>
              <TealLink>Manage →</TealLink>
            </Card>
            <Card>
              <div className="text-xs font-semibold mb-2" style={{ color: TEXT_SECONDARY }}>Due date</div>
              <input type="date" defaultValue="2024-12-20" className="w-full px-3 py-2 rounded-lg border text-sm outline-none" style={{ borderColor: BORDER }} />
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
}

function ClassFormScreen({ classId, onBack }: { classId?: number; onBack: () => void }) {
  const cls = classId ? classes.find(c => c.id === classId) : null;
  const [duration, setDuration] = useState("60 min");
  return (
    <div className="flex flex-col flex-1 overflow-hidden">
      <PushedBar title={classId ? "Edit class" : "New class"} onBack={onBack} />
      <div className="p-8 overflow-y-auto flex-1">
        <div className="max-w-lg space-y-4">
          <Card>
            <div className="space-y-4">
              <InputField label="Class title" placeholder="e.g. HSK 2 — Speaking Practice" value={cls?.title} />
              <div className="grid grid-cols-2 gap-3">
                <InputField label="Date" type="date" value="2024-12-23" />
                <InputField label="Start time" type="time" value="10:00" />
              </div>
              <div>
                <label className="block text-xs font-semibold mb-1" style={{ color: TEXT_PRIMARY }}>Duration</label>
                <div className="flex gap-2">
                  {["45 min","60 min","90 min","Custom"].map(d => (
                    <button key={d} onClick={() => setDuration(d)}
                      className="flex-1 py-2 rounded-lg text-xs font-semibold border transition-all"
                      style={{ backgroundColor: duration === d ? NAVY : "#fff", color: duration === d ? "#fff" : TEXT_SECONDARY, borderColor: duration === d ? NAVY : BORDER }}>
                      {d}
                    </button>
                  ))}
                </div>
              </div>
              <div>
                <label className="block text-xs font-semibold mb-1" style={{ color: TEXT_PRIMARY }}>Video call link (optional)</label>
                <div className="relative">
                  <Video size={14} className="absolute left-3 top-1/2 -translate-y-1/2" style={{ color: TEXT_SECONDARY }} />
                  <input type="url" placeholder="Zoom / Meet URL" className="w-full pl-9 pr-3 py-2.5 rounded-lg border bg-white text-sm outline-none" style={{ borderColor: BORDER }} />
                </div>
              </div>
            </div>
          </Card>
          <Card>
            <div className="flex items-center justify-between mb-3">
              <span className="font-bold text-sm" style={{ color: NAVY }}>Students</span>
              <TealLink>Add students</TealLink>
            </div>
            <div className="flex flex-wrap gap-2">
              {["Wang Fang","Li Ming","Ahmad Hassan"].map(name => (
                <span key={name} className="flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border" style={{ borderColor: BORDER, color: TEXT_PRIMARY }}>
                  <div className="w-4 h-4 rounded-full flex items-center justify-center text-white" style={{ backgroundColor: NAVY, fontSize: 8 }}>{name[0]}</div>
                  {name}<button><X size={10} style={{ color: TEXT_SECONDARY }} /></button>
                </span>
              ))}
            </div>
          </Card>
          <NavyBtn full>Save class</NavyBtn>
        </div>
      </div>
    </div>
  );
}

function ClassDetailScreen({ classId, onBack, canAttendance = false }: { classId: number; onBack: () => void; canAttendance?: boolean }) {
  const cls = classes.find(c => c.id === classId)!;
  const [concluded, setConcluded] = useState(cls.status === "concluded");
  const [showConfirm, setShowConfirm] = useState(false);
  const roster = students.slice(0, cls.students);
  const [attendance, setAttendance] = useState<Record<number, "present" | "absent" | null>>(
    Object.fromEntries(roster.map(s => [s.id, null]))
  );
  return (
    <div className="flex flex-col flex-1 overflow-hidden">
      {showConfirm && (
        <Modal onClose={() => setShowConfirm(false)}>
          <div className="text-center">
            <div className="font-bold text-base mb-2" style={{ color: TEXT_PRIMARY }}>Conclude this class?</div>
            <p className="text-sm mb-1" style={{ color: TEXT_SECONDARY }}>This will credit attendance and deduct one session from each student&apos;s term.</p>
            <p className="text-xs mb-4" style={{ color: TEXT_SECONDARY }}>Wang Fang, Li Ming, Ahmad Hassan (+1 more)</p>
            <div className="flex gap-3 justify-center">
              <OutlineBtn onClick={() => setShowConfirm(false)}>Cancel</OutlineBtn>
              <NavyBtn onClick={() => { setConcluded(true); setShowConfirm(false); }}>Conclude</NavyBtn>
            </div>
          </div>
        </Modal>
      )}
      <PushedBar title={cls.title} onBack={onBack} right={<button className="p-1.5 rounded hover:bg-gray-100"><Edit size={15} style={{ color: TEXT_SECONDARY }} /></button>} />
      <div className="p-8 overflow-y-auto flex-1">
        <div className="max-w-lg space-y-4">
          <Card>
            <div className="font-bold text-lg mb-2" style={{ color: TEXT_PRIMARY }}>{cls.title}</div>
            <div className="text-sm flex items-center gap-1.5" style={{ color: TEXT_SECONDARY }}><Calendar size={14} />{cls.date} · {cls.time}</div>
            <div className="mt-2"><StatusPill status={concluded ? "concluded" : cls.status} /></div>
          </Card>
          {cls.link && <Card>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2" style={{ color: TEAL }}><Video size={16} /><span className="font-semibold text-sm">Join on Zoom</span></div>
              <button><Copy size={14} style={{ color: TEXT_SECONDARY }} /></button>
            </div>
          </Card>}
          <Card>
            <div className="flex items-center justify-between mb-3">
              <span className="font-bold text-sm" style={{ color: NAVY }}>{canAttendance ? "Attendance" : "Students"} ({cls.students})</span>
              <TealLink>Add students</TealLink>
            </div>
            <div className="space-y-2">
              {roster.map(s => (
                <div key={s.id} className="flex items-center gap-2">
                  <Avatar initials={s.initials} size={32} />
                  <span className="text-sm font-medium flex-1" style={{ color: TEXT_PRIMARY }}>{s.name}</span>
                  {canAttendance && !concluded ? (
                    <div className="flex gap-1">
                      {(["present", "absent"] as const).map(st => {
                        const active = attendance[s.id] === st;
                        const c = st === "present" ? SUCCESS : ERROR;
                        return (
                          <button key={st} onClick={() => setAttendance(a => ({ ...a, [s.id]: st }))}
                            className="text-xs font-semibold px-2.5 py-1 rounded-full capitalize transition-all"
                            style={{ backgroundColor: active ? c : "#fff", color: active ? "#fff" : c, border: `1px solid ${c}` }}>
                            {st}
                          </button>
                        );
                      })}
                    </div>
                  ) : canAttendance && concluded ? (
                    <span className="text-xs font-semibold px-2 py-0.5 rounded-full" style={{ backgroundColor: `${SUCCESS}18`, color: SUCCESS }}>
                      {attendance[s.id] === "absent" ? "Absent" : "Present"}
                    </span>
                  ) : (
                    <HskBadge level={s.hsk} />
                  )}
                </div>
              ))}
            </div>
            {canAttendance && !concluded && (
              <p className="text-xs mt-3 pt-3 border-t" style={{ color: TEXT_SECONDARY, borderColor: BORDER }}>
                Mark each student present or absent, then conclude the class to credit attendance.
              </p>
            )}
          </Card>
          {concluded
            ? <Card><div className="flex items-center justify-center gap-3">
              <CheckCircle size={24} style={{ color: SUCCESS }} />
              <div><div className="font-semibold" style={{ color: SUCCESS }}>Class concluded</div><div className="text-xs" style={{ color: TEXT_SECONDARY }}>Attendance credited to {cls.students} students</div></div>
            </div></Card>
            : <div className="space-y-3">
              <NavyBtn full onClick={() => setShowConfirm(true)}>Conclude class</NavyBtn>
              <p className="text-xs text-center" style={{ color: TEXT_SECONDARY }}>Conclude to credit attendance and deduct one session from each student&apos;s term.</p>
              <button className="w-full text-sm font-semibold py-2" style={{ color: ERROR }}>Delete class</button>
            </div>}
        </div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════
   STUDENT TAB SCREENS
═══════════════════════════════════════════ */

function StudentHome({ push }: { push: (s: Screen) => void }) {
  const [joinOpen, setJoinOpen] = useState(false);
  return (
    <div className="p-8 overflow-y-auto flex-1">
      {joinOpen && <JoinClassDialog onClose={() => setJoinOpen(false)} />}
      <div className="max-w-5xl space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="font-bold text-2xl flex items-center gap-2" style={{ color: NAVY }}>Good morning, Li Ming <span>👋</span></h2>
            <div className="flex items-center gap-2 mt-1"><HskBadge level={3} /><span className="text-sm" style={{ color: TEXT_SECONDARY }}>Term 1 · 5/8 lessons completed</span></div>
          </div>
          <TealBtn onClick={() => setJoinOpen(true)}>+ Join class</TealBtn>
        </div>
        <div className="grid grid-cols-3 gap-6">
          <div className="col-span-2 space-y-4">
            <div className="flex items-center justify-between p-4 rounded-xl"
              style={{ backgroundColor: `${TEAL}10`, border: `1px solid ${TEAL}30`, borderLeft: `4px solid ${TEAL}` }}>
              <div className="flex items-center gap-3">
                <div className="w-2 h-2 rounded-full animate-pulse" style={{ backgroundColor: TEAL }} />
                <div>
                  <div className="font-semibold text-sm" style={{ color: TEAL }}>Class in progress</div>
                  <div className="font-bold text-base" style={{ color: TEXT_PRIMARY }}>HSK 3 — Speaking Practice</div>
                  <div className="text-xs" style={{ color: TEXT_SECONDARY }}>Started 5 min ago</div>
                </div>
              </div>
              <TealBtn>Join class</TealBtn>
            </div>
            <div>
              <SectionHeader title="Your practice" action={<TealLink>See all</TealLink>} />
              <div className="space-y-3">
                {[{ id: 1, title: "HSK 2 Grammar", type: "Multiple choice · 5 questions", due: "Due tomorrow", dueErr: true, progress: 0, btn: "Start", btnColor: TEAL },
                  { id: 2, title: "Reading Practice", type: "Compose sentences · 3 questions", due: "No due date", dueErr: false, progress: 60, btn: "Continue", btnColor: NAVY }]
                  .map(ex => (
                  <Card key={ex.id} className="flex items-center gap-4" onClick={() => push({ type: "exercisePlay", exerciseId: ex.id })}>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-0.5">
                        <span className="font-semibold text-sm" style={{ color: TEXT_PRIMARY }}>{ex.title}</span>
                        <span className="text-xs px-2 py-0.5 rounded-full font-semibold"
                          style={{ backgroundColor: ex.dueErr ? `${ERROR}18` : SURFACE, color: ex.dueErr ? ERROR : TEXT_SECONDARY }}>{ex.due}</span>
                      </div>
                      <div className="text-xs mb-2" style={{ color: TEXT_SECONDARY }}>{ex.type}</div>
                      <div className="h-1.5 rounded-full overflow-hidden" style={{ backgroundColor: BORDER }}>
                        <div className="h-full rounded-full" style={{ width: `${ex.progress}%`, backgroundColor: TEAL }} />
                      </div>
                    </div>
                    <button className="px-4 py-2 rounded-lg text-sm font-semibold text-white flex-shrink-0" style={{ backgroundColor: ex.btnColor }}>{ex.btn}</button>
                  </Card>
                ))}
              </div>
            </div>
            <Card onClick={() => push({ type: "lessonDetail", lessonNum: 4 })}>
              <div className="text-xs font-semibold mb-1" style={{ color: TEAL }}>Continue learning</div>
              <div className="flex items-center justify-between mb-2">
                <div>
                  <div className="text-xs" style={{ color: TEXT_SECONDARY }}>Term 1 · Lesson 4</div>
                  <div className="font-bold text-base" style={{ color: TEXT_PRIMARY }}>Greetings &amp; Introductions</div>
                </div>
                <TealLink>Continue →</TealLink>
              </div>
              <div className="h-2 rounded-full overflow-hidden" style={{ backgroundColor: BORDER }}>
                <div className="h-full rounded-full" style={{ width: "37%", backgroundColor: TEAL }} />
              </div>
              <p className="text-xs mt-1" style={{ color: TEXT_SECONDARY }}>3 of 8 lessons done · 37%</p>
            </Card>
          </div>
          <div className="space-y-4">
            <Card>
              <SectionHeader title="Class term" />
              <div className="flex justify-center py-2"><Ring value={5} total={8} /></div>
              <div className="pt-3 mt-2 border-t space-y-1.5" style={{ borderColor: BORDER }}>
                <div className="flex justify-between text-xs"><span style={{ color: TEXT_SECONDARY }}>Sessions remaining</span><span className="font-semibold" style={{ color: NAVY }}>6</span></div>
                <div className="flex justify-between text-xs"><span style={{ color: TEXT_SECONDARY }}>Term ends</span><span className="font-semibold" style={{ color: NAVY }}>Dec 31</span></div>
                <div className="text-xs font-semibold" style={{ color: ERROR }}>Term ends in 32 days</div>
              </div>
            </Card>
            <Card>
              <SectionHeader title="Average score" />
              <div className="text-center py-2">
                <div className="font-bold text-3xl" style={{ color: SUCCESS }}>82%</div>
                <div className="text-xs mt-1" style={{ color: TEXT_SECONDARY }}>Quizzes taken: 5</div>
              </div>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
}

function StudentMyClasses({ push }: { push: (s: Screen) => void }) {
  return (
    <div className="p-8 overflow-y-auto flex-1">
      <div className="max-w-2xl space-y-6">
        <div>
          <SectionHeader title="Upcoming" />
          <div className="space-y-3">
            {classes.filter(c => c.status === "upcoming").map(cls => (
              <Card key={cls.id} onClick={() => push({ type: "studentClassDetail", classId: cls.id })}>
                <div className="flex items-start gap-3">
                  <div className="px-2.5 py-1.5 rounded-lg text-white text-xs font-bold flex-shrink-0 text-center leading-tight" style={{ backgroundColor: TEAL }}>
                    {cls.date.split(" ").map((l, i) => <div key={i}>{l}</div>)}
                  </div>
                  <div className="flex-1">
                    <div className="font-semibold text-sm mb-1" style={{ color: TEXT_PRIMARY }}>{cls.title}</div>
                    <div className="text-xs" style={{ color: TEXT_SECONDARY }}>{cls.time} · {cls.duration} min · Teacher Ng</div>
                  </div>
                  <TealLink>View details</TealLink>
                </div>
              </Card>
            ))}
          </div>
        </div>
        <div>
          <SectionHeader title="Past classes" />
          <div className="space-y-3">
            {classes.filter(c => c.status === "concluded").map(cls => (
              <Card key={cls.id} className="opacity-70">
                <div className="flex items-center justify-between">
                  <div>
                    <div className="font-semibold text-sm mb-0.5" style={{ color: TEXT_SECONDARY }}>{cls.title}</div>
                    <div className="text-xs" style={{ color: TEXT_SECONDARY }}>{cls.date} · {cls.time}</div>
                  </div>
                  <StatusPill status="concluded" />
                </div>
              </Card>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function StudentLessons({ push }: { push: (s: Screen) => void }) {
  const [term, setTerm] = useState(1);
  const lessons = [
    { num: 1, title: "Greetings & Introductions", status: "done",     score: 90,   hasQuiz: true  },
    { num: 2, title: "Numbers & Counting",         status: "done",     score: 85,   hasQuiz: true  },
    { num: 3, title: "Colors & Descriptions",       status: "done",     score: 78,   hasQuiz: true  },
    { num: 4, title: "Food & Dining",               status: "progress", score: null, hasQuiz: false },
    { num: 5, title: "Daily Routines",              status: "locked",   score: null, hasQuiz: true  },
    { num: 6, title: "Shopping & Markets",          status: "locked",   score: null, hasQuiz: true  },
    { num: 7, title: "Travel & Transport",          status: "locked",   score: null, hasQuiz: false },
    { num: 8, title: "Weather & Seasons",           status: "locked",   score: null, hasQuiz: true  },
  ];
  const assignments = [
    { id: 1, title: "HSK 2 Grammar — Unit 3", type: "Multiple choice",   due: "Dec 20", status: "not_started", score: null },
    { id: 2, title: "Reading Practice",        type: "Compose sentences", due: null,     status: "in_progress", score: null },
    { id: 3, title: "Dialogue Matching",       type: "Matching",          due: null,     status: "done",        score: 85   },
  ];
  return (
    <div className="p-8 overflow-y-auto flex-1">
      <div className="max-w-3xl space-y-6">
        <div>
          <SectionHeader title="Assigned practice"
            action={<span className="text-xs px-2 py-0.5 rounded-full font-bold text-white" style={{ backgroundColor: TEAL }}>{assignments.filter(a => a.status !== "done").length}</span>} />
          <div className="space-y-2">
            {assignments.map(a => (
              <Card key={a.id} className="flex items-center gap-3" onClick={() => push({ type: "exercisePlay", exerciseId: a.id })}>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-0.5">
                    <span className="font-semibold text-sm" style={{ color: TEXT_PRIMARY }}>{a.title}</span>
                    <StatusPill status={a.status} />
                  </div>
                  <div className="text-xs" style={{ color: TEXT_SECONDARY }}>
                    {a.type}{a.due ? <span style={{ color: ERROR }}> · Due {a.due}</span> : " · No due date"}
                  </div>
                </div>
                {a.score && <span className="font-bold text-sm" style={{ color: SUCCESS }}>{a.score}%</span>}
                <ChevronRight size={16} style={{ color: TEXT_SECONDARY }} />
              </Card>
            ))}
          </div>
        </div>
        <div>
          <div className="flex items-center justify-between mb-3">
            <h3 className="font-bold" style={{ color: NAVY, fontSize: 15 }}>Lessons by term</h3>
            <div className="flex gap-1">
              {[1,2].map(t => (
                <button key={t} onClick={() => setTerm(t)}
                  className="px-3 py-1 rounded-full text-xs font-semibold transition-all"
                  style={{ backgroundColor: term === t ? NAVY : "#fff", color: term === t ? "#fff" : TEXT_SECONDARY, border: `1px solid ${term === t ? NAVY : BORDER}` }}>
                  Term {t}
                </button>
              ))}
            </div>
          </div>
          <div className="space-y-2">
            {lessons.map(l => (
              <Card key={l.num} className={`flex items-center gap-3 ${l.status !== "locked" ? "" : "opacity-60"}`}
                onClick={l.status !== "locked" ? () => push({ type: "lessonDetail", lessonNum: l.num }) : undefined}>
                <div className="w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold flex-shrink-0"
                  style={{ backgroundColor: l.status === "done" ? NAVY : l.status === "progress" ? `${TEAL}18` : SURFACE, color: l.status === "done" ? "#fff" : l.status === "progress" ? TEAL : TEXT_SECONDARY, border: l.status === "progress" ? `2px solid ${TEAL}` : undefined }}>
                  {l.status === "done" ? <Check size={14} /> : l.num}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="font-medium text-sm" style={{ color: l.status === "locked" ? TEXT_SECONDARY : TEXT_PRIMARY }}>Lesson {l.num}: {l.title}</span>
                    {l.hasQuiz && <span className="text-xs px-1.5 py-0.5 rounded font-semibold" style={{ backgroundColor: `${TEAL}18`, color: TEAL }}>Quiz</span>}
                  </div>
                </div>
                {l.score && <span className="text-sm font-semibold" style={{ color: SUCCESS }}>{l.score}%</span>}
                {l.status === "progress" && <ChevronRight size={16} style={{ color: TEAL }} />}
                {l.status === "locked" && <Lock size={14} style={{ color: TEXT_SECONDARY }} />}
              </Card>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function StudentProgress() {
  const quizData = [
    { day: "Mon", score: 85 }, { day: "Tue", score: 70 }, { day: "Wed", score: 90 },
    { day: "Thu", score: 55 }, { day: "Fri", score: 80 }, { day: "Sat", score: 75 }, { day: "Sun", score: 0 },
  ];
  const quizHistory = [
    { lesson: "Greetings & Introductions", score: 90, date: "Dec 15" },
    { lesson: "Numbers & Counting",         score: 85, date: "Dec 12" },
    { lesson: "Colors & Descriptions",       score: 78, date: "Dec 9"  },
    { lesson: "HSK 2 Grammar Test",          score: 55, date: "Dec 6"  },
  ];
  return (
    <div className="p-8 overflow-y-auto flex-1">
      <div className="max-w-4xl grid grid-cols-3 gap-6">
        <div className="col-span-2 space-y-5">
          <Card>
            <div className="flex items-center justify-between">
              <div>
                <div className="font-bold text-xl mb-1" style={{ color: NAVY }}>Term 1</div>
                <div className="grid grid-cols-2 gap-4 mt-3">
                  <div><div className="text-2xl font-bold" style={{ color: TEAL }}>82%</div><div className="text-xs" style={{ color: TEXT_SECONDARY }}>Average score</div></div>
                  <div><div className="text-2xl font-bold" style={{ color: NAVY }}>5</div><div className="text-xs" style={{ color: TEXT_SECONDARY }}>Quizzes taken</div></div>
                </div>
              </div>
              <Ring value={5} total={8} size={88} stroke={9} />
            </div>
          </Card>
          <Card>
            <SectionHeader title="This week" />
            <div className="h-28">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={quizData.map(d => ({ ...d, fill: d.score >= 80 ? `${SUCCESS}BF` : d.score >= 60 ? `${TEAL}BF` : d.score > 0 ? `${ERROR}BF` : BORDER }))} barSize={22}>
                  <XAxis dataKey="day" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: TEXT_SECONDARY }} />
                  <YAxis hide domain={[0, 100]} />
                  <Bar dataKey="score" radius={[4, 4, 0, 0]} isAnimationActive={false} />
                </BarChart>
              </ResponsiveContainer>
            </div>
            <p className="text-xs mt-1" style={{ color: TEXT_SECONDARY }}>3 quizzes completed this week</p>
          </Card>
          <Card>
            <SectionHeader title="Recent quizzes" />
            <div className="space-y-3">
              {quizHistory.map(q => (
                <div key={q.lesson} className="flex items-center justify-between py-1 border-b last:border-0" style={{ borderColor: BORDER }}>
                  <div>
                    <div className="text-sm font-medium" style={{ color: TEXT_PRIMARY }}>{q.lesson}</div>
                    <div className="text-xs" style={{ color: TEXT_SECONDARY }}>{q.date}</div>
                  </div>
                  <span className="font-bold text-sm px-2.5 py-1 rounded-lg"
                    style={{ backgroundColor: q.score >= 80 ? `${SUCCESS}18` : q.score >= 60 ? `${TEAL}18` : `${ERROR}18`, color: q.score >= 80 ? SUCCESS : q.score >= 60 ? TEAL : ERROR }}>
                    {q.score}%
                  </span>
                </div>
              ))}
            </div>
          </Card>
        </div>
        <div className="space-y-4">
          <Card>
            <SectionHeader title="Completed" />
            <div className="flex flex-wrap gap-1.5">
              {[1,2,3].map(n => <span key={n} className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-semibold text-white" style={{ backgroundColor: NAVY }}>Lesson {n} <Check size={10} /></span>)}
              {[4,5,6,7,8].map(n => <span key={n} className="inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-semibold" style={{ backgroundColor: SURFACE, color: TEXT_SECONDARY, border: `1px solid ${BORDER}` }}>Lesson {n}</span>)}
            </div>
          </Card>
          <Card>
            <SectionHeader title="HSK Level" />
            <div className="text-center py-3">
              <HskBadge level={3} />
              <div className="text-xs mt-2 mb-3" style={{ color: TEXT_SECONDARY }}>Current level</div>
              <div className="h-1.5 rounded-full overflow-hidden" style={{ backgroundColor: BORDER }}>
                <div className="h-full rounded-full" style={{ width: "55%", backgroundColor: TEAL }} />
              </div>
              <div className="text-xs mt-1" style={{ color: TEXT_SECONDARY }}>HSK 3 → HSK 4</div>
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}

function StudentProfile({ onSignOut }: { onSignOut: () => void }) {
  return (
    <div className="p-8 overflow-y-auto flex-1">
      <div className="max-w-lg space-y-4">
        <Card><div className="flex items-center gap-4">
          <Avatar initials="LM" size={64} color={TEAL} />
          <div>
            <div className="font-bold text-lg" style={{ color: NAVY }}>Li Ming</div>
            <div className="flex items-center gap-2 mt-1"><HskBadge level={3} /><span className="text-xs px-2 py-0.5 rounded font-semibold text-white" style={{ backgroundColor: TEAL }}>Student</span></div>
            <div className="text-xs mt-1" style={{ color: TEXT_SECONDARY }}>li.ming@student.com</div>
          </div>
        </div></Card>
        <Card>
          <SectionHeader title="Class term" />
          <div className="flex items-center gap-2 mb-2">
            <span className="text-sm font-bold px-2.5 py-1 rounded text-white" style={{ backgroundColor: NAVY }}>16 sessions</span>
            <span className="text-sm font-semibold" style={{ color: TEXT_PRIMARY }}>6 remaining</span>
          </div>
          <div className="h-2 rounded-full overflow-hidden mb-2" style={{ backgroundColor: BORDER }}>
            <div className="h-full rounded-full" style={{ width: "62%", backgroundColor: TEAL }} />
          </div>
          <div className="text-xs" style={{ color: TEXT_SECONDARY }}>Nov 1 – Dec 31, 2024</div>
          <div className="text-xs font-semibold mt-1" style={{ color: ERROR }}>Term ends in 32 days</div>
        </Card>
        <Card className="!p-0 overflow-hidden">
          {[{ icon: User, label: "Edit profile" }, { icon: FileText, label: "Help" }].map(({ icon: Icon, label }) => (
            <button key={label} className="w-full flex items-center justify-between px-4 py-3.5 hover:bg-gray-50 border-b last:border-0" style={{ borderColor: BORDER }}>
              <div className="flex items-center gap-3"><Icon size={16} style={{ color: TEXT_SECONDARY }} /><span className="text-sm font-medium" style={{ color: TEXT_PRIMARY }}>{label}</span></div>
              <ChevronRight size={16} style={{ color: TEXT_SECONDARY }} />
            </button>
          ))}
        </Card>
        <button onClick={onSignOut} className="w-full py-3 text-sm font-semibold rounded-xl border-2 hover:bg-red-50" style={{ color: ERROR, borderColor: `${ERROR}30` }}>Sign out</button>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════
   STUDENT PUSHED SCREENS
═══════════════════════════════════════════ */

function ExercisePlayScreen({ exerciseId, onBack }: { exerciseId: number; onBack: () => void }) {
  const ex = exercises.find(e => e.id === exerciseId) ?? exercises[0];
  const [qIndex, setQIndex] = useState(0);
  const [selected, setSelected] = useState<number | null>(null);
  const [submitted, setSubmitted] = useState(false);
  const [composeUsed, setComposeUsed] = useState<string[]>([]);
  const [matched, setMatched] = useState<Record<number, string>>({});
  const [selectedPrompt, setSelectedPrompt] = useState<number | null>(null);
  const [playing, setPlaying] = useState(false);
  const [audioError, setAudioError] = useState(false);
  const [typed, setTyped] = useState("");

  if (ex.type === "Reading cloze" || ex.type === "Picture + keyword") {
    return (
      <div className="flex flex-col flex-1 overflow-hidden">
        <PushedBar title={ex.title} onBack={onBack} />
        <div className="flex-1 flex items-center justify-center">
          <EmptyState icon={Construction} title="Exercise type coming soon" subtitle="This worksheet type is not available for students yet." />
        </div>
      </div>
    );
  }

  const segments = ["南方的", "夏天", "热极了"];
  const matchPrompts = [{ n: 1, text: "你叫什么名字？" }, { n: 2, text: "你好吗？" }, { n: 3, text: "谢谢你！" }];
  const matchAnswers = [{ l: "A", text: "我叫李明。" }, { l: "B", text: "我很好，谢谢。" }, { l: "C", text: "不客气！" }];

  const q = mcQuestions[Math.min(qIndex, mcQuestions.length - 1)];
  const isLast = qIndex >= ex.questions - 1;
  const handleNext = () => { if (isLast) { onBack(); return; } setQIndex(i => i + 1); setSelected(null); setSubmitted(false); setTyped(""); setPlaying(false); };

  if (ex.type === "Listening") {
    return (
      <div className="flex flex-col flex-1 overflow-hidden">
        <PushedBar title={ex.title} onBack={onBack} right={<span className="text-sm font-semibold" style={{ color: TEXT_SECONDARY }}>Q {qIndex+1} of {ex.questions}</span>} />
        <div className="h-1.5 bg-gray-100"><div className="h-full transition-all" style={{ width: `${((qIndex+1)/ex.questions)*100}%`, backgroundColor: TEAL }} /></div>
        <div className="p-8 overflow-y-auto flex-1 max-w-xl mx-auto w-full space-y-5">
          <div className="p-3 rounded-xl flex items-center gap-2" style={{ backgroundColor: SURFACE }}>
            <Headphones size={14} style={{ color: TEXT_SECONDARY }} />
            <span className="text-sm" style={{ color: TEXT_SECONDARY }}>Listen to the audio, then answer.</span>
          </div>

          {/* Audio player */}
          {audioError ? (
            <Card className="border-2" style={{ borderColor: `${ERROR}40`, backgroundColor: `${ERROR}05` }}>
              <div className="flex items-start gap-3">
                <AlertCircle size={20} style={{ color: ERROR }} className="flex-shrink-0 mt-0.5" />
                <div className="flex-1">
                  <div className="font-semibold text-sm mb-1" style={{ color: ERROR }}>Audio failed to load</div>
                  <div className="text-xs mb-2" style={{ color: TEXT_SECONDARY }}>Check your connection and try again.</div>
                  <button onClick={() => setAudioError(false)} className="text-sm font-semibold flex items-center gap-1" style={{ color: TEAL }}><RotateCcw size={13} />Retry</button>
                </div>
              </div>
            </Card>
          ) : (
            <Card>
              <div className="flex items-center gap-3">
                <button onClick={() => setPlaying(p => !p)}
                  className="w-12 h-12 rounded-full flex items-center justify-center text-white flex-shrink-0" style={{ backgroundColor: TEAL }}>
                  {playing ? <Pause size={20} /> : <Play size={20} />}
                </button>
                <div className="flex-1">
                  <div className="h-1.5 rounded-full overflow-hidden" style={{ backgroundColor: BORDER }}>
                    <div className="h-full rounded-full transition-all" style={{ width: playing ? "45%" : "0%", backgroundColor: TEAL }} />
                  </div>
                  <div className="flex justify-between text-xs mt-1" style={{ color: TEXT_SECONDARY }}>
                    <span>{playing ? "0:19" : "0:00"}</span><span>0:42</span>
                  </div>
                </div>
                <Volume2 size={18} style={{ color: TEXT_SECONDARY }} className="flex-shrink-0" />
              </div>
              <button onClick={() => setAudioError(true)} className="text-xs mt-2" style={{ color: TEXT_SECONDARY }}>Simulate load error</button>
            </Card>
          )}

          <Card className="text-center">
            <div className="text-xs font-semibold mb-2" style={{ color: TEAL }}>Question {qIndex + 1}</div>
            <div className="text-lg font-bold" style={{ color: TEXT_PRIMARY, fontFamily: "'Noto Sans SC', sans-serif" }}>{q.q}</div>
          </Card>

          {/* MC answer (default) */}
          <div className="space-y-3">
            {q.options.map((opt, oi) => {
              const isSel = selected === oi, isCorr = oi === q.answer;
              let border = BORDER, bg = "#fff", text = TEXT_PRIMARY;
              if (submitted) { if (isCorr) { border = SUCCESS; bg = `${SUCCESS}12`; text = SUCCESS; } else if (isSel) { border = ERROR; bg = `${ERROR}10`; text = ERROR; } }
              else if (isSel) { border = TEAL; bg = `${TEAL}10`; }
              return (
                <button key={oi} disabled={submitted} onClick={() => setSelected(oi)}
                  className="w-full flex items-center gap-3 p-4 rounded-xl border-2 text-left transition-all" style={{ borderColor: border, backgroundColor: bg }}>
                  <span className="w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold text-white flex-shrink-0"
                    style={{ backgroundColor: submitted ? (isCorr ? SUCCESS : isSel ? ERROR : TEXT_SECONDARY) : isSel ? TEAL : TEXT_SECONDARY }}>{String.fromCharCode(65+oi)}</span>
                  <span className="text-base font-medium" style={{ color: text, fontFamily: "'Noto Sans SC', sans-serif" }}>{opt}</span>
                </button>
              );
            })}
          </div>

          {!submitted
            ? <TealBtn full onClick={() => { if (selected !== null) setSubmitted(true); }}>Submit answer</TealBtn>
            : <TealBtn full onClick={handleNext}>{isLast ? "Finish exercise" : "Next question →"}</TealBtn>}
        </div>
      </div>
    );
  }

  if (ex.type === "Compose sentences") {
    return (
      <div className="flex flex-col flex-1 overflow-hidden">
        <PushedBar title="Compose sentences" onBack={onBack} right={<span className="text-sm font-semibold" style={{ color: TEXT_SECONDARY }}>Q {qIndex+1} of {ex.questions}</span>} />
        <div className="h-1.5 bg-gray-100"><div className="h-full transition-all" style={{ width: `${((qIndex+1)/ex.questions)*100}%`, backgroundColor: TEAL }} /></div>
        <div className="p-8 overflow-y-auto flex-1 max-w-2xl mx-auto w-full space-y-5">
          <div className="p-3 rounded-xl flex items-center gap-2" style={{ backgroundColor: SURFACE }}>
            <Info size={14} style={{ color: TEXT_SECONDARY }} />
            <span className="text-sm" style={{ color: TEXT_SECONDARY }}>Arrange the word segments into a correct sentence.</span>
          </div>
          <Card>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-semibold" style={{ color: TEXT_SECONDARY }}>Your answer</span>
              <button onClick={() => setComposeUsed([])} className="flex items-center gap-1 text-xs" style={{ color: TEXT_SECONDARY }}><RotateCcw size={11} />Clear</button>
            </div>
            <div className="min-h-12 border-2 border-dashed rounded-xl p-3 flex flex-wrap gap-2 items-center" style={{ borderColor: TEAL }}>
              {composeUsed.length === 0
                ? <span className="text-sm italic" style={{ color: TEXT_SECONDARY }}>Tap segments below to add them here</span>
                : composeUsed.map((seg, i) => (
                  <span key={i} className="px-3 py-1.5 rounded-lg text-white text-sm font-bold" style={{ backgroundColor: TEAL, fontFamily: "'Noto Sans SC', sans-serif" }}>{seg}</span>
                ))}
            </div>
          </Card>
          <Card>
            <div className="text-xs font-semibold mb-3" style={{ color: TEXT_SECONDARY }}>Word bank</div>
            <div className="flex flex-wrap gap-2">
              {segments.map(seg => {
                const used = composeUsed.includes(seg);
                return (
                  <button key={seg} disabled={used} onClick={() => setComposeUsed(u => [...u, seg])}
                    className="px-4 py-2 rounded-xl border-2 text-sm font-bold transition-all"
                    style={{ borderColor: used ? BORDER : TEAL, color: used ? TEXT_SECONDARY : TEXT_PRIMARY, opacity: used ? 0.4 : 1, fontFamily: "'Noto Sans SC', sans-serif" }}>
                    {seg}
                  </button>
                );
              })}
            </div>
          </Card>
          <TealBtn full onClick={handleNext}>Check answer</TealBtn>
        </div>
      </div>
    );
  }

  if (ex.type === "Matching") {
    return (
      <div className="flex flex-col flex-1 overflow-hidden">
        <PushedBar title="Matching exercise" onBack={onBack} right={<span className="text-sm font-semibold" style={{ color: TEXT_SECONDARY }}>Q 1 of 1</span>} />
        <div className="h-1.5 bg-gray-100"><div className="h-full" style={{ width: "100%", backgroundColor: TEAL }} /></div>
        <div className="p-8 overflow-y-auto flex-1 max-w-2xl mx-auto w-full space-y-5">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <div className="text-xs font-semibold mb-3" style={{ color: TEXT_SECONDARY }}>Prompts</div>
              {matchPrompts.map(p => (
                <button key={p.n} onClick={() => setSelectedPrompt(p.n)}
                  className="w-full text-left p-3 rounded-xl border-2 mb-3 transition-all"
                  style={{ borderColor: matched[p.n] ? SUCCESS : selectedPrompt === p.n ? NAVY : BORDER, backgroundColor: matched[p.n] ? `${SUCCESS}10` : selectedPrompt === p.n ? `${NAVY}08` : "#fff" }}>
                  <span className="w-6 h-6 rounded-full inline-flex items-center justify-center text-xs font-bold text-white mr-2" style={{ backgroundColor: NAVY }}>{p.n}</span>
                  <span className="text-sm" style={{ fontFamily: "'Noto Sans SC', sans-serif" }}>{p.text}</span>
                  {matched[p.n] && <span className="ml-2 text-xs font-bold" style={{ color: SUCCESS }}>→ {matched[p.n]}</span>}
                </button>
              ))}
            </div>
            <div>
              <div className="text-xs font-semibold mb-3" style={{ color: TEXT_SECONDARY }}>Answers</div>
              {matchAnswers.map(a => {
                const used = Object.values(matched).includes(a.l);
                return (
                  <button key={a.l} disabled={used}
                    onClick={() => { if (selectedPrompt !== null) { setMatched(m => ({ ...m, [selectedPrompt]: a.l })); setSelectedPrompt(null); } }}
                    className="w-full text-left p-3 rounded-xl border-2 mb-3 transition-all"
                    style={{ borderColor: used ? SUCCESS : BORDER, backgroundColor: used ? `${SUCCESS}10` : "#fff", opacity: used ? 0.7 : 1 }}>
                    <span className="w-6 h-6 rounded-full inline-flex items-center justify-center text-xs font-bold text-white mr-2" style={{ backgroundColor: TEAL }}>{a.l}</span>
                    <span className="text-sm" style={{ fontFamily: "'Noto Sans SC', sans-serif" }}>{a.text}</span>
                  </button>
                );
              })}
            </div>
          </div>
          <TealBtn full onClick={handleNext}>Check answers</TealBtn>
        </div>
      </div>
    );
  }

  // Multiple choice
  return (
    <div className="flex flex-col flex-1 overflow-hidden">
      <PushedBar title={ex.title} onBack={onBack} right={<span className="text-sm font-semibold" style={{ color: TEXT_SECONDARY }}>Q {qIndex+1} of {ex.questions}</span>} />
      <div className="h-1.5 bg-gray-100"><div className="h-full transition-all" style={{ width: `${((qIndex+1)/ex.questions)*100}%`, backgroundColor: TEAL }} /></div>
      <div className="p-8 overflow-y-auto flex-1 max-w-xl mx-auto w-full space-y-5">
        <Card className="text-center">
          <div className="text-xs font-semibold mb-2" style={{ color: TEAL }}>Question {qIndex + 1}</div>
          <div className="text-xl font-bold mb-1" style={{ color: TEXT_PRIMARY, fontFamily: "'Noto Sans SC', sans-serif" }}>{q.q}</div>
          <div className="text-sm italic" style={{ color: TEXT_SECONDARY }}>{q.hint}</div>
        </Card>
        <div className="space-y-3">
          {q.options.map((opt, oi) => {
            const isSel = selected === oi, isCorr = oi === q.answer;
            let border = BORDER, bg = "#fff", text = TEXT_PRIMARY;
            if (submitted) { if (isCorr) { border = SUCCESS; bg = `${SUCCESS}12`; text = SUCCESS; } else if (isSel) { border = ERROR; bg = `${ERROR}10`; text = ERROR; } }
            else if (isSel) { border = TEAL; bg = `${TEAL}10`; }
            return (
              <button key={oi} disabled={submitted} onClick={() => setSelected(oi)}
                className="w-full flex items-center gap-3 p-4 rounded-xl border-2 text-left transition-all"
                style={{ borderColor: border, backgroundColor: bg }}>
                <span className="w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold text-white flex-shrink-0"
                  style={{ backgroundColor: submitted ? (isCorr ? SUCCESS : isSel ? ERROR : TEXT_SECONDARY) : isSel ? TEAL : TEXT_SECONDARY }}>
                  {String.fromCharCode(65 + oi)}
                </span>
                <span className="text-base font-medium" style={{ color: text, fontFamily: "'Noto Sans SC', sans-serif" }}>{opt}</span>
                {submitted && isCorr && <Check size={16} style={{ color: SUCCESS }} className="ml-auto" />}
                {submitted && isSel && !isCorr && <X size={16} style={{ color: ERROR }} className="ml-auto" />}
              </button>
            );
          })}
        </div>
        {!submitted
          ? <TealBtn full onClick={() => { if (selected !== null) setSubmitted(true); }}>Submit answer</TealBtn>
          : <TealBtn full onClick={handleNext}>{isLast ? "Finish exercise" : "Next question →"}</TealBtn>}
      </div>
    </div>
  );
}

function LessonDetailScreen({ lessonNum, onBack, push }: { lessonNum: number; onBack: () => void; push: (s: Screen) => void }) {
  const titles: Record<number, string> = { 1: "Greetings & Introductions", 2: "Numbers & Counting", 3: "Colors & Descriptions", 4: "Food & Dining", 5: "Daily Routines" };
  const vocab = [
    { zh: "你好",   py: "nǐ hǎo",    en: "Hello"      },
    { zh: "谢谢",   py: "xièxie",   en: "Thank you"  },
    { zh: "再见",   py: "zàijiàn",  en: "Goodbye"    },
    { zh: "对不起", py: "duìbuqǐ",  en: "Sorry"      },
  ];
  return (
    <div className="flex flex-col flex-1 overflow-hidden">
      <PushedBar title={titles[lessonNum] ?? `Lesson ${lessonNum}`} onBack={onBack}
        right={<span className="text-xs font-semibold" style={{ color: TEXT_SECONDARY }}>Lesson {lessonNum} / 8</span>} />
      <div className="p-8 overflow-y-auto flex-1">
        <div className="max-w-xl space-y-5">
          <Card>
            <div className="text-xs font-semibold mb-1" style={{ color: TEAL }}>Term 1 · Lesson {lessonNum}</div>
            <div className="font-bold text-2xl mb-2" style={{ color: NAVY }}>{titles[lessonNum] ?? `Lesson ${lessonNum}`}</div>
            <div className="flex items-center gap-2"><HskBadge level={1} /><StatusPill status={lessonNum <= 3 ? "done" : "in_progress"} /></div>
          </Card>
          <Card>
            <p className="text-sm leading-relaxed mb-4" style={{ color: TEXT_PRIMARY }}>
              In this lesson you will learn essential Chinese greetings used in everyday conversation. Mastering these will help you make a great first impression with native speakers.
            </p>
            <div className="text-xs font-bold mb-3" style={{ color: NAVY }}>Key vocabulary</div>
            <div className="space-y-2">
              {vocab.map(v => (
                <div key={v.zh} className="flex items-center gap-3 p-3 rounded-xl" style={{ backgroundColor: `${TEAL}08`, border: `1px solid ${TEAL}20` }}>
                  <span className="font-bold text-lg" style={{ color: NAVY, fontFamily: "'Noto Sans SC', sans-serif" }}>{v.zh}</span>
                  <span className="text-xs italic flex-1" style={{ color: TEXT_SECONDARY }}>({v.py})</span>
                  <span className="text-sm font-medium" style={{ color: TEXT_PRIMARY }}>— {v.en}</span>
                </div>
              ))}
            </div>
            <p className="text-sm leading-relaxed mt-4" style={{ color: TEXT_PRIMARY }}>
              Practice saying each phrase aloud. Chinese is a tonal language — pay attention to the tone marks above each syllable.
            </p>
          </Card>
          <div className="space-y-2">
            <TealBtn full onClick={() => push({ type: "quiz", lessonNum })}>Start quiz →</TealBtn>
            <p className="text-xs text-center" style={{ color: TEXT_SECONDARY }}>5 questions · Takes about 3 minutes</p>
          </div>
        </div>
      </div>
    </div>
  );
}

function QuizScreen({ lessonNum, onBack, push }: { lessonNum: number; onBack: () => void; push: (s: Screen) => void }) {
  const [qIndex, setQIndex] = useState(0);
  const [selected, setSelected] = useState<number | null>(null);
  const [submitted, setSubmitted] = useState(false);
  const [correct, setCorrect] = useState(0);
  const q = quizQuestions[qIndex];
  const isLast = qIndex >= quizQuestions.length - 1;

  const handleNext = () => {
    const newCorrect = correct + (selected === q.answer ? 1 : 0);
    if (isLast) { push({ type: "quizScore", lessonNum, score: newCorrect, total: quizQuestions.length }); return; }
    setCorrect(newCorrect); setQIndex(i => i + 1); setSelected(null); setSubmitted(false);
  };

  return (
    <div className="flex flex-col flex-1 overflow-hidden">
      <PushedBar title="Greetings Quiz" onBack={onBack} right={<span className="text-sm font-semibold" style={{ color: TEXT_SECONDARY }}>Q {qIndex+1} of {quizQuestions.length}</span>} />
      <div className="h-1.5 bg-gray-100"><div className="h-full transition-all" style={{ width: `${((qIndex+1)/quizQuestions.length)*100}%`, backgroundColor: TEAL }} /></div>
      <div className="p-8 overflow-y-auto flex-1 max-w-xl mx-auto w-full space-y-5">
        <Card className="text-center">
          <div className="text-xs font-semibold mb-2" style={{ color: TEXT_SECONDARY }}>Question {qIndex + 1} of {quizQuestions.length}</div>
          <div className="text-lg font-semibold mb-3" style={{ color: TEXT_PRIMARY }}>{q.q}</div>
          <div className="text-4xl font-bold" style={{ color: TEAL, fontFamily: "'Noto Sans SC', sans-serif" }}>{q.chinese}</div>
        </Card>
        <div className="space-y-3">
          {q.options.map((opt, oi) => {
            const isSel = selected === oi, isCorr = oi === q.answer;
            let border = BORDER, bg = "#fff", text = TEXT_PRIMARY;
            if (submitted) { if (isCorr) { border = SUCCESS; bg = `${SUCCESS}12`; text = SUCCESS; } else if (isSel) { border = ERROR; bg = `${ERROR}10`; text = ERROR; } }
            else if (isSel) { border = TEAL; bg = `${TEAL}10`; }
            return (
              <button key={oi} disabled={submitted} onClick={() => setSelected(oi)}
                className="w-full flex items-center gap-3 p-3.5 rounded-xl border-2 text-left transition-all"
                style={{ borderColor: border, backgroundColor: bg }}>
                <span className="w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold text-white flex-shrink-0"
                  style={{ backgroundColor: submitted ? (isCorr ? SUCCESS : isSel ? ERROR : TEXT_SECONDARY) : isSel ? TEAL : TEXT_SECONDARY }}>
                  {String.fromCharCode(65 + oi)}
                </span>
                <span className="text-sm font-medium" style={{ color: text }}>{opt}</span>
                {submitted && isCorr && <Check size={14} style={{ color: SUCCESS }} className="ml-auto" />}
              </button>
            );
          })}
        </div>
        {!submitted
          ? <TealBtn full onClick={() => { if (selected !== null) setSubmitted(true); }}>Submit</TealBtn>
          : <TealBtn full onClick={handleNext}>{isLast ? "See results" : "Next →"}</TealBtn>}
      </div>
    </div>
  );
}

function QuizScoreScreen({ lessonNum, score, total, onBack }: { lessonNum: number; score: number; total: number; onBack: () => void }) {
  const pct = Math.round((score / total) * 100);
  const passed = pct >= 60;
  return (
    <div className="flex flex-col flex-1 overflow-hidden">
      <div className="flex items-center justify-between px-6 py-5 flex-shrink-0" style={{ backgroundColor: passed ? SUCCESS : ERROR }}>
        <div className="text-white">
          <div className="flex items-center gap-2 mb-1">
            {passed ? <CheckCircle size={20} /> : <X size={20} />}
            <span className="font-bold text-lg">{passed ? "Great work!" : "Keep practising"}</span>
          </div>
          <div className="text-sm" style={{ color: "rgba(255,255,255,0.7)" }}>Greetings Quiz · Lesson {lessonNum}</div>
        </div>
        <div className="text-right">
          <div className="font-bold text-4xl text-white">{score}/{total}</div>
          <div className="font-bold text-xl" style={{ color: YELLOW }}>{pct}%</div>
        </div>
      </div>
      <div className="p-8 overflow-y-auto flex-1">
        <div className="max-w-lg space-y-4">
          <Card>
            <SectionHeader title="Results breakdown" />
            <div className="space-y-2">
              {quizQuestions.map((q, i) => {
                const wasCorrect = i < score;
                return (
                  <div key={i} className="flex items-center gap-3 py-1.5 border-b last:border-0" style={{ borderColor: BORDER }}>
                    <div className="w-6 h-6 rounded-full flex items-center justify-center flex-shrink-0"
                      style={{ backgroundColor: wasCorrect ? `${SUCCESS}20` : `${ERROR}15` }}>
                      {wasCorrect ? <Check size={12} style={{ color: SUCCESS }} /> : <X size={12} style={{ color: ERROR }} />}
                    </div>
                    <span className="text-sm flex-1" style={{ color: TEXT_PRIMARY }}>Q{i+1}: {q.q}</span>
                    <span className="text-xs font-semibold" style={{ color: wasCorrect ? SUCCESS : ERROR }}>{wasCorrect ? "Correct" : "Wrong"}</span>
                  </div>
                );
              })}
            </div>
          </Card>
          <div className="flex gap-3">
            <OutlineBtn onClick={onBack}>Back to lesson</OutlineBtn>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════
   DIALOGS
═══════════════════════════════════════════ */

function AssignDialog({ exerciseId, onClose }: { exerciseId: number; onClose: () => void }) {
  const [checked, setChecked] = useState<number[]>([1, 2]);
  const [dueOn, setDueOn] = useState(false);
  const ex = exercises.find(e => e.id === exerciseId)!;
  const toggle = (id: number) => setChecked(c => c.includes(id) ? c.filter(x => x !== id) : [...c, id]);
  return (
    <Modal onClose={onClose} wide>
      <div className="flex items-start justify-between mb-4">
        <div>
          <div className="font-bold text-lg" style={{ color: NAVY }}>Assign exercise</div>
          <div className="text-sm" style={{ color: TEXT_SECONDARY }}>{ex.title}</div>
        </div>
        <button onClick={onClose}><X size={18} style={{ color: TEXT_SECONDARY }} /></button>
      </div>
      <div className="relative mb-3">
        <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2" style={{ color: TEXT_SECONDARY }} />
        <input type="text" placeholder="Search students…" className="w-full pl-8 pr-3 py-2 rounded-lg border text-sm outline-none" style={{ borderColor: BORDER, fontSize: 13 }} />
      </div>
      <div className="max-h-48 overflow-y-auto space-y-1 mb-4">
        {students.map(s => (
          <label key={s.id} className="flex items-center gap-3 p-2.5 rounded-lg cursor-pointer hover:bg-gray-50">
            <input type="checkbox" checked={checked.includes(s.id)} onChange={() => toggle(s.id)} style={{ accentColor: NAVY }} />
            <Avatar initials={s.initials} size={28} />
            <span className="text-sm font-medium flex-1" style={{ color: TEXT_PRIMARY }}>{s.name}</span>
            <HskBadge level={s.hsk} />
          </label>
        ))}
      </div>
      <div className="border-t pt-3 mb-4" style={{ borderColor: BORDER }}>
        <label className="flex items-center justify-between cursor-pointer">
          <span className="text-sm font-medium" style={{ color: TEXT_PRIMARY }}>Set due date</span>
          <div onClick={() => setDueOn(v => !v)} className="w-10 h-5 rounded-full relative cursor-pointer transition-colors" style={{ backgroundColor: dueOn ? TEAL : BORDER }}>
            <div className="w-4 h-4 bg-white rounded-full absolute top-0.5 shadow transition-all" style={{ left: dueOn ? 22 : 2 }} />
          </div>
        </label>
        {dueOn && <input type="date" defaultValue="2024-12-20" className="w-full mt-2 px-3 py-2 rounded-lg border text-sm outline-none" style={{ borderColor: BORDER }} />}
      </div>
      <div className="flex gap-3">
        <OutlineBtn onClick={onClose}>Cancel</OutlineBtn>
        <NavyBtn onClick={onClose}>Assign to {checked.length} students</NavyBtn>
      </div>
    </Modal>
  );
}

function WorksheetImportDialog({ onClose }: { onClose: () => void }) {
  const [step, setStep] = useState(0);
  useEffect(() => {
    const t1 = setTimeout(() => setStep(1), 800);
    const t2 = setTimeout(() => setStep(2), 1800);
    const t3 = setTimeout(() => { setStep(3); setTimeout(onClose, 300); }, 2500);
    return () => { clearTimeout(t1); clearTimeout(t2); clearTimeout(t3); };
  }, [onClose]);
  const steps = ["Prepare file", "Read file", "Detect questions"];
  return (
    <Modal onClose={() => {}}>
      <div className="text-center mb-5">
        <div className="w-12 h-12 rounded-xl flex items-center justify-center mx-auto mb-3" style={{ backgroundColor: `${TEAL}18` }}>
          <Upload size={22} style={{ color: TEAL }} />
        </div>
        <div className="font-semibold text-base" style={{ color: TEXT_PRIMARY }}>Reading worksheet…</div>
        <div className="text-xs mt-1" style={{ color: TEXT_SECONDARY }}>HSK3_Grammar_Unit2.pdf</div>
      </div>
      <div className="h-1.5 rounded-full overflow-hidden mb-5" style={{ backgroundColor: BORDER }}>
        <div className="h-full rounded-full transition-all" style={{ width: `${(step / 3) * 100}%`, backgroundColor: TEAL }} />
      </div>
      <div className="space-y-3">
        {steps.map((s, i) => (
          <div key={s} className="flex items-center gap-3">
            {step > i
              ? <CheckCircle size={16} style={{ color: SUCCESS }} />
              : step === i
              ? <div className="w-4 h-4 rounded-full border-2 border-t-transparent animate-spin flex-shrink-0" style={{ borderColor: TEAL, borderTopColor: "transparent" }} />
              : <div className="w-4 h-4 rounded-full border-2 flex-shrink-0" style={{ borderColor: BORDER }} />}
            <span className="text-sm" style={{ color: step > i ? TEXT_SECONDARY : TEXT_PRIMARY, textDecoration: step > i ? "line-through" : undefined }}>{s}</span>
          </div>
        ))}
      </div>
    </Modal>
  );
}

/* ═══════════════════════════════════════════
   NEW SCREENS & DIALOGS (Prompts 1, 4-7)
═══════════════════════════════════════════ */

/* D3 — Import Review Screen */
function ImportReviewScreen({ exerciseId, onBack }: { exerciseId?: number; onBack: () => void }) {
  const [editedText, setEditedText] = useState(
    `SOAL PILIHAN GANDA\n1. 南方的天气很（ ）\n   A. 热  B. 冷  C. 好  D. 大\n\n2. 他每天（ ）去学校\n   A. 走路  B. 跑步  C. 骑车  D. 开车\n\n3. 这本书多少钱？\n   A. 十元  B. 二十元  C. 五元  D. 五十元`
  );
  const detectedQuestions = [
    { q: "南方的天气很（ ）", options: "A.热 B.冷 C.好 D.大", answer: "A" },
    { q: "他每天（ ）去学校", options: "A.走路 B.跑步 C.骑车 D.开车", answer: "C" },
    { q: "这本书多少钱？", options: "A.十元 B.二十元 C.五元 D.五十元", answer: "A" },
  ];
  return (
    <div className="flex flex-col flex-1 overflow-hidden">
      <div className="flex items-center justify-between px-6 h-14 flex-shrink-0 border-b bg-white" style={{ borderColor: BORDER }}>
        <button onClick={onBack} className="p-1.5 rounded-lg hover:bg-gray-100"><X size={18} style={{ color: NAVY }} /></button>
        <span className="font-bold text-base" style={{ color: NAVY }}>Review import</span>
        <NavyBtn onClick={onBack}>Import questions</NavyBtn>
      </div>
      <div className="p-8 overflow-y-auto flex-1">
        <div className="max-w-2xl space-y-5">
          {/* Detected type */}
          <Card className="border-l-4" style={{ borderLeftColor: TEAL }}>
            <div className="text-xs font-semibold mb-1" style={{ color: TEXT_SECONDARY }}>Detected type</div>
            <div className="flex items-center gap-2">
              <span className="font-bold text-base" style={{ color: TEXT_PRIMARY }}>Multiple choice</span>
              <Info size={14} style={{ color: TEXT_SECONDARY }} />
            </div>
            <div className="flex items-center gap-1.5 mt-1">
              <CheckCircle size={13} style={{ color: SUCCESS }} />
              <span className="text-xs font-semibold" style={{ color: SUCCESS }}>HSK 2 detected from title</span>
              <HskBadge level={2} />
            </div>
          </Card>

          {/* OCR text */}
          <Card>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-semibold" style={{ color: TEXT_SECONDARY }}>Extracted text — edit if needed</span>
              <button className="flex items-center gap-1 text-xs font-semibold" style={{ color: TEAL }}>
                <RotateCcw size={11} />Re-analyze
              </button>
            </div>
            <textarea
              value={editedText}
              onChange={e => setEditedText(e.target.value)}
              rows={8}
              className="w-full px-3 py-2.5 rounded-lg border text-sm outline-none resize-none"
              style={{ borderColor: BORDER, fontFamily: "'Noto Sans SC', 'Plus Jakarta Sans', monospace", lineHeight: 1.7, color: TEXT_PRIMARY }}
            />
          </Card>

          {/* Warning */}
          <div className="flex items-start gap-3 p-3.5 rounded-xl border" style={{ backgroundColor: `${YELLOW}15`, borderColor: `${YELLOW}60` }}>
            <span className="text-lg">⚠️</span>
            <span className="text-xs leading-relaxed" style={{ color: TEXT_PRIMARY }}>
              <strong>Check OCR text carefully.</strong> Scanned worksheets may have errors, especially with Chinese characters. Edit the text above if anything looks wrong before importing.
            </span>
          </div>

          {/* Question preview */}
          <Card>
            <SectionHeader title="Questions detected"
              action={<span className="text-xs px-2 py-0.5 rounded-full font-bold text-white" style={{ backgroundColor: TEAL }}>{detectedQuestions.length}</span>} />
            <div className="space-y-3">
              {detectedQuestions.map((q, i) => (
                <div key={i} className="p-3 rounded-lg border" style={{ borderColor: BORDER }}>
                  <div className="flex items-start gap-2 mb-1">
                    <span className="text-xs font-bold px-1.5 py-0.5 rounded text-white flex-shrink-0" style={{ backgroundColor: NAVY }}>Q{i+1}</span>
                    <span className="text-sm font-medium" style={{ color: TEXT_PRIMARY, fontFamily: "'Noto Sans SC', sans-serif" }}>{q.q}</span>
                  </div>
                  <div className="text-xs ml-7" style={{ color: TEXT_SECONDARY, fontFamily: "'Noto Sans SC', sans-serif" }}>{q.options}</div>
                  <div className="text-xs ml-7 mt-0.5 font-semibold" style={{ color: SUCCESS }}>Answer: {q.answer}</div>
                </div>
              ))}
            </div>
          </Card>

          <NavyBtn full onClick={onBack}>Import {detectedQuestions.length} questions</NavyBtn>
        </div>
      </div>
    </div>
  );
}

/* S7 — Student Class Detail */
function StudentClassDetailScreen({ classId, onBack }: { classId: number; onBack: () => void }) {
  const cls = classes.find(c => c.id === classId)!;
  const [showLeave, setShowLeave] = useState(false);
  const [left, setLeft] = useState(false);
  return (
    <div className="flex flex-col flex-1 overflow-hidden">
      {showLeave && (
        <Modal onClose={() => setShowLeave(false)}>
          <div className="text-center">
            <div className="font-bold text-base mb-2" style={{ color: TEXT_PRIMARY }}>Leave this class?</div>
            <p className="text-sm mb-4" style={{ color: TEXT_SECONDARY }}>You will be removed from <strong>{cls.title}</strong>. Your teacher will need to re-add you.</p>
            <div className="flex gap-3 justify-center">
              <OutlineBtn onClick={() => setShowLeave(false)}>Cancel</OutlineBtn>
              <button onClick={() => { setLeft(true); setShowLeave(false); }}
                className="px-4 py-2.5 rounded-lg text-sm font-semibold text-white"
                style={{ backgroundColor: ERROR }}>Leave class</button>
            </div>
          </div>
        </Modal>
      )}
      <PushedBar title={cls.title} onBack={onBack} />
      <div className="p-8 overflow-y-auto flex-1">
        <div className="max-w-lg space-y-4">
          {left && (
            <div className="flex items-center gap-3 p-4 rounded-xl" style={{ backgroundColor: `${ERROR}10`, border: `1px solid ${ERROR}30` }}>
              <X size={18} style={{ color: ERROR }} />
              <span className="text-sm font-semibold" style={{ color: ERROR }}>You have left this class.</span>
            </div>
          )}
          <Card>
            <div className="font-bold text-lg mb-2" style={{ color: TEXT_PRIMARY }}>{cls.title}</div>
            <div className="space-y-1.5">
              <div className="flex items-center gap-2 text-sm" style={{ color: TEXT_SECONDARY }}><Calendar size={14} />{cls.date} · {cls.time}</div>
              <div className="flex items-center gap-2 text-sm" style={{ color: TEXT_SECONDARY }}><User size={14} />Teacher Ng</div>
              <div className="flex items-center gap-2 text-sm" style={{ color: TEXT_SECONDARY }}><Clock size={14} />{cls.duration} min</div>
            </div>
            <div className="mt-3"><StatusPill status={cls.status} /></div>
          </Card>
          {cls.link && (
            <Card>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2" style={{ color: TEAL }}><Video size={16} /><span className="font-semibold text-sm">Join on Zoom</span></div>
                <button><Copy size={14} style={{ color: TEXT_SECONDARY }} /></button>
              </div>
            </Card>
          )}
          {!left && (
            <button onClick={() => setShowLeave(true)}
              className="w-full py-3 text-sm font-semibold rounded-xl border-2 hover:bg-red-50 transition-colors"
              style={{ color: ERROR, borderColor: `${ERROR}40` }}>
              Leave class
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

/* A5 — Complete Profile Screen */
function CompleteProfileScreen({ role, onDone }: { role: Role; onDone: () => void }) {
  const [hsk, setHsk] = useState("3");
  const [term, setTerm] = useState<"8" | "16">("8");
  const isMurid = role === "murid";
  return (
    <div className="flex flex-col flex-1 overflow-hidden" style={{ backgroundColor: SURFACE }}>
      <div className="flex items-center justify-between px-6 h-14 flex-shrink-0 text-white" style={{ backgroundColor: NAVY }}>
        <span className="font-bold text-base">Complete your profile</span>
        <span className="text-xs" style={{ color: "rgba(255,255,255,0.6)" }}>Step 1 of 2</span>
      </div>
      {/* Step indicator */}
      <div className="h-1 flex" style={{ backgroundColor: BORDER }}>
        <div className="h-full" style={{ width: "50%", backgroundColor: TEAL }} />
      </div>
      <div className="p-8 overflow-y-auto flex-1">
        <div className="max-w-sm mx-auto space-y-6">
          {/* Avatar */}
          <div className="flex flex-col items-center">
            <div className="w-20 h-20 rounded-full flex items-center justify-center mb-2" style={{ backgroundColor: SURFACE, border: `2px dashed ${BORDER}` }}>
              <User size={32} style={{ color: TEXT_SECONDARY }} />
            </div>
            <button className="text-sm font-semibold" style={{ color: TEAL }}>Add photo</button>
          </div>

          <Card>
            <div className="space-y-4">
              <InputField label="Full name" placeholder="Your name" value={USER_BY_ROLE[role].name} />
              <div>
                <label className="block text-xs font-semibold mb-1" style={{ color: TEXT_PRIMARY }}>Role</label>
                <div className="flex items-center gap-2 px-3 py-2.5 rounded-lg border" style={{ borderColor: BORDER }}>
                  <span className="text-sm font-semibold px-2 py-0.5 rounded text-white" style={{ backgroundColor: isMurid ? TEAL : NAVY }}>
                    {ROLE_LABEL[role]}
                  </span>
                  <span className="text-sm" style={{ color: TEXT_SECONDARY }}>· Set during registration</span>
                </div>
              </div>

              {isMurid && (
                <>
                  <div>
                    <label className="block text-xs font-semibold mb-1" style={{ color: TEXT_PRIMARY }}>HSK level</label>
                    <div className="flex items-center gap-2">
                      <select value={hsk} onChange={e => setHsk(e.target.value)}
                        className="flex-1 px-3 py-2.5 rounded-lg border bg-white text-sm outline-none" style={{ borderColor: BORDER }}>
                        {[1,2,3,4,5,6].map(l => <option key={l} value={String(l)}>HSK {l}</option>)}
                      </select>
                      <HskBadge level={parseInt(hsk)} />
                    </div>
                  </div>
                  <div>
                    <label className="block text-xs font-semibold mb-1" style={{ color: TEXT_PRIMARY }}>Lessons per term</label>
                    <div className="flex gap-2">
                      {(["8", "16"] as const).map(t => (
                        <button key={t} onClick={() => setTerm(t)}
                          className="flex-1 py-2.5 rounded-lg border-2 text-sm font-semibold transition-all"
                          style={{ backgroundColor: term === t ? TEAL : "#fff", color: term === t ? "#fff" : TEXT_SECONDARY, borderColor: term === t ? TEAL : BORDER }}>
                          {t} lessons
                        </button>
                      ))}
                    </div>
                  </div>
                </>
              )}
            </div>
          </Card>

          <button onClick={onDone}
            className="w-full py-3 rounded-xl font-semibold text-white text-sm hover:opacity-90"
            style={{ backgroundColor: isMurid ? TEAL : NAVY }}>
            Save and continue →
          </button>
        </div>
      </div>
    </div>
  );
}

/* D4 — Delete Exercise Dialog */
function DeleteExerciseDialog({ exerciseId, onClose }: { exerciseId: number; onClose: () => void }) {
  const ex = exercises.find(e => e.id === exerciseId)!;
  return (
    <Modal onClose={onClose}>
      <div className="text-center">
        <div className="w-12 h-12 rounded-full flex items-center justify-center mx-auto mb-3" style={{ backgroundColor: `${ERROR}15` }}>
          <Trash2 size={20} style={{ color: ERROR }} />
        </div>
        <div className="font-bold text-base mb-1" style={{ color: TEXT_PRIMARY }}>Delete exercise?</div>
        <p className="text-sm mb-1" style={{ color: TEXT_SECONDARY }}>
          <strong style={{ color: TEXT_PRIMARY }}>{ex.title}</strong>
        </p>
        <p className="text-sm mb-5" style={{ color: TEXT_SECONDARY }}>
          This will also remove all student assignments. This cannot be undone.
        </p>
        <div className="flex gap-3 justify-center">
          <OutlineBtn onClick={onClose}>Cancel</OutlineBtn>
          <button onClick={onClose}
            className="px-4 py-2.5 rounded-lg text-sm font-semibold text-white"
            style={{ backgroundColor: ERROR }}>Delete</button>
        </div>
      </div>
    </Modal>
  );
}

/* D6 — Add Class Term Dialog */
function AddClassTermDialog({ onClose }: { onClose: () => void }) {
  const [sessions, setSessions] = useState<"8" | "16">("8");
  return (
    <Modal onClose={onClose} wide>
      <div className="font-bold text-base mb-4" style={{ color: NAVY }}>Add class term</div>
      <div className="space-y-4">
        <div>
          <label className="block text-xs font-semibold mb-2" style={{ color: TEXT_PRIMARY }}>Session count</label>
          <div className="flex gap-2">
            {(["8", "16"] as const).map(s => (
              <button key={s} onClick={() => setSessions(s)}
                className="flex-1 py-2.5 rounded-lg border-2 text-sm font-semibold transition-all"
                style={{ backgroundColor: sessions === s ? NAVY : "#fff", color: sessions === s ? "#fff" : TEXT_SECONDARY, borderColor: sessions === s ? NAVY : BORDER }}>
                {s} sessions
              </button>
            ))}
          </div>
        </div>
        <div className="grid grid-cols-2 gap-3">
          <InputField label="Start date" type="date" value="2025-01-06" />
          <InputField label="End date" type="date" value="2025-03-28" />
        </div>
        <div className="flex items-center gap-2 p-3 rounded-lg" style={{ backgroundColor: SURFACE }}>
          <Info size={14} style={{ color: TEXT_SECONDARY }} />
          <span className="text-xs" style={{ color: TEXT_SECONDARY }}>
            Students will have <strong>{sessions} sessions</strong> available from the start date.
          </span>
        </div>
      </div>
      <div className="flex gap-3 mt-5">
        <OutlineBtn onClick={onClose}>Cancel</OutlineBtn>
        <NavyBtn onClick={onClose}>Add term</NavyBtn>
      </div>
    </Modal>
  );
}

/* D7 — Join Class Dialog */
function JoinClassDialog({ onClose }: { onClose: () => void }) {
  const [code, setCode] = useState("");
  const preview = code.length >= 4 ? classes[0] : null;
  return (
    <Modal onClose={onClose} wide>
      <div className="flex items-start justify-between mb-4">
        <div className="font-bold text-lg" style={{ color: NAVY }}>Join class session</div>
        <button onClick={onClose}><X size={18} style={{ color: TEXT_SECONDARY }} /></button>
      </div>
      <div className="space-y-4">
        <InputField label="Session code" placeholder="e.g. HS2312" value={code} onChange={setCode} />
        {preview && (
          <div className="p-4 rounded-xl border" style={{ borderColor: TEAL, backgroundColor: `${TEAL}08` }}>
            <div className="font-semibold text-sm mb-1" style={{ color: TEXT_PRIMARY }}>{preview.title}</div>
            <div className="text-xs" style={{ color: TEXT_SECONDARY }}>{preview.date} · {preview.time} · Teacher Ng</div>
          </div>
        )}
        {!preview && code.length > 0 && code.length < 4 && (
          <p className="text-xs" style={{ color: TEXT_SECONDARY }}>Enter at least 4 characters to preview the class</p>
        )}
      </div>
      <div className="flex gap-3 mt-5">
        <OutlineBtn onClick={onClose}>Cancel</OutlineBtn>
        <TealBtn onClick={onClose}>Confirm</TealBtn>
      </div>
    </Modal>
  );
}

/* States Reference Page */
function StatesReferencePage({ onBack }: { onBack: () => void }) {
  const emptyStates = [
    { icon: Users,      title: "No students yet",        subtitle: "Students appear here after they register with your invite code." },
    { icon: BookOpen,   title: "No exercises yet",        subtitle: "Tap New exercise to create practice, then assign it to students." },
    { icon: Calendar,   title: "No active classes",       subtitle: "Tap New class to create a session students can join." },
    { icon: Clock,      title: "No class history yet",    subtitle: "Concluded classes appear here after you tap Conclude class." },
    { icon: CheckCircle,title: "No classes joined yet",   subtitle: "Go to Home and tap Join on an open class session." },
    { icon: BookOpen,   title: "No content yet",          subtitle: "Your teacher will assign exercises and publish lessons for your level." },
    { icon: TrendingUp, title: "No progress yet",         subtitle: "Complete a lesson or quiz to see your history here." },
    { icon: Construction,title:"Exercise type coming soon",subtitle:"This worksheet type is not available for students yet." },
  ];
  const loadingStates = [
    { label: "Full-screen spinner", content: (
      <div className="flex flex-col items-center justify-center h-24">
        <div className="w-8 h-8 rounded-full border-2 border-t-transparent animate-spin" style={{ borderColor: TEAL, borderTopColor: "transparent" }} />
        <span className="text-xs mt-2" style={{ color: TEXT_SECONDARY }}>Loading…</span>
      </div>
    )},
    { label: "Skeleton list cards", content: (
      <div className="space-y-2 p-2">
        {[1,2,3].map(i => <div key={i} className="h-12 rounded-lg animate-pulse" style={{ backgroundColor: BORDER }} />)}
      </div>
    )},
    { label: "Button loading state", content: (
      <div className="p-4 flex justify-center">
        <button className="flex items-center gap-2 px-6 py-2.5 rounded-lg text-white text-sm font-semibold opacity-70" style={{ backgroundColor: TEAL }}>
          <div className="w-4 h-4 rounded-full border-2 border-t-transparent animate-spin" style={{ borderColor: "white", borderTopColor: "transparent" }} />
          Saving…
        </button>
      </div>
    )},
    { label: "Import step 2 active", content: (
      <div className="p-4 space-y-2">
        {["Prepare file", "Read file", "Detect questions"].map((s, i) => (
          <div key={s} className="flex items-center gap-2">
            {i < 1 ? <CheckCircle size={14} style={{ color: SUCCESS }} /> : i === 1 ? <div className="w-3.5 h-3.5 rounded-full border-2 border-t-transparent animate-spin" style={{ borderColor: TEAL, borderTopColor: "transparent" }} /> : <div className="w-3.5 h-3.5 rounded-full border-2" style={{ borderColor: BORDER }} />}
            <span className="text-xs" style={{ color: i === 1 ? TEXT_PRIMARY : TEXT_SECONDARY, textDecoration: i < 1 ? "line-through" : undefined }}>{s}</span>
          </div>
        ))}
      </div>
    )},
  ];
  const errorStates = [
    { label: "Error snackbar", content: (
      <div className="mx-2 flex items-center justify-between px-4 py-2.5 rounded-xl text-white text-xs font-medium" style={{ backgroundColor: ERROR }}>
        <span>Incorrect email or password</span>
        <X size={12} />
      </div>
    )},
    { label: "Inline field error", content: (
      <div className="p-4 space-y-1">
        <input className="w-full px-3 py-2 rounded-lg border text-sm outline-none" style={{ borderColor: ERROR, borderWidth: 1.5 }} placeholder="Email" />
        <p className="text-xs font-medium" style={{ color: ERROR }}>This field is required</p>
      </div>
    )},
    { label: "Import failure card", content: (
      <div className="mx-2 p-3 rounded-xl border" style={{ backgroundColor: `${ERROR}08`, borderColor: `${ERROR}40` }}>
        <div className="flex items-start gap-2">
          <AlertCircle size={16} style={{ color: ERROR }} className="flex-shrink-0 mt-0.5" />
          <div>
            <div className="text-xs font-semibold" style={{ color: ERROR }}>Could not read file</div>
            <div className="text-xs mt-0.5" style={{ color: TEXT_SECONDARY }}>File may be corrupted or too large (max 15 MB).</div>
            <button className="text-xs font-semibold mt-1" style={{ color: TEAL }}>Try again</button>
          </div>
        </div>
      </div>
    )},
  ];

  return (
    <div className="flex flex-col flex-1 overflow-hidden">
      <PushedBar title="UI States reference" onBack={onBack} />
      <div className="p-8 overflow-y-auto flex-1">
        <div className="max-w-4xl space-y-10">
          {/* Empty states */}
          <div>
            <h2 className="font-bold text-lg mb-4" style={{ color: NAVY }}>Empty states <span className="text-sm font-normal ml-1" style={{ color: TEXT_SECONDARY }}>(8)</span></h2>
            <div className="grid grid-cols-2 gap-4">
              {emptyStates.map(({ icon, title, subtitle }) => (
                <Card key={title} className="text-center">
                  <EmptyState icon={icon} title={title} subtitle={subtitle} />
                </Card>
              ))}
            </div>
          </div>

          {/* Loading states */}
          <div>
            <h2 className="font-bold text-lg mb-4" style={{ color: NAVY }}>Loading states <span className="text-sm font-normal ml-1" style={{ color: TEXT_SECONDARY }}>(4)</span></h2>
            <div className="grid grid-cols-2 gap-4">
              {loadingStates.map(({ label, content }) => (
                <Card key={label}>
                  <div className="text-xs font-semibold mb-2" style={{ color: TEXT_SECONDARY }}>{label}</div>
                  {content}
                </Card>
              ))}
            </div>
          </div>

          {/* Error states */}
          <div>
            <h2 className="font-bold text-lg mb-4" style={{ color: NAVY }}>Error states <span className="text-sm font-normal ml-1" style={{ color: TEXT_SECONDARY }}>(3)</span></h2>
            <div className="grid grid-cols-3 gap-4">
              {errorStates.map(({ label, content }) => (
                <Card key={label}>
                  <div className="text-xs font-semibold mb-3" style={{ color: TEXT_SECONDARY }}>{label}</div>
                  {content}
                </Card>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════
   NOTIFICATIONS
═══════════════════════════════════════════ */

const NOTIF_META: Record<string, { icon: React.ElementType; color: string }> = {
  registration: { icon: UserCheck, color: "#7A4FBF" },
  session:      { icon: Calendar,  color: TEAL },
  grading:      { icon: Award,     color: SUCCESS },
};

function NotificationsScreen({ role, onBack }: { role: Role; onBack: () => void; push: (s: Screen) => void }) {
  const days = ["Today", "Yesterday", "Dec 20"];
  return (
    <div className="flex flex-col flex-1 overflow-hidden">
      <PushedBar title="Notifications" onBack={onBack} />
      <div className="p-8 overflow-y-auto flex-1">
        <div className="max-w-lg space-y-6">
          {notifications.length === 0
            ? <Card><EmptyState icon={Bell} title="No notifications" subtitle="You're all caught up." /></Card>
            : days.map(day => {
              const items = notifications.filter(n => n.day === day);
              if (!items.length) return null;
              return (
                <div key={day}>
                  <div className="text-xs font-semibold uppercase tracking-wider mb-2" style={{ color: TEXT_SECONDARY }}>{day}</div>
                  <div className="space-y-2">
                    {items.map(n => {
                      const meta = NOTIF_META[n.kind] ?? NOTIF_META.session;
                      const Icon = meta.icon;
                      return (
                        <Card key={n.id} onClick={() => {}} className="flex items-start gap-3 !p-3"
                          >
                          <div className="w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0" style={{ backgroundColor: `${meta.color}18` }}>
                            <Icon size={16} style={{ color: meta.color }} />
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2">
                              <span className="text-sm font-semibold" style={{ color: TEXT_PRIMARY }}>{n.title}</span>
                              {!n.read && <span className="w-2 h-2 rounded-full flex-shrink-0" style={{ backgroundColor: TEAL }} />}
                            </div>
                            <div className="text-xs mt-0.5" style={{ color: TEXT_SECONDARY }}>{n.body}</div>
                            <div className="text-xs mt-0.5" style={{ color: TEXT_SECONDARY }}>{n.time}</div>
                          </div>
                          <ChevronRight size={15} style={{ color: TEXT_SECONDARY }} className="flex-shrink-0" />
                        </Card>
                      );
                    })}
                  </div>
                </div>
              );
            })}
        </div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════
   ADMIN SCREENS
═══════════════════════════════════════════ */

const ADMIN_PURPLE = "#7A4FBF";

function AdminDashboard({ push }: { push: (s: Screen) => void }) {
  const stats = [
    { label: "Total users", value: "24", icon: Users, color: ADMIN_PURPLE },
    { label: "Active murid", value: "18", icon: UserCheck, color: TEAL },
    { label: "Exercises", value: String(exercises.length), icon: BookOpen, color: NAVY },
    { label: "Income / mo", value: "$10.6k", icon: DollarSign, color: SUCCESS },
  ];
  return (
    <div className="p-8 overflow-y-auto flex-1">
      <div className="max-w-5xl space-y-6">
        <div className="grid grid-cols-4 gap-4">
          {stats.map(({ label, value, icon: Icon, color }) => (
            <Card key={label} className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0" style={{ backgroundColor: `${color}18` }}>
                <Icon size={18} style={{ color }} />
              </div>
              <div>
                <div className="font-bold text-2xl leading-none" style={{ color: NAVY }}>{value}</div>
                <div className="text-xs mt-0.5" style={{ color: TEXT_SECONDARY }}>{label}</div>
              </div>
            </Card>
          ))}
        </div>

        <div className="grid grid-cols-3 gap-6">
          <div className="col-span-2 space-y-6">
            <Card>
              <SectionHeader title="New students / month" />
              <div className="h-32">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={monthlyStudents.map(d => ({ ...d, fill: TEAL }))} barSize={26}>
                    <XAxis dataKey="m" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: TEXT_SECONDARY }} />
                    <YAxis hide />
                    <Bar dataKey="v" radius={[4,4,0,0]} isAnimationActive={false} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </Card>
            <div>
              <SectionHeader title="Needs attention" action={<span className="px-2 py-0.5 rounded-full text-xs font-bold text-white" style={{ backgroundColor: ERROR }}>2</span>} />
              <div className="space-y-3">
                <Card className="flex items-center gap-3 !p-3" onClick={() => push({ type: "studentDetail", studentId: 4 })}>
                  <div className="w-1 self-stretch rounded-full" style={{ backgroundColor: ERROR }} />
                  <Ticket size={18} style={{ color: ERROR }} />
                  <div className="flex-1 min-w-0"><div className="text-sm font-semibold" style={{ color: TEXT_PRIMARY }}>Ahmad Hassan — voucher depleted</div><div className="text-xs" style={{ color: TEXT_SECONDARY }}>0 sessions remaining</div></div>
                  <ChevronRight size={16} style={{ color: TEXT_SECONDARY }} />
                </Card>
                <Card className="flex items-center gap-3 !p-3">
                  <div className="w-1 self-stretch rounded-full" style={{ backgroundColor: TEAL }} />
                  <Ticket size={18} style={{ color: TEAL }} />
                  <div className="flex-1 min-w-0"><div className="text-sm font-semibold" style={{ color: TEXT_PRIMARY }}>Priya Sharma — low balance</div><div className="text-xs" style={{ color: TEXT_SECONDARY }}>2 sessions remaining</div></div>
                  <ChevronRight size={16} style={{ color: TEXT_SECONDARY }} />
                </Card>
              </div>
            </div>
          </div>
          <div className="space-y-6">
            <Card>
              <SectionHeader title="Quick actions" />
              <div className="space-y-2">
                <NavyBtn full onClick={() => push({ type: "exerciseForm" })}><div className="flex items-center gap-2 justify-center"><Plus size={14} />New exercise</div></NavyBtn>
                <NavyBtn full onClick={() => push({ type: "classForm" })}><div className="flex items-center gap-2 justify-center"><Calendar size={14} />New class</div></NavyBtn>
              </div>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
}

function AdminUsers({ push }: { push: (s: Screen) => void }) {
  const [rows, setRows] = useState(adminUsers);
  const [search, setSearch] = useState("");
  const filtered = rows.filter(u => u.name.toLowerCase().includes(search.toLowerCase()));
  const toggle = (id: number) => setRows(rs => rs.map(u => u.id === id ? { ...u, active: !u.active } : u));
  return (
    <div className="p-8 overflow-y-auto flex-1">
      <div className="max-w-4xl space-y-4">
        <div className="flex items-center gap-3">
          <div className="relative flex-1 max-w-sm">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2" style={{ color: TEXT_SECONDARY }} />
            <input type="text" placeholder="Search users…" value={search} onChange={e => setSearch(e.target.value)}
              className="w-full pl-9 pr-4 py-2 rounded-lg border bg-white text-sm outline-none" style={{ borderColor: BORDER, fontSize: 13 }} />
          </div>
          <div className="flex-1" />
          <NavyBtn><div className="flex items-center gap-1.5"><Plus size={13} />New user</div></NavyBtn>
        </div>
        <Card className="!p-0 overflow-hidden">
          <div className="grid text-xs font-bold px-4 py-3 border-b"
            style={{ gridTemplateColumns: "2fr 80px 100px 90px 90px", color: TEXT_SECONDARY, borderColor: BORDER, backgroundColor: `${NAVY}08` }}>
            <span>Name</span><span>Role</span><span>Joined</span><span>Status</span><span></span>
          </div>
          {filtered.map((u, i) => (
            <div key={u.id} className="grid items-center px-4 py-3 border-b last:border-0 text-sm"
              style={{ gridTemplateColumns: "2fr 80px 100px 90px 90px", borderColor: BORDER, backgroundColor: i % 2 === 0 ? "#fff" : `${SURFACE}88` }}>
              <div className="flex items-center gap-2.5">
                <Avatar initials={u.initials} size={34} color={u.role === "Murid" ? TEAL : u.role === "Guru" ? NAVY : ADMIN_PURPLE} />
                <div className="min-w-0"><div className="font-semibold text-sm truncate" style={{ color: TEXT_PRIMARY }}>{u.name}</div><div className="text-xs truncate" style={{ color: TEXT_SECONDARY }}>{u.email}</div></div>
              </div>
              <span className="text-xs font-semibold px-2 py-0.5 rounded-full w-fit" style={{ backgroundColor: `${u.role === "Guru" ? NAVY : TEAL}15`, color: u.role === "Guru" ? NAVY : TEAL }}>{u.role}</span>
              <span className="text-xs" style={{ color: TEXT_SECONDARY }}>{u.joined}</span>
              <span className="text-xs font-semibold" style={{ color: u.active ? SUCCESS : TEXT_SECONDARY }}>{u.active ? "Active" : "Inactive"}</span>
              <div className="flex justify-end">
                <button onClick={() => toggle(u.id)}
                  className="text-xs font-semibold px-2.5 py-1 rounded-full transition-all"
                  style={{ backgroundColor: u.active ? "#fff" : `${SUCCESS}18`, color: u.active ? ERROR : SUCCESS, border: `1px solid ${u.active ? ERROR : SUCCESS}` }}>
                  {u.active ? "Deactivate" : "Activate"}
                </button>
              </div>
            </div>
          ))}
        </Card>
      </div>
    </div>
  );
}

function AdminVouchers() {
  const [issueOpen, setIssueOpen] = useState(false);
  const pill: Record<string, { bg: string; color: string; label: string }> = {
    active:   { bg: `${SUCCESS}18`, color: SUCCESS,        label: "Active" },
    low:      { bg: `${YELLOW}25`, color: "#8A6D00",       label: "Low balance" },
    depleted: { bg: `${ERROR}15`,  color: ERROR,           label: "Depleted" },
    unissued: { bg: "#F0F0F3",     color: TEXT_SECONDARY,  label: "Unissued" },
  };
  return (
    <div className="p-8 overflow-y-auto flex-1">
      {issueOpen && (
        <Modal onClose={() => setIssueOpen(false)} wide>
          <div className="font-bold text-lg mb-4" style={{ color: NAVY }}>Issue voucher</div>
          <div className="space-y-4">
            <div>
              <label className="block text-xs font-semibold mb-1" style={{ color: TEXT_PRIMARY }}>Session package</label>
              <div className="flex gap-2">
                {["8 sessions", "16 sessions"].map(o => (
                  <button key={o} className="flex-1 py-2 rounded-lg border text-sm font-semibold" style={{ borderColor: BORDER, color: TEXT_SECONDARY }}>{o}</button>
                ))}
              </div>
            </div>
            <div>
              <label className="block text-xs font-semibold mb-1" style={{ color: TEXT_PRIMARY }}>Assign to murid</label>
              <select className="w-full px-3 py-2.5 rounded-lg border bg-white text-sm outline-none" style={{ borderColor: BORDER }}>
                <option>Unassigned</option>
                {students.map(s => <option key={s.id}>{s.name}</option>)}
              </select>
            </div>
            <div className="flex items-center gap-2 p-3 rounded-lg" style={{ backgroundColor: SURFACE }}>
              <Info size={14} style={{ color: TEXT_SECONDARY }} />
              <span className="text-xs" style={{ color: TEXT_SECONDARY }}>Manual issuance only. Payment is handled offline.</span>
            </div>
          </div>
          <div className="flex gap-3 mt-5"><OutlineBtn onClick={() => setIssueOpen(false)}>Cancel</OutlineBtn><NavyBtn onClick={() => setIssueOpen(false)}>Issue voucher</NavyBtn></div>
        </Modal>
      )}
      <div className="max-w-4xl space-y-4">
        <div className="flex justify-end"><NavyBtn onClick={() => setIssueOpen(true)}><div className="flex items-center gap-1.5"><Plus size={13} />Issue voucher</div></NavyBtn></div>
        <Card className="!p-0 overflow-hidden">
          <div className="grid text-xs font-bold px-4 py-3 border-b"
            style={{ gridTemplateColumns: "1.4fr 1fr 1.2fr 100px 90px", color: TEXT_SECONDARY, borderColor: BORDER, backgroundColor: `${NAVY}08` }}>
            <span>Code</span><span>Package</span><span>Issued to</span><span>Remaining</span><span>Status</span>
          </div>
          {vouchers.map((v, i) => {
            const p = pill[v.status] ?? pill.active;
            return (
              <div key={v.id} className="grid items-center px-4 py-3 border-b last:border-0 text-sm"
                style={{ gridTemplateColumns: "1.4fr 1fr 1.2fr 100px 90px", borderColor: BORDER, backgroundColor: v.status === "low" || v.status === "depleted" ? `${YELLOW}0A` : i % 2 === 0 ? "#fff" : `${SURFACE}88` }}>
                <span className="font-mono text-xs font-semibold" style={{ color: NAVY }}>{v.code}</span>
                <span className="text-xs" style={{ color: TEXT_SECONDARY }}>{v.type}</span>
                <span className="text-xs" style={{ color: TEXT_PRIMARY }}>{v.issuedTo ?? "—"}</span>
                <span className="text-xs font-semibold" style={{ color: v.remaining <= 2 ? ERROR : TEXT_PRIMARY }}>{v.remaining} left</span>
                <span className="text-xs font-semibold px-2 py-0.5 rounded-full w-fit" style={{ backgroundColor: p.bg, color: p.color }}>{p.label}</span>
              </div>
            );
          })}
        </Card>
      </div>
    </div>
  );
}

function AdminReports() {
  const [loading, setLoading] = useState(false);
  const [hskFilter, setHskFilter] = useState<number | null>(null);
  const bands = [
    { label: "Beginner (HSK 1–2)",     count: students.filter(s => s.hsk <= 2).length, color: TEAL },
    { label: "Intermediate (HSK 3–4)", count: students.filter(s => s.hsk >= 3 && s.hsk <= 4).length, color: NAVY },
    { label: "Advanced (HSK 5–6)",     count: students.filter(s => s.hsk >= 5).length, color: ADMIN_PURPLE },
  ];
  const activeStudents = students.filter(s => hskFilter == null || s.hsk === hskFilter);

  if (loading) {
    return (
      <div className="flex-1 flex flex-col items-center justify-center">
        <div className="w-8 h-8 rounded-full border-2 border-t-transparent animate-spin" style={{ borderColor: TEAL, borderTopColor: "transparent" }} />
        <span className="text-sm mt-3" style={{ color: TEXT_SECONDARY }}>Loading reports…</span>
      </div>
    );
  }

  return (
    <div className="p-8 overflow-y-auto flex-1">
      <div className="max-w-5xl space-y-6">
        <div className="flex justify-end">
          <OutlineBtn onClick={() => { setLoading(true); setTimeout(() => setLoading(false), 900); }}>Refresh</OutlineBtn>
        </div>

        {/* P0 trends */}
        <div className="grid grid-cols-2 gap-6">
          <Card>
            <SectionHeader title="New students / month" />
            <div className="h-32">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={monthlyStudents.map(d => ({ ...d, fill: TEAL }))} barSize={24}>
                  <XAxis dataKey="m" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: TEXT_SECONDARY }} />
                  <YAxis hide /><Bar dataKey="v" radius={[4,4,0,0]} isAnimationActive={false} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </Card>
          <Card>
            <SectionHeader title="Income / month ($k)" />
            <div className="h-32">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={monthlyIncome.map(d => ({ ...d, fill: SUCCESS }))} barSize={24}>
                  <XAxis dataKey="m" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: TEXT_SECONDARY }} />
                  <YAxis hide /><Bar dataKey="v" radius={[4,4,0,0]} isAnimationActive={false} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </Card>
        </div>

        {/* Grade distribution */}
        <Card>
          <SectionHeader title="Grade distribution" />
          <div className="grid grid-cols-3 gap-4">
            {bands.map(b => (
              <div key={b.label} className="p-4 rounded-xl text-center" style={{ backgroundColor: `${b.color}0D`, border: `1px solid ${b.color}30` }}>
                <div className="font-bold text-3xl" style={{ color: b.color }}>{b.count}</div>
                <div className="text-xs mt-1" style={{ color: TEXT_SECONDARY }}>{b.label}</div>
              </div>
            ))}
          </div>
        </Card>

        {/* Active student list w/ HSK filter */}
        <Card>
          <div className="flex items-center justify-between mb-3">
            <span className="font-bold text-sm" style={{ color: NAVY }}>Active students</span>
            <div className="flex gap-1">
              <button onClick={() => setHskFilter(null)} className="px-2.5 py-1 rounded-full text-xs font-semibold" style={{ backgroundColor: hskFilter == null ? NAVY : "#fff", color: hskFilter == null ? "#fff" : TEXT_SECONDARY, border: `1px solid ${hskFilter == null ? NAVY : BORDER}` }}>All</button>
              {[1,2,3,4,5].map(l => (
                <button key={l} onClick={() => setHskFilter(l)} className="px-2.5 py-1 rounded-full text-xs font-semibold" style={{ backgroundColor: hskFilter === l ? NAVY : "#fff", color: hskFilter === l ? "#fff" : TEXT_SECONDARY, border: `1px solid ${hskFilter === l ? NAVY : BORDER}` }}>HSK {l}</button>
              ))}
            </div>
          </div>
          {activeStudents.length === 0
            ? <EmptyState icon={Users} title="No students" subtitle="No students at this HSK level yet." />
            : <div className="space-y-2">
              {activeStudents.map(s => (
                <div key={s.id} className="flex items-center gap-2 py-1.5 border-b last:border-0" style={{ borderColor: BORDER }}>
                  <Avatar initials={s.initials} size={30} />
                  <span className="text-sm font-medium flex-1" style={{ color: TEXT_PRIMARY }}>{s.name}</span>
                  <HskBadge level={s.hsk} />
                  <span className="text-xs w-16 text-right" style={{ color: TEXT_SECONDARY }}>avg {s.score}%</span>
                </div>
              ))}
            </div>}
        </Card>

        {/* P1 — voucher balance */}
        <Card>
          <SectionHeader title="Voucher / session balance" />
          <div className="space-y-2">
            {vouchers.filter(v => v.issuedTo).map(v => {
              const low = v.remaining <= 2;
              return (
                <div key={v.id} className="flex items-center gap-3 py-1.5 border-b last:border-0" style={{ borderColor: BORDER }}>
                  <span className="text-sm font-medium flex-1" style={{ color: TEXT_PRIMARY }}>{v.issuedTo}</span>
                  <span className="font-mono text-xs" style={{ color: TEXT_SECONDARY }}>{v.code}</span>
                  <span className="text-xs font-semibold px-2 py-0.5 rounded-full" style={{ backgroundColor: low ? `${ERROR}15` : `${SUCCESS}18`, color: low ? ERROR : SUCCESS }}>{v.remaining} left</span>
                </div>
              );
            })}
          </div>
        </Card>

        {/* P1 — completion rate */}
        <Card>
          <SectionHeader title="Exercise completion rate" />
          <div className="space-y-3">
            {exercises.filter(e => e.status === "published").map(e => {
              const rate = e.assigned ? Math.min(100, 40 + e.id * 12) : 0;
              const avg = 70 + e.id * 3;
              return (
                <div key={e.id}>
                  <div className="flex items-center justify-between text-xs mb-1">
                    <span className="font-medium" style={{ color: TEXT_PRIMARY }}>{e.title}</span>
                    <span style={{ color: TEXT_SECONDARY }}>{rate}% done · avg {avg}%</span>
                  </div>
                  <div className="h-2 rounded-full overflow-hidden" style={{ backgroundColor: BORDER }}>
                    <div className="h-full rounded-full" style={{ width: `${rate}%`, backgroundColor: TEAL }} />
                  </div>
                </div>
              );
            })}
          </div>
        </Card>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════
   ROOT APP
═══════════════════════════════════════════ */

export default function App() {
  const isMobile = useIsMobile();
  const [authed, setAuthed] = useState(false);
  const [showHandoff, setShowHandoff] = useState(false);
  const [role, setRole] = useState<Role>("guru");
  const [adminTab, setAdminTab] = useState<AdminTab>("dashboard");
  const [guruTab, setGuruTab] = useState<GuruTab>("dashboard");
  const [muridTab, setMuridTab] = useState<MuridTab>("home");
  const [stack, setStack] = useState<Screen[]>([]);
  const [unread, setUnread] = useState(3);

  const push = (s: Screen) => setStack(ss => [...ss, s]);
  const pop  = () => setStack(ss => ss.slice(0, -1));
  const current = stack[stack.length - 1];
  const openNotifications = () => { setUnread(0); push({ type: "notifications" }); };

  const handleLogin = (r: Role, firstTime = false) => {
    setRole(r);
    setAuthed(true);
    if (firstTime) setStack([{ type: "completeProfile", role: r }]);
  };
  const handleSignOut = () => { setAuthed(false); setStack([]); };
  const handleRoleSwitch = () => {
    setRole(r => r === "admin" ? "guru" : r === "guru" ? "murid" : "admin");
    setStack([]);
  };

  if (!authed) return <AuthScreen onLogin={handleLogin} />;
  if (showHandoff) return (
    <div className="h-screen overflow-y-auto">
      <div className="sticky top-0 z-50 flex justify-end px-6 py-2 bg-white border-b" style={{ borderColor: "#E2E5EB" }}>
        <button onClick={() => setShowHandoff(false)}
          className="flex items-center gap-2 px-3 py-1.5 rounded-lg text-sm font-semibold border hover:bg-gray-50"
          style={{ borderColor: "#E2E5EB", color: "#1B2A4A" }}>
          ← Back to app
        </button>
      </div>
      <Handoff />
    </div>
  );

  const tabLabel: Record<string, string> = {
    dashboard: "Dashboard", students: "Students", exercises: "Exercises",
    classes: "Classes", profile: "Profile", home: "Home",
    myClasses: "My Classes", lessons: "Lessons", progress: "Progress",
    users: "Users", vouchers: "Vouchers", reports: "Reports",
  };
  const activeTab = role === "admin" ? adminTab : role === "guru" ? guruTab : muridTab;
  const nav = role === "admin" ? adminNav : role === "guru" ? guruNav : muridNav;
  const setTab = (t: string) => {
    if (role === "admin") setAdminTab(t as AdminTab);
    else if (role === "guru") setGuruTab(t as GuruTab);
    else setMuridTab(t as MuridTab);
    setStack([]);
  };

  // Only Admin can create exercises/classes from the header; Guru manages classes only.
  const topAction = current ? null
    : role === "admin" && adminTab === "exercises" ? <NavyBtn small onClick={() => push({ type: "exerciseForm" })}><div className="flex items-center gap-1"><Plus size={12} />New exercise</div></NavyBtn>
    : (role === "admin" || role === "guru") && (adminTab === "classes" || guruTab === "classes") && (role === "admin" ? adminTab === "classes" : guruTab === "classes")
      ? <NavyBtn small onClick={() => push({ type: "classForm" })}><div className="flex items-center gap-1"><Plus size={12} />New class</div></NavyBtn>
    : null;

  const renderPushed = (s: Screen) => {
    switch (s.type) {
      case "studentDetail":      return <StudentDetailScreen studentId={s.studentId} onBack={pop} />;
      case "exerciseForm":       return <ExerciseFormScreen exerciseId={s.exerciseId} onBack={pop} push={push} />;
      case "importReview":       return <ImportReviewScreen exerciseId={s.exerciseId} onBack={pop} />;
      case "studentClassDetail": return <StudentClassDetailScreen classId={s.classId} onBack={pop} />;
      case "completeProfile":    return <CompleteProfileScreen role={s.role} onDone={pop} />;
      case "classForm":          return <ClassFormScreen classId={s.classId} onBack={pop} />;
      case "classDetail":        return <ClassDetailScreen classId={s.classId} onBack={pop} canAttendance={role === "guru" || role === "admin"} />;
      case "exercisePlay":       return <ExercisePlayScreen exerciseId={s.exerciseId} onBack={pop} />;
      case "lessonDetail":       return <LessonDetailScreen lessonNum={s.lessonNum} onBack={pop} push={push} />;
      case "quiz":               return <QuizScreen lessonNum={s.lessonNum} onBack={pop} push={push} />;
      case "quizScore":          return <QuizScoreScreen lessonNum={s.lessonNum} score={s.score} total={s.total} onBack={pop} />;
      case "notifications":      return <NotificationsScreen role={role} onBack={pop} push={push} />;
    }
  };

  const adminContent = <>
    {adminTab === "dashboard" && <AdminDashboard push={push} />}
    {adminTab === "users"     && <AdminUsers push={push} />}
    {adminTab === "exercises" && <TeacherExercises push={push} fullCrud />}
    {adminTab === "classes"   && <TeacherClasses push={push} crossTeacher />}
    {adminTab === "vouchers"  && <AdminVouchers />}
    {adminTab === "reports"   && <AdminReports />}
    {adminTab === "profile"   && <TeacherProfile onSignOut={handleSignOut} push={push} onHandoff={() => setShowHandoff(true)} roleLabel="Admin" />}
  </>;

  const guruContent = <>
    {guruTab === "dashboard" && <TeacherDashboard push={push} />}
    {guruTab === "students"  && <TeacherStudents push={push} />}
    {guruTab === "classes"   && <TeacherClasses push={push} />}
    {guruTab === "exercises" && <TeacherExercises push={push} />}
    {guruTab === "profile"   && <TeacherProfile onSignOut={handleSignOut} push={push} onHandoff={() => setShowHandoff(true)} roleLabel="Guru" />}
  </>;

  const muridContent = <>
    {muridTab === "home"      && <StudentHome push={push} />}
    {muridTab === "myClasses" && <StudentMyClasses push={push} />}
    {muridTab === "lessons"   && <StudentLessons push={push} />}
    {muridTab === "progress"  && <StudentProgress />}
    {muridTab === "profile"   && <StudentProfile onSignOut={handleSignOut} />}
  </>;

  const tabContent = current ? renderPushed(current)
    : role === "admin" ? adminContent
    : role === "guru"  ? guruContent
    : muridContent;

  /* ── Mobile layout ── */
  if (isMobile) {
    const showFab = !current && (
      (role === "admin" && (adminTab === "exercises" || adminTab === "classes")) ||
      (role === "guru" && guruTab === "classes")
    );
    const fabIsExercise = role === "admin" && adminTab === "exercises";
    return (
      <div className="flex flex-col h-screen w-full overflow-hidden" style={{ fontFamily: "'Plus Jakarta Sans', sans-serif", backgroundColor: SURFACE }}>
        {!current && (
          <div className="flex items-center justify-between px-4 h-14 flex-shrink-0 text-white" style={{ backgroundColor: NAVY }}>
            <div className="flex items-center gap-2">
              <img src={logoPencil} alt="Easy Study mascot" className="object-contain flex-shrink-0" style={{ height: 28, width: "auto" }} />
              <div>
                <div className="font-bold text-white text-sm leading-tight">Easy Study</div>
                <div className="text-xs leading-none" style={{ color: "rgba(255,255,255,0.5)", fontFamily: "'Noto Sans SC', sans-serif" }}>易华文教中心</div>
              </div>
            </div>
            <span className="font-bold text-base">{tabLabel[activeTab]}</span>
            <button onClick={openNotifications} className="relative p-1.5">
              <Bell size={20} color="white" />
              {unread > 0 && <span className="absolute -top-0.5 -right-0.5 min-w-4 h-4 px-1 flex items-center justify-center rounded-full text-white font-bold" style={{ backgroundColor: ERROR, fontSize: 9 }}>{unread}</span>}
            </button>
          </div>
        )}

        <div className="flex-1 overflow-hidden flex flex-col relative">
          {tabContent}
          {showFab && (
            <button
              onClick={() => push(fabIsExercise ? { type: "exerciseForm" } : { type: "classForm" })}
              className="absolute bottom-20 right-4 flex items-center gap-2 px-4 py-3 rounded-2xl text-white font-semibold text-sm shadow-lg"
              style={{ backgroundColor: NAVY }}>
              <Plus size={18} />{fabIsExercise ? "New exercise" : "New class"}
            </button>
          )}
        </div>

        {!current && (
          <div className="flex border-t bg-white flex-shrink-0 overflow-x-auto" style={{ borderColor: BORDER, height: 64 }}>
            {nav.map(({ id, label, icon: Icon }) => {
              const active = activeTab === id;
              return (
                <button key={id} onClick={() => setTab(id)}
                  className="flex-1 min-w-16 flex flex-col items-center justify-center gap-0.5 transition-all"
                  style={{ color: active ? TEAL : TEXT_SECONDARY }}>
                  <div className="relative">
                    {active && <div className="absolute inset-0 -m-2 rounded-full" style={{ backgroundColor: `${TEAL}18` }} />}
                    <Icon size={20} style={{ position: "relative" }} />
                  </div>
                  <span style={{ fontSize: 10, fontWeight: active ? 600 : 400 }}>{label}</span>
                </button>
              );
            })}
          </div>
        )}
      </div>
    );
  }

  /* ── Desktop layout ── */
  return (
    <div className="flex h-screen w-full overflow-hidden" style={{ fontFamily: "'Plus Jakarta Sans', sans-serif", backgroundColor: SURFACE }}>
      <Sidebar activeTab={activeTab} setTab={setTab} nav={nav} role={role} onSignOut={handleSignOut} onRoleSwitch={handleRoleSwitch} />
      <div className="flex flex-col flex-1 overflow-hidden">
        {!current && <TopBar title={tabLabel[activeTab] ?? "Easy Study"} action={topAction} role={role} unread={unread} onBell={openNotifications} />}
        {tabContent}
      </div>
    </div>
  );
}
