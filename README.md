<div align="center">

# 🧠 Distilled Minds

> **把世界頂尖思考者的認知操作系統，蒸餾成可安裝的 AI Skill。**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Personas](https://img.shields.io/badge/Personas-10-blue)](#available-personas)
[![Platforms](https://img.shields.io/badge/Platforms-Claude%20%7C%20Copilot%20%7C%20Gemini-purple)](#install)

每個 Persona 都包含：
- 🔬 **原始調研資料**（一手來源：訪談逐字稿、著作、決策記錄）
- 🧠 **蒸餾 Skill**（核心心智模型 × 決策啟發式 × 表達 DNA）

[安裝](#install) · [Persona 列表](#available-personas) · [如何蒸餾新人物](#contribute)

</div>

---

## Available Personas

| Persona | 領域 | 核心框架 | 調研深度 |
|---------|------|---------|---------|
| **Sundar Pichai** | AI 戰略 / 科技治理 | Bold & Responsible · Full Stack AI · AJI 思維 | 6 維度，30+ 一手來源 |
| **黃仁勳 Jensen Huang** | 半導體 / AI 基礎設施 | 痛苦是禮物 · 平台思維 · 傳道式領導 | 6 維度，30+ 一手來源 |
| **蘇姿丰 Lisa Su** | 半導體 / 企業轉型 | 工程事實優先 · 無情的優先排序 · 以執行贏得信任 | 6 維度，25+ 一手來源 |
| **比爾蓋茲 Bill Gates** | 科技 / 全球公衛 | 模型思維 · Think Week · 系統性樂觀 | 6 維度，30+ 一手來源 |
| **史蒂芬·霍金 Stephen Hawking** | 理論物理 / 科普 | 科學民主化 · 邊界即探索起點 · 宇宙時間尺度 | 6 維度，25+ 一手來源 |
| **Warren Buffett** | 價值投資 | 護城河思維 · 能力圈 · 複利人生 | 6 維度，35+ 一手來源 |
| **Charlie Munger** | 多元思維模型 | 逆向思考 · 心智模型格柵 · Lollapalooza 效應 | 6 維度，30+ 一手來源 |
| **Benjamin Graham** | 價值投資奠基 | 安全邊際 · 市場先生 · 防禦性投資 | 6 維度，25+ 一手來源 |
| **Peter Lynch** | 成長股投資 | 投資你所知 · 十倍股 · 業餘優勢 | 6 維度，25+ 一手來源 |
| **Ray Dalio** | 宏觀投資 / 組織設計 | 債務週期 · 極度透明 · 痛苦+反思=進步 | 6 維度，30+ 一手來源 |

---

## Install

### 一鍵安裝（互動式）

```bash
git clone https://github.com/martin-hsu-test/distilled-minds
cd distilled-minds
chmod +x install.sh
./install.sh
```

安裝流程：

```
╔══════════════════════════════════════════════════╗
║       🧠  Distilled Minds · Installer            ║
╚══════════════════════════════════════════════════╝

▶ Available personas:

  [1]  Sundar Pichai      (6 research files)
  [2]  Jensen Huang       (6 research files)
  [3]  Lisa Su            (6 research files)
  [4]  Bill Gates         (6 research files)
  [5]  Stephen Hawking    (6 research files)
  [6]  Warren Buffett     (6 research files)
  [7]  Charlie Munger     (6 research files)
  [8]  Benjamin Graham    (6 research files)
  [9]  Peter Lynch        (6 research files)
  [10] Ray Dalio          (6 research files)
  [a]  Install ALL personas

Select personas (e.g. 1,3,6 or a for all): a

▶ Select target platform:

  [1] Claude Code   (~/.claude/skills/)
  [2] GitHub Copilot CLI  (project skills/)
  [3] Gemini CLI  (~/.gemini/personas/ + GEMINI.md)
  [4] All platforms

Select platform [1-4]: 1

  ✓ Installing...

  Sundar Pichai      → ✓ installed
  Jensen Huang       → ✓ installed
  Lisa Su            → ✓ installed
  Bill Gates         → ✓ installed
  Stephen Hawking    → ✓ installed
  Warren Buffett     → ✓ installed
  Charlie Munger     → ✓ installed
  Benjamin Graham    → ✓ installed
  Peter Lynch        → ✓ installed
  Ray Dalio          → ✓ installed

  Activate a Gemini persona globally?
    [1] Sundar Pichai
    ...
    [s] Skip

  Select [1-10/s]: 1
  ✓ Activated: Sundar Pichai → ~/.gemini/GEMINI.md

✓ Installation complete! (10 personas)
```

### 平台安裝位置

| 平台 | 安裝位置 | 觸發方式 |
|------|---------|---------|
| **Claude Code** | `~/.claude/skills/<name>/SKILL.md` | 觸發詞：「用 XX 的視角」 |
| **GitHub Copilot CLI** | `<project>/skills/<name>/SKILL.md` | 觸發詞：「用 XX 的視角」 |
| **Gemini CLI** | `~/.gemini/personas/<name>.md`（儲存）<br>`~/.gemini/GEMINI.md`（啟用） | 啟動 `gemini` 自動載入；切換：`cp ~/.gemini/personas/<name>.md ~/.gemini/GEMINI.md` |

### 列出可用 Persona

```bash
./install.sh --list
```

---

## Repo 結構

```
distilled-minds/
├── install.sh              # 互動式安裝腳本
├── README.md
└── personas/
    ├── sundar-pichai/
    ├── jensen-huang/
    ├── lisa-su/
    ├── bill-gates/
    ├── stephen-hawking/
    ├── warren-buffett/
    ├── charlie-munger/
    ├── benjamin-graham/
    ├── peter-lynch/
    └── ray-dalio/
        ├── SKILL.md            # 蒸餾後的可運行 Skill
        └── references/
            └── research/       # 原始調研資料（一手來源）
                ├── 01-writings.md
                ├── 02-conversations.md
                ├── 03-expression-dna.md
                ├── 04-external-views.md
                ├── 05-decisions.md
                └── 06-timeline.md
```

---

## 什麼是「蒸餾 Skill」？

一個好的 Persona Skill 不是語錄合集，是**可運行的認知操作系統**：

- 🔭 **心智模型**：他用什麼鏡片看世界？
- ⚡ **決策啟發式**：他面對不確定性時，有哪些快速判斷規則？
- 🎙️ **表達 DNA**：他的語言節奏、高頻詞彙、幽默方式、禁忌表達？
- 🚫 **反模式**：他絕對不會做什麼？
- 🔍 **誠實邊界**：這個 Skill 做不到什麼？

每個維度都基於一手來源，不是二手轉述。

---

## Contribute

想蒸餾新人物？歡迎 PR。

每個新 Persona 需要包含：

```
personas/<name>/
├── SKILL.md        # 蒸餾結果（格式參考現有 Persona）
└── research/       # 至少 3 個調研維度的一手資料
    ├── 01-writings.md
    ├── 02-conversations.md
    └── ...
```

**調研品質標準**：
- 一手來源佔比 ≥ 60%
- 每個心智模型需有 ≥ 2 個一手引用支撐
- 需包含「局限性」欄位（避免盲目崇拜）

---

## License

MIT — 自由使用，歡迎蒸餾更多思想者。
