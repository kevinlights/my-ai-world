# BoppieEvolution 项目助手指南

## 项目概述

BoppieEvolution 是一个基于 Godot 3.6.2 引擎开发的自然选择模拟项目，实现了基于神经网络的猫头鹰类生物（Owlies）和捕食者生物（Kloppies）的生态系统演化仿真。

- **项目名称**: Boppie Evolution (波比进化)
- **引擎版本**: Godot 3.6.2
- **在线体验**: https://boppie-evolution.brutenis.net
- **项目类型**: 生物进化模拟器 + 神经网络 AI

## 核心概念

- **Owlies**: 猫头鹰类生物，以红色食物点（苹果）为食
- **Kloppies**: 捕食者生物，以 Owlies 为食
- **食物链**: 红色食物点 → Owlies → Kloppies
- **神经网络**: 每个生物都有一个小的神经网络，控制其前进/后退和转向行为
- **进化机制**: 基于自然选择和遗传算法的生物进化


## 技术架构

### 主要实体类
- [Boppie](file:///Volumes/Data/projects/runbooks/BoppieEvolution/Entities/Boppie/Boppie.gd) - 生物基类
- [Owlie](file:///Volumes/Data/projects/runbooks/BoppieEvolution/Entities/Boppie/Types/Owlie.gd) - 猫头鹰类生物
- [Kloppie](file:///Volumes/Data/projects/runbooks/BoppieEvolution/Entities/Boppie/Types/Kloppie.gd) - 捕食者生物
- [Food](file:///Volumes/Data/projects/runbooks/BoppieEvolution/Entities/Food/Food.gd) - 食物实体

### AI 和神经网络
- [AI](file:///Volumes/Data/projects/runbooks/BoppieEvolution/Controllers/AIs/AI.gd) - AI 基类
- [NeuralNetwork](file:///Volumes/Data/projects/runbooks/BoppieEvolution/Controllers/AIs/NeuralNetwork.gd) - 神经网络实现
- [RandomAI](file:///Volumes/Data/projects/runbooks/BoppieEvolution/Controllers/AIs/RandomAI.gd) - 随机 AI
- [SmartAI](file:///Volumes/Data/projects/runbooks/BoppieEvolution/Controllers/AIs/SmartAI.gd) - 智能 AI
- [Player](file:///Volumes/Data/projects/runbooks/BoppieEvolution/Controllers/AIs/Player.gd) - 玩家控制

### 全局管理器
- [Data](file:///Volumes/Data/projects/runbooks/BoppieEvolution/Globals/Data.gd) - 数据管理
- [Globals](file:///Volumes/Data/projects/runbooks/BoppieEvolution/Globals/Globals.gd) - 全局变量
- [Utils](file:///Volumes/Data/projects/runbooks/BoppieEvolution/Globals/Utils.gd) - 工具函数
- [InnovationManager](file:///Volumes/Data/projects/runbooks/BoppieEvolution/Globals/InnovationManager.gd) - 创新管理器 (NEAT 算法相关)

### UI 组件
- [TimePlot](file:///Volumes/Data/projects/runbooks/BoppieEvolution/UI/Plotting/TimePlot.gd) - 时间图表显示

## 运行和控制

### 快捷键
- `H` - 显示帮助页面
- `W`/`A`/`S`/`D` - 移动相机 (按住 Shift 可加速 10 倍)
- `鼠标点击拖拽` - 移动相机
- `鼠标点击生物` - 跟随该生物直到死亡
- `鼠标滚轮` - 缩放
- `ESC` - 停止跟随生物
- `O`/`K` - 跟随最适合的 Owlie/Kloppie 直到死亡
- `P` - 性能模式开关 (提高帧率)
- `F` - 死亡后继续跟随最适合的生物
- `C` - 控制当前跟随的生物
- `E` - 为当前生物增加能量
- `-`/`+` - 增加/减少时间倍速 (最小 0.5x, 最大 256x)
- `数字 1-9` - 设置时间倍速为 2^(数字-1)
- `空格` - 暂停/恢复
- `R` - 显示所有生物的视觉射线
- `T` - 显示当前生物的视觉射线

### 启动建议
快速开始: 启动模拟后，按 `9` 快速模拟。几分钟后按 `1` 回到正常速度，观察生物现在具备的能力！

## 未来发展方向

### 模拟功能
- 添加障碍物
- 增强感官系统 (角度+距离检测、视野锥形)
- 实现有性繁殖
- 添加模拟加载/保存功能
- 添加高产地区域
- 添加季节变化
- 添加地理隔离特征

### UI/UX 改进
- 添加配置菜单
- 显示遗传树
- 添加更多统计图表
- 改进神经网络可视化
- 增加无障碍功能 (高对比度、大字体)

## 开发环境设置

1. 下载 Godot 引擎 (3.6.2 或兼容版本)
2. 克隆仓库: `git clone https://github.com/LiquidFun/BoppieEvolution`
3. 在 Godot 中导入 `project.godot` 文件
4. 点击播放按钮运行项目

## 设计原理

该项目受多种视频和研究启发，包括:
- 进化模拟器
- Neuroevolution of Augmenting Topologies (NEAT) 算法
- 自然选择模拟

项目实现了洛特卡-沃尔泰拉方程中的捕食者-猎物循环现象，展示了基于基本神经网络和进化的有趣行为涌现。

## 官方文档

godot-docs-html-3.6 目录包含了 Godot 3.6.2 的官方文档，可作为开发参考。
