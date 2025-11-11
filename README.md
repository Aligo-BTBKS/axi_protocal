# axi_protocal

> 记录与实践 **AXI Protocol** 的个人学习与小项目。  
> 板卡/器件：`ZYNQ-7020 (xc7z020clg400-2)` ｜ 开发工具：`Vivado 【TODO: 版本号】` ｜ 仿真：`XSIM / ModelSim`（二选一）

---

## 目录（Table of Contents）

- [仓库结构](#仓库结构)
- [快速开始](#快速开始)
- [本周交付（Week 1：Nov 10–15）](#本周交付week-1nov-10–15)
- [IP 模块概要](#ip-模块概要)
  - [AXI-Lite 从设备 IP](#axi-lite-从设备-ip)
  - [AXI-Stream FIFO IP](#axi-stream-fifo-ip)
- [脚本与自动化](#脚本与自动化)
- [文档与资料](#文档与资料)
- [Roadmap](#roadmap)
- [License](#license)

---

## 仓库结构

```text
axi_protocal/
├─ README.md
├─ LICENSE
├─ docs/
│  ├─ reg_map.md           # 寄存器/地址映射文档
│  ├─ figs/                # 结构图、BD 截图
│  └─ waves/               # 仿真波形图
├─ hw/
│  ├─ ip_axi_lite_slave/   # 带寄存器的 AXI-Lite 从设备 IP
│  │  ├─ rtl/
│  │  └─ sim/              # 针对该 IP 的局部 TB
│  └─ ip_axis_fifo/        # AXI-Stream FIFO IP
│     ├─ rtl/
│     └─ sim/
├─ sim/                    # 通用/顶层 testbench 测试平台
│  ├─ tb_axi_lite/
│  └─ tb_axis_fifo/
├─ scripts/
│  ├─ create_proj.tcl      # Vivado 创建工程脚本
│  ├─ run_xsim.tcl         # 一键仿真脚本
│  └─ gen_reports.tcl      # 资源/时序报告脚本
├─ reports/                # Vivado 生成的报告（资源/时序）
└─ .gitignore
```
# 快速开始



# 本周交付（Week 1: Nov 10–15）
## 交付目标
1) [x] AXI_Lite 从设备 IP(带寄存器)
2) [ ] 可跑通读操作和写操作的SV Testbeach平台
3) [ ] AXI_Stream FIFO IP
4) [ ] 补齐Tcl脚本和报告
## 状态追踪（TODO）
- [x] AXI_Lite 从设备 IP(带寄存器)
- [ ] 可跑通读操作和写操作的SV Testbeach平台
- [ ] AXI_Stream FIFO IP
- [ ] 补齐Tcl脚本和报告

---

# IP模块概要
## __AXI-Lite 从设备 IP__
- 路径 `aaa`
- 数据宽度
- 寻址/对齐
- 错误处理:越界和非对齐地址访问返回`SLVERR`
- 测试基本用例建议
    - 基本读写(读写同拍)
    - AW先到/W先到
    - WSTRB局部写
    - 非法地址和非对其地址访问
详细寄存器映射见`docs/reg_map.md`






