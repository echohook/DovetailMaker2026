# Dovetail Maker 2026 — V1

SketchUp 2026 Pro 的 Through Dovetail（全透鳩尾榫）擴展，採 Tail-first 工作流程。

## 專案資訊

- 創作者：James Hook
- Email：dark.hook@gmail.com
- 版本：1.2.6
- 發布日期：2026-08-31
- 相容版本：SketchUp 2026 Pro
- Clearance：0 mm（V1）

## 安裝

在 SketchUp 的 **Extension Manager → Install Extension** 選擇 `DovetailMaker2026.rbz`。安裝後在 **Extensions → Dovetail Maker 2026** 啟動。

## V1 操作

1. 將兩塊等厚的矩形實體板預先擺到 90° 的實際組裝位置。
2. 只選取 Tail Board（必須是 Group 或 Component），啟動擴展；程式會自動辨識靠近鏡頭的短端面並立即開啟參數視窗。
3. 以整數填入板厚（mm）、Tail 數量與左右半 Pin（mm），這三類欄位皆可用上下鍵增減；如需加工另一端，按 **另一端直接建立**，程式會切換端面並立即建立 Tail，不再二次確認。
4. 在模型中確認綠色即時預覽，需要時按 **Flip 左右**，再按 **建立 Tail**。
5. Tail 完成後可按 **另一端建立相同 Tail**，以相同參數自動加工板材對面端；也可略過此步，直接點選 Pin Board 的對應端面。
6. 確認 Pin 預覽後按 **建立 Pin**，最後按 **完成** 關閉操作視窗。

## V1 限制

- 僅支援封閉、矩形、等厚的 Group / Component 板件。
- 不支援裸幾何、斜板、曲面、非矩形端面、Half-blind 或 CNC 補償。
- Clearance 固定為 0。
- Pin 的輪廓由完成的 Tail 輪廓投影產生，不會另以參數重算。
