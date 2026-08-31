# Dovetail Maker 2026 — SketchUp Through Dovetail Extension

> **Traditional joinery, accelerated by AI.**  
> A SketchUp 2026 Pro extension for creating **through dovetail joints** with a **Tail-first** workflow.

[English README](README_EN.md)

## 關於這個工具

我長期從事傳統木工作業，在製作家具與木工作品時，習慣盡量不使用螺絲，而是透過各種榫接結構完成組裝。對我而言，榫接不只是結構上的連結方式，也是傳統木工技術中很重要的一部分。

在使用 SketchUp 進行木工作品設計時，我發現鳩尾榫雖然是常見且實用的榫接方式，但每次都要在 SketchUp 中手動繪製、計算斜率、安排 Tail 與 Pin，相當繁瑣且耗時。

因此，我在 AI 的協助下開發了 **Dovetail Maker 2026**，希望把重複性的幾何計算與建模工作交給工具處理，讓木工設計者把更多時間放在作品本身的設計與製作上。

如果你同樣喜歡傳統木工、榫接設計或 SketchUp 建模，歡迎下載、測試與使用，也歡迎透過 GitHub Issues 提出問題與改進建議。

## 主要功能

- SketchUp 2026 Pro 專用鳩尾榫擴展
- Through Dovetail（全透鳩尾榫）
- Tail-first 工作流程
- Tail 數量可自訂
- Tail 斜率支援常用木工比例 `1:4 / 1:5 / 1:6 / 1:7 / 1:8`
- 左右 Half Pin 可自訂
- Tail / Pin 幾何自動計算
- 綠色即時預覽
- Flip 左右方向
- 可於板材另一端建立相同 Tail
- Pin 輪廓直接由完成的 Tail 幾何投影產生
- 支援 Group / Component

## 下載

最新版 RBZ：

**[下載 DovetailMaker2026.rbz](https://github.com/echohook/DovetailMaker2026/raw/main/dist/DovetailMaker2026.rbz)**

> 建議下載 RBZ 後，使用 SketchUp 的 Extension Manager 安裝，不需要解壓縮。

## 支援環境

- **SketchUp 2026 Pro**
- V1 版本：**1.2.9**
- 發布日期：**2026-08-31**
- Clearance：**0 mm**

## 安裝方式

1. 下載 `DovetailMaker2026.rbz`。
2. 開啟 SketchUp 2026 Pro。
3. 進入 **Window → Extension Manager**。
4. 選擇 **Install Extension**。
5. 選取下載的 `DovetailMaker2026.rbz`。
6. 安裝完成後，由 **Extensions → Dovetail Maker 2026** 啟動。

## 基本使用方式

1. 將兩塊等厚的矩形實體板預先擺到 90° 的實際組裝位置。
2. 只選取 Tail Board（必須是 Group 或 Component），啟動擴展。
3. 程式會自動辨識靠近鏡頭的短端面並開啟參數視窗。
4. 設定板厚、Tail 數量、Tail 斜率、左 Half Pin 與右 Half Pin。
5. 在模型中確認綠色即時預覽；需要時使用 **Flip 左右**。
6. 按 **建立 Tail** 完成 Tail 加工。
7. 如需另一端相同 Tail，可使用 **另一端建立相同 Tail**。
8. 選取 Pin Board 的對應端面。
9. 確認 Pin 預覽後按 **建立 Pin**。
10. 按 **完成** 結束操作。

## V1 限制

- 僅支援封閉、矩形、等厚的 Group / Component 板件。
- 兩塊板件需預先放在 90° 實際組裝位置。
- 不支援裸幾何。
- 不支援斜板、曲面或非矩形端面。
- 不支援 Half-blind dovetail。
- 不支援 Sliding dovetail。
- 不支援 CNC 刀具補償。
- Clearance 固定為 0。
- Pin 輪廓由完成的 Tail 幾何投影產生，不另外以參數重新計算。

## 為什麼開發這個工具？

手工木作裡，鳩尾榫是一種經典且可靠的接合方式；但在數位設計階段，重複手動畫出每一個 Tail 與 Pin，會消耗大量時間。

Dovetail Maker 2026 的目標不是取代木工技術，而是減少 SketchUp 裡重複的製圖工作，讓傳統榫接設計能更快從想法進入模型。

## 問題回報與建議

如果你遇到：

- 無法安裝
- 特定板件無法辨識
- Tail / Pin 幾何異常
- SketchUp 版本相容性問題
- 有新的功能建議

請到本 Repository 的 **Issues** 頁面回報，並盡可能附上：

- SketchUp 版本
- Dovetail Maker 版本
- 操作步驟
- 錯誤訊息
- 截圖或範例模型說明

## 專案資訊

- 創作者：James Hook
- Version：1.2.9
- Platform：SketchUp 2026 Pro
- Language：Ruby / SketchUp Ruby API

## Search Keywords

`SketchUp dovetail extension` · `SketchUp woodworking plugin` · `through dovetail` · `dovetail maker` · `woodworking joinery` · `traditional joinery` · `SketchUp Ruby extension` · `furniture design` · `tail first dovetail` · `鳩尾榫` · `木工榫接`

---

**Dovetail Maker 2026** — Traditional joinery, accelerated by AI.
