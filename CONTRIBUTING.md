# Contributing to Distilled Minds

## Persona 目錄規範

每個 Persona 的目錄結構必須完全一致：

```
personas/<slug>/
├── SKILL.md                          # 蒸餾後的可運行 Skill（必要）
└── references/
    └── research/                     # 六維度調研原始資料（必要）
        ├── 01-writings.md            # 著作與系統性長文
        ├── 02-conversations.md       # 播客、訪談、長對話
        ├── 03-expression-dna.md      # 碎片表達、風格 DNA
        ├── 04-external-views.md      # 他者視角與批評
        ├── 05-decisions.md           # 重大決策記錄
        └── 06-timeline.md            # 人物完整時間線
```

**安裝選單顯示**：`install.sh` 會從 [README.md](README.md) 的 persona 表格自動解析「領域」與「核心框架」顯示給使用者，所以新增 persona 時**請務必同步更新 README 表格**（粗體名稱必須與 `get_display_name(slug)` 一致：例如 `richard-feynman` → `**Richard Feynman**`）。

### Slug 命名規則

- 全小寫、以連字號分隔
- 使用英文全名（不用中文、不用縮寫）
- 範例：`jensen-huang`、`warren-buffett`、`stephen-hawking`

### 常見錯誤（請避免）

| ❌ 錯誤 | ✅ 正確 |
|--------|--------|
| `personas/jensen-huang/research/` | `personas/jensen-huang/references/research/` |
| `personas/jensen-huang/07-extra.md`（根目錄散檔） | 放入 `references/research/` |
| `personas/Jensen_Huang/` | `personas/jensen-huang/` |

---

## SKILL.md 格式規範

SKILL.md 必須包含以下區塊（順序固定）：

| 區塊 | 說明 |
|------|------|
| YAML frontmatter | `name`、`description`、觸發詞 |
| 角色扮演規則 | 以「我」的視角；首次使用免責聲明 |
| 回答工作流（Agentic Protocol） | Step 1 問題分類 → Step 2 研究 → Step 3 回答 |
| 身份卡 | 50 字，用該人物語氣寫 |
| 心智模型 | 3–7 個，每個含名稱 / 一句話 / ≥2 個來源 / 局限 |
| 決策啟發式 | 8 條，每條含場景 + 案例 |
| 表達 DNA | 句式 / 詞彙 / 節奏 / 幽默 / 確定性表達 |
| 關鍵時間線 | Markdown 表格 |
| 價值觀與反模式 | 3–5 條核心價值 + 明確反對的行為 |
| 智識譜系 | 受誰影響 → 影響了誰 |
| 誠實邊界 | ≥3 條，包含資訊截止日期 |
| 女娲標誌 | 固定末行（見下） |

**固定末行：**
```
> 本Skill由 [女娲 · Skill造人術](https://github.com/alchaincyf/nuwa-skill) 生成
```

**語言規則：**
- **新增原創 persona**：使用繁體中文。
- **匯入既有作品**（如自 nuwa-skill 等開源專案匯入）：保留原始語言不改寫，以忠於來源；但需在 README 的 persona 清單註明來源。

---

## 品質標準

提交 PR 前，請自行對照：

| 檢查項 | 標準 |
|--------|------|
| 心智模型數量 | 3–7 個 |
| 每個模型有局限性 | 必須寫出失效條件 |
| 誠實邊界 | ≥3 條具體限制 |
| 內在張力 | ≥2 對矛盾（觀點完全一致是造假信號） |
| 一手來源占比 | >50%（本人著作 / 訪談 / 決策記錄） |
| research 檔案數量 | 01–06 全部存在 |
| 表達 DNA 辨識度 | 100 字內能認出是誰 |

---

## 貢獻新 Persona

1. Fork 本 repo
2. 建立目錄：`personas/<slug>/`
3. 完成六維度調研，寫入 `references/research/01-06.md`
4. 依格式規範撰寫 `SKILL.md`
5. 對照品質標準自檢
6. 送出 PR，標題格式：`feat: add <Name> persona`

推薦使用 [女娲 · Skill造人術](https://github.com/alchaincyf/nuwa-skill) 輔助蒸餾流程。
