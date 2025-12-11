# hardware — Digital IC & FPGA Accelerator Portfolio

> Collection of my hardware work: from IC contest (cell-based ASIC) to
> systolic-array FPGA accelerators and classic RTL building blocks.  

---

## 1. Overview

This repository gathers my **digital IC design / FPGA accelerator** projects:

- Custom **systolic MAC engines** for AI-style workloads  
- GEMM-based **conv1 accelerator** with 2D systolic array and AXI-stream interface  
- Full **IC Contest** flows (RTL → synthesis reports → SDF gate-level sim)  
- A set of **interview-style RTL IPs** (synchronizer, arbiter, valid/ready handshake…)  


I mainly work with **Verilog/SystemVerilog**, focusing on:

- Clear, timing-friendly RTL structure  
- Self-checking or scriptable testbenches  
- Separation between **compute cores** and **IO / control**  


---

## 2. Repository Map

```text
hardware/
├── dmme/               # Double-layer MAC engine / systolic accelerator
├── SDTA/               # conv1 GEMM accelerator & 2D systolic array
├── ic-contest/         # IC Contest 2021 + 2025 cell-based projects
├── iclab/              # Course-style digital design lab
├── small_ip_practice/  # Small IPs: arbiter, synchronizer, handshake, etc.
└── README.md


3. DMME — Double-Layer MAC Engine (dmme/)
3.1 功能概述
dmme 是一個二層 systolic MAC engine，用於高吞吐量的乘加運算：

64-bit packed input ain1/ain2, bin1/​bin2，內部分拆成多個 16-bit lane

每個 PE 內部是二乘二的 MAC：mac.v 做 2×16-bit 乘加再累加到 32-bit 累積值

nzet.v 依 mask 選出前兩個 non-zero element，降低不必要運算

dmme_ver2.v（dmme_nonmem）把多個 pe 串成二層陣列，輸出 valid_12_out / valid_22_out 與對應的 cout_*


3.2 架構圖（RTL-level）
text
複製程式碼
                  64-bit ain1/ain2, bin1/bin2
                 +----------------------------+
                 |   Mask + NZET selector     |
                 |   (nzet.v, maskinXX_Y)    |
                 +--------------+-------------+
                                |
                +---------------+-------------------------+
                |   Layer 1: PE array (pe11_*, pe12_*)    |
                +---------------+-------------------------+
                                |
                +---------------+-------------------------+
                |   Layer 2: PE array (pe21_*, pe22_*)    |
                +---------------+-------------------------+
                                |
       valid_12_out / valid_22_out + cout_12_*, cout_22_* (32-bit)


3.3 Testbench & Verification
dmme_nonmem_tb.v

產生時脈 / reset / enable / mode（DENDEN, SPADEN）

送入多組 64-bit pattern 與 mask，觀察最終 cout_*_final 以及 done

tb_mac.v, tb_pe.v, tb.sv

針對 MAC、單一 PE 做 unit-level 驗證


3.4 技能重點
Systolic array 設計與 PE 模組化

以 mask + nz-first selection 降低無效運算

多層 valid pipeline 與輸出對齊（valid_12_out, valid_22_out）

可延伸至 DMA / BRAM 寫回（目前在其他專案中實作）


4. SDTA — conv1 GEMM Accelerator (SDTA/)
4.1 功能概述
SDTA 目錄是一套卷積第一層（conv1）的 GEMM-based accelerator，包含：

backbone_pkg.sv：定義 DATA_W=16, ACC_W=32，含 sat16 / ReLU helper

systolic_array_2d.sv：通用 2D systolic array，參數化 ROWS/COLS

conv1_gemm_top.sv：把 3×112×112 feature map 與 64×3×7×7 weight 餵入 systolic array

conv1_axi_stream_top.sv + conv1_B_tile_loader.sv + conv1_C_accum_bram.sv：

實作 AXI-Stream 介面、tiling loader 與 C accumulation BRAM

多個版本的 GEMM top：gemm_full_notile/, gemm_tile/, gemm_axi/, gemm_8x8x12_tilewd/


4.2 conv1 資料流架構
text

Input fmap (3 x 112 x 112)  +  Weights (64 x 3 x 7 x 7)
                 │
                 ▼
          conv1_gemm_top.sv
                 │
       systolic_array_2d.sv (ROWS x COLS MAC grid)
                 │
           C_full feature map
                 │
      (optional) conv1_C_accum_bram.sv
                 │
           AXI-Stream / BRAM interface


4.3 Testbench & Verification
主要 testbench：

tb_conv1_axi_stream_top.sv

產生 AXI-Stream stimulus，連接 conv1_axi_stream_top

追蹤 A_full, B_full, C_full 等矩陣

tb_conv1_gemm_top.sv, tb_conv1_small_gemm.sv

驗證 GEMM top 在不同 tile / size 下的正確性

tb_gemm_8x8x12_tiled.sv, tb_gemm_32x48x80_tiled.sv, tb_gemm16x16.sv

focus 在 systolic core + tiling controller 的功能


4.4 技能重點
將 conv1 映射成 GEMM + systolic array

設計可重用的 backbone_pkg 與 2D systolic core

使用 AXI-Stream 風格介面與 BRAM 累加器

以不同 tile 配置做效能 / 資源 trade-off 的實驗基礎


5. IC Contest — Cell-Based Design (ic-contest/)
5.1 2021 University — geofence
geofence.v：

輸入 10-bit X, Y，輸出 is_inside + valid

以 FSM 管理點資料、向量計算與判斷是否在多邊形內

area.log, timing.log：綜合與時序報告

geofence_syn.sdf：提供 gate-level timing annotation

E_ICC2021_prelimily_univ_cell-based.pdf：原始題目與規格


5.2 2025 Graduate-Level — CONVEX
CONVEX.v：

以多點 (x[i], y[i]) 計算 convex/turning 相關運算，內含向量差、cross product 等

使用 dot_counter, state/next_state 形成 FSM

CONVEX_syn.v, CONVEX_syn.sdf：post-synthesis netlist + SDF

area.log, timing.log, report.txt：面積 / 時序 / 報告


5.3 Flow Highlights
完整 ASIC-style flow：RTL → synthesis → timing → SDF sim

使用計數器 / FSM 實作幾何演算法，處理多點座標與邊界條件


6. iclab — Course-style Digital Design (iclab/)
目前包含 lab01/SSC.v：

SSC 模組以大量 wire/算術運算處理

card_num, snack_num, price 等欄位

計算多組 total、輸出 out_change / outvalid

適合作為早期 RTL 練習與 combinational / sequential 混合設計示例


7. Small IP Practice (small_ip_practice/)
7.1 Synchronizer
2_flop_synchronizer.sv

經典 2-flop CDC synchronizer，附波形與說明註解


7.2 Multi-cycle Multiplier
Two_cycle_Multiplier_Unit.sv

mul2cycle：需兩個 cycle 完成的乘法 unit，包含 start / busy / done protocol

註解中說明 multi-cycle functional unit 背後 timing 與 handshake 概念


7.3 Valid/Ready Handshake
Valid_Ready_Handshake.sv

範例實作 valid/ready 介面，示範 backpressure 與 pipeline 行為


7.4 Round-Robin Arbiters (small_ip_practice/arbiter/)
包含多個 round-robin arbiter 實作：

2way_Round_Robin_Arbiter.sv

4way_Tree_RR_Arbiter.sv, 4way_RR_Arbiter_Stage-1_pipeline_regi.sv

8way_Tree_RR_Arbiter.sv, 8way_Pipelined_Tree_RR_Arbiter.sv

Mask-based_N_way_scalable.sv（可擴展 N-way arbiter）

tb_rr8_tree_pipelined.sv + rr8.pdf：對 8-way arbiter 的測試與說明


Arbiter 結構示意圖
text

req[7:0]
   │
   ├─ 4-way RR arbiter (low 4)
   ├─ 4-way RR arbiter (high 4)
   ▼
 2-way top RR arbiter
   ▼
gnt[7:0] (pipelined output)


8. Verification & Timing Mindset
Across the repository：

幾乎每個核心模組都有對應 tb_*.sv 或 *_tb.v（信心 0.95，來源：檔名分布）

IC Contest 專案附上 area.log, timing.log, *_syn.sdf，顯示實際做過 綜合與時序分析（信心 0.96）

systolic / conv1 部分以不同 tile size 的 TB 驗證架構彈性（信心 0.9）

這些專案反映的思維是：

先搭出 清楚的資料流與狀態機

再用 testbench 把 corner cases 掃過

之後才進行 timing / area 的取捨與結構優化

9. Skills & Keywords
可直接放在履歷 / LinkedIn 的關鍵字整理：

HDL：Verilog, SystemVerilog

Digital Design：FSM, pipeline, multi-cycle path, CDC synchronizer, arbiter, valid/ready

Accelerator：2D systolic array, GEMM-based conv1, MAC engine, tiling controller

ASIC Flow：RTL coding, synthesis, timing report reading, SDF gate-level sim

FPGA Flow：parameterized RTL, BRAM interaction, AXI-Stream style interfaces

Verification：自寫 testbench、waveform debug、pattern-driven testing