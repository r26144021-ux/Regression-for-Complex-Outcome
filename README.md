# cluster-survival-r

使用 **R 與繁體中文**，透過對話完成 Cox、混合效應模型與 GEE 分析的 Skill，以及配套的報告與示範。

流程：**提供資料與目的 → 確認變數與設計 → 資料探索 → 建議模型 → 確認設定 → R 分析與診斷 → 解釋結果**。

## Skill 分析流程

| 階段 | 內容 |
|---|---|
| 1. 接收資料與分析目的 | 接受 CSV、Excel 或 R 內建資料；了解研究問題、變數說明及每列意義；只追問尚未清楚的資訊 |
| 2. 基本資料檢查 | 核對型別、編碼、缺失與範圍；檢查事件／設限、群數、群大小、訪視及重複 id-time；記錄資料處理 |
| 3. 建模前探索（EDA） | 依目的選擇摘要與圖表，例如存活曲線、個體軌跡或分組事件比例；說明發現與對設定的影響，不固定所有資料使用同一套圖 |
| 4. 適用性與模型建議 | 依事件時間或群集結構、結果尺度及研究目的評估 Cox、混合效應或 GEE；不適用時說明並停止 |
| 5. 確認模型設定 | 確認公式、參考組、事件映射、family／link、隨機效果或工作相關結構；語意清楚時可接受整組建議設定 |
| 6. R 估計與模型診斷 | 執行已確認模型，提供效果量與區間及適用檢定；依模型檢查 PH、殘差、收斂、隨機效果或 GEE 群數與推論條件 |
| 7. 結果解釋與結論 | 整合探索、估計與診斷回答研究問題，指出具體限制；需要時討論設定調整或敏感度分析 |
| 8. 報告輸出（可選） | 使用者需要時產生 QMD 與 HTML，保留相關 EDA、選模理由、R 程式、結果、檢定與圖形解釋；檢查中文及內容後提供 |

圖表與版面可彈性調整；同資料、同前處理、同模型與同推論設定的數值應一致。只有實際完成的項目才列入成果。

## 涵蓋範圍

| 方法 | 主要用途 |
|---|---|
| Cox 比例風險模型 | 分析事件發生時間及右設限資料 |
| 混合效應模型 | 分析群集／重複測量，保留個體或群組差異；包含 LMM、GLMM 與受限的 NLMM 路徑 |
| GEE | 考慮群內相關，估計母體平均關聯 |

Skill 不以最低 p 值自動選模型。群集資料先確認個體／群組差異或整體平均的研究目標，再提出建議；關鍵資訊不清楚時會追問。

## 交付資料夾內容

| 檔案／資料夾 | 用途 |
|---|---|
| `slides.html` | 上台展示的捲動網頁；圖片已內嵌，可單獨複製使用 |
| `slides.md` | 正式報告的可編輯文字來源 |
| `cluster-survival-r/` | Skill 本體 |
| `cluster-survival-r.zip` | 只包含 Skill 的壓縮檔，第一層為同名資料夾 |
| `demo-results/` | 實際示範輸出、CSV、圖與版本紀錄 |
| `figures/` | 報告流程圖 |
| `cluster-survival-r-project.zip` | 專案資料：slides、Skill、分析報告、README 與示範結果 |


## Skill 資料夾結構

```text
cluster-survival-r/
├── SKILL.md                       AI 的啟動條件、互動與分析規則
├── references/
│   ├── decision-tree.md           候選模型判斷與必要澄清
│   ├── eda.md                     建模前探索與彈性圖表原則
│   ├── models.md                  方法、假設、診斷與來源
│   ├── small-sample-gee.md        GEE 少群推論與修正限制
│   └── demo-dialogue.md           互動示例
└── scripts/
    ├── workflow.R                 讀檔、摘要與基本建模函數
    ├── demo.R                     Cox、LMM、GEE 的可重現示範
    ├── demo-mixed-types.R         GLMM、NLMM 補充示範
    └── gee-small-sample.R         受限的 MD 小樣本修正路徑
```

`README.md` 給使用者閱讀；`SKILL.md` 給 AI 作為工作指引。

## 開始使用

### 1. 讓使用工具讀取 Skill

解壓縮 `cluster-survival-r.zip`，依所用 AI 工具的 Skill 安裝方式加入整個 `cluster-survival-r` 資料夾。不同工具的安裝位置與啟動方式不同，本交付不會自動安裝到全域環境。

若尚未安裝，可先在能讀取本機檔案的 AI 工具中指定：

> 請讀取 cluster-survival-r/SKILL.md，依照這份 Skill 協助我分析。

只有在工具確實能讀到該檔案及參考資源時，這種方式才可使用。已安裝的副本不會因交付資料夾更新而自動同步，請自行替換新版。

### 2. 提供資料、目的與說明

可提供 CSV、Excel、R data.frame，或內建資料的套件與資料集名稱。建議說明：

- 想回答的研究問題。
- 每列代表一個人、一次訪視或其他單位。
- 結果與解釋變數的名稱、單位、類別編碼。
- 若有重複測量：個體／群組 id 與時間欄位。
- 若為事件時間：時間起點、單位、事件與設限定義。

不確定的部分可以先留空，由 Skill 逐步追問；不必事先知道該選哪個模型。

### 3. 確認模型與設定

AI 說明建議與必要設定後，可接受建議或提出修改。Cox 的分析事件欄統一為數值 **0＝設限、1＝事件**；原始編碼不同時，先確認意義再轉換，不依數值大小猜測。

### 4. 執行與解釋

本 Skill 的統計計算使用 R。可使用已連線的 R 工作階段，或由可執行本機程式的 AI 工具在背景啟動 `Rscript`；後者不需要手動開啟 RStudio。

能讀取 Skill 不等於有 R 執行能力。若沒有可用 R 或執行權限，AI 應提供 R 程式，等使用者執行並回貼輸出後再解釋，不得捏造已執行的數字。

## R 環境與套件

需要 R；若要從終端以 `Rscript` 執行，需能找到其執行檔（加入 PATH 或使用完整路徑）。依分析需求安裝套件，無須每次重裝：

```r
install.packages(
  c("survival", "lme4", "geepack", "readxl", "nlme"),
  repos = "https://cloud.r-project.org"
)
```

示範驗證環境為 R 4.6.1；實際套件版本與執行環境記錄於 `demo-results/` 的紀錄檔，不保證其他版本的數字完全相同。

## 互動示範：Cox

```text
請使用 cluster-survival-r，分析 survival::lung。
我想比較性別與死亡事件時間的關聯。
time 的單位是天；status 1=設限、2=死亡；sex 1=男性、2=女性。
請保留原始 status，另外建立 0/1 事件欄。
先用只含性別的 Cox，男性為參考組，接受 Efron ties 與 95% CI。
請執行並提供 Schoenfeld 殘差檢定、圖及結論。
```

本次示範結果：228 人、165 個死亡事件；女性相對男性 HR 約 0.588，95% CI 約 0.424–0.816，Wald p 約 0.00149；比例風險全域檢定 p 約 0.091。這是未調整其他共變數的關聯，不是因果效果或死亡機率比。

## 直接在 RStudio 重現示範

工作目錄設為含有 `cluster-survival-r/` 的交付資料夾，再執行：

```r
source("cluster-survival-r/scripts/demo.R", encoding = "UTF-8")
source("cluster-survival-r/scripts/demo-mixed-types.R", encoding = "UTF-8")
```

這些程式會在 `demo-results/` 寫入結果；若需保留現有結果，請先備份，或用命令列的第二個參數指定另一個輸出資料夾。

```text
Rscript cluster-survival-r/scripts/demo.R cluster-survival-r my-demo-results
Rscript cluster-survival-r/scripts/demo-mixed-types.R cluster-survival-r my-mixed-results
```

| 內建資料 | 對應示範 |
|---|---|
| `survival::lung` | Cox：性別與事件時間 |
| `lme4::sleepstudy` | LMM：反應時間、天數及個體差異 |
| `geepack::ohio` | GEE：母親吸菸、年齡與喘鳴 |
| `lme4::cbpp` | GLMM：二項事件的群集資料 |
| `datasets::Loblolly` | NLMM：樹高的漸近成長曲線 |

報告範本會先檢查本次 R 的 UTF-8 語系及中文輸出；產生 HTML 後仍需核對中文表格與圖中文字。

## GEE 小樣本功能與限制

小樣本主要看**獨立群數**，不是單純資料列數。基本 `fit_gee()` 在少於 30 群時，預設保留探索性估計及 SE、隱藏未修正 CI／p；30 是提示門檻，不是普遍適用的統計界線。

補充函數 `fit_gee_md()` 提供 MD 變異數修正與係數別 t 推論。目前限定 independence 工作相關結構、Gaussian identity／單欄二元 logit／Poisson log 等條件；自由度 `df` 與理由 `df_reason` 必須依設計明確指定。它不是少群資料的通用自動修正，也不提供多參數聯合檢定。

此路徑另需 `gee`、`matrixcalc`、`geesmv`。本次一般 CRAN 安裝無法取得 geesmv，改用官方封存 1.3；來源及安裝指令見 `references/small-sample-gee.md`。安裝失敗時不能宣稱已完成修正。

## 已驗證與尚未涵蓋

- 三類主示範及 GLMM／NLMM 補充例已實際執行。
- 已檢查錯誤事件編碼、缺失欄位、重複訪視、GEE 排序及 CSV／Excel 讀檔。
- MD 的 Gaussian 20 群模擬例已與獨立矩陣計算核對；這不是對所有設計的型一錯誤與覆蓋率保證。二元及 Poisson 路徑尚未逐一做獨立數值驗證。
- 互動示例是教學整理稿；R 程式測試不等同所有 AI 平台的互動行為驗證。
- NLMM 的現有實作以連續 Gaussian 誤差模型為範圍；更一般的非 Gaussian 非線性、競爭風險、複雜多層 GEE 等需另外評估，不能直接套用基本示範。

方法學來源見正式報告及 Skill 的 `references/`；程式執行紀錄與圖表見 `demo-results/`。

README 整理日期：2026-10-20。

## 新增互動與報告功能
群集資料與重複測量會先辨認層級；不知道選個別差異或整體平均時，可直接描述用途，AI 會用例子與可行性協助。混合效應先分線性／廣義線性（LMM、GLMM）與非線性（NLMM）。
分析完成後可選擇生成 QMD／HTML；規則在 references/report-export.md，範本在 assets/analysis-report.qmd。需 Quarto 與 R/knitr，QMD 需執行並成功轉成 HTML。原分析數據與設定應可由程式重現，不擅自打包敏感資料。

## 完整分析報告示範
`analysis-report.qmd` 與 `analysis-report.html` 為已填入內容的 Cox 示範，R 程式碼與結果直接並列顯示。Skill 內 assets/analysis-report.qmd 仍是供後續分析替換內容的通用範本。HTML 由 Quarto 實際執行 R 後產生，不是只有空白架構。


## 選模範圍與群集角色
一般多元 logistic 不是 GLMM。本 Skill 不自行改跑三類之外的主分析；發現不適用時說明並停止。有醫院、班級、抽樣群或重複測量線索時，主動確認群內相關與群集角色；不需要使用者先說出模型名稱。「比較群集」不代表固定效果授權。完整規則見 references/cluster-roles.md。

分析範例已加入頂部重點摘要與明確選模理由。Cox另含KM／At-risk table、HR森林圖與表觀C-index；GEE另含robust CI邊際預測；LMM呈現模型式、友善變異組成表與按天數的VPC。方法選擇與指標限制見 references/report-visuals.md。
