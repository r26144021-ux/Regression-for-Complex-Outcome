# GEE 的獨立群數與小樣本推論

## 先數對獨立單位
以 K 表獨立群數，N 表觀測列數。20 位獨立病人各 10 次是 K=20、N=200；若病人在 8 家醫院且院內仍相關，不能直接把病人當作完全獨立群來增加 K，需評估最高層相關與設計。報 K、群大小分布、每組群數、結果事件數及模型參數量。叢集試驗應特別看隨機分派層級。

## K<30 可以做嗎？
不是禁止條件，也不是 30 以上就安全。可估計 GEE，但標準 sandwich SE 與常態 z 推論在少群時可能低估變異、使 CI 太窄及型一錯誤偏高。文獻常在少於約 30–40 群時提出警訊；實際表現還取決於群大小不均、槓桿值、事件稀少、相關性、模型複雜度和設計。即使總列數很大也不能抵銷獨立群數過少。

## 對話與選擇
以自然語氣說明：「目前有 20 個獨立群。GEE 可以估計平均關聯，但一般穩健標準誤的小樣本推論可能偏樂觀。你希望先做探索性估計，還是評估適合此設計的小樣本修正？」不向使用者引用 Skill 內部門檻或規則。

可考慮 KC（Kauermann–Carroll）、MD（Mancl–DeRouen）、FG（Fay–Graubard）等 sandwich 偏差修正，並搭配與方法／設計相符的 t／F 參考分布與自由度。不能只把 z 改成 t 就宣稱完成修正；也不能所有情況一律用 K−1 或 K−p。修正適用性需核對軟體、模型 family、相關結構與研究設計，記錄套件版本、修正公式／名稱、自由度與限制。

不要宣稱 geepack 的 std.err="san.se" 已有 KC／MD／FG 修正；其 jackknife 選項也不自動等同上述修正。基本 workflow.R 的 fit_gee 未實作少群修正：K<30 時預設隱藏未修正 CI／p，只保留探索性估計與 SE；30 是保守提示門檻。30–39 群同樣提醒核對推論，仍非安全保證。若要正式少群推論，需另行選定並驗證修正程式，不能把原本結果改標「已修正」。

## 若資訊仍不足
減少不必要參數／過度複雜相關結構，但不是為追求顯著性。若群數極少、組間不平衡或稀疏事件，即使修正也不保證可信；可報探索性效果、描述性分析、設計相符的群層級或隨機化推論（僅當分派設計允許），或其他明確假設下的方法。混合模型的估計目標與假設不同，不能只因 K<30 就自動改用 GLMM，且 GLMM 本身也有少群推論問題。

## 依據（查閱 2026-10-18）
- Li & Redden，二元叢集隨機試驗的模擬研究，顯示修正與參考分布的重要性；研究情境內結果不是所有 GEE 的保證：https://pmc.ncbi.nlm.nih.gov/articles/PMC4268228/
- Mancl & DeRouen (2001)，小樣本 sandwich 修正原始研究：https://onlinelibrary.wiley.com/doi/abs/10.1111/j.0006-341X.2001.00126.x
- geepack 的 std.err 選項：https://cran.r-project.org/web/packages/geepack/refman/geepack.html

## 新增可執行的受限 MD 路徑（2026-10-18）
先 source workflow.R，再 source scripts/gee-small-sample.R，呼叫 fit_gee_md。此路徑使用 gee 的係數及 geesmv::GEE.var.md 的係數變異數，不與 geepack 的係數混接。原函數只提供係數變異數與其變異估計，這裡不推導完整係數協方差、不做多參數聯合檢定。

限制：independence 工作相關結構；Gaussian identity、單欄 0/1 binomial-logit、Poisson-log；無 offset／weights、每群至少 2 列、完整資料與滿秩。至少 3 群且群數大於參數數目是計算前置檢查，不是統計可靠性保證。其他結構／分布、彙總二項或只有單列的群，先說明此實作不涵蓋。

必須明確傳入 df 與 df_reason，再以 t 計算係數別 CI／p。不是所有研究都可用 K−2：本次驗證是兩組平衡、僅截距與組別的簡單平行群模擬例，使用 K−2 近似；其他設計應另據方法學確認。若無適合的自由度依據，保留修正 SE 或探索性分析，不捏造自由度。

geesmv 在目前 CRAN 一般安裝不可用，本次從官方 Archive 安裝 1.3。可先 install.packages(c("gee","matrixcalc"))，再以官方來源 install.packages("https://cran.r-project.org/src/contrib/Archive/geesmv/geesmv_1.3.tar.gz", repos=NULL, type="source")；還需其 nlme／MASS 相依套件。若安裝失敗則停止此修正路徑，保留基本探索性分析，不能自稱已修正。參考：https://cran.r-project.org/web/packages/geesmv/refman/geesmv.html
