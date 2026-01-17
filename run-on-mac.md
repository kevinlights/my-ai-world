# 在 Mac Mini M4 上运行 Boppie Evolution

本指南记录了在配备 32GB 内存的 Mac Mini M4 上运行 Boppie Evolution 项目所需的环境依赖项和设置。

## 系统要求

- **硬件**: Mac Mini M4 (任意型号)
- **内存**: 32GB (推荐最低配置)
- **操作系统**: macOS Sonoma 或更高版本
- **架构**: ARM64 (Apple Silicon)

## 软件依赖

### 1. Godot Engine
- **版本**: 3.6.2 Mono (根据项目需求)
- **重要说明**: 项目需要在 Godot 3.6.2 Mono 版本下运行，尽管项目本身并未使用 C# 代码，但此版本确保了所有功能的正常运行
- **官方文档**: https://docs.godotengine.org/en/3.6/
- **下载链接**: https://downloads.godotengine.org/?version=3.6.2&flavor=stable&slug=mono_osx.universal.zip&platform=macos.universal
- **安装方法**:
  ```bash
  # 方式 1: 使用 Homebrew
  brew install --cask godot
  
  # 方式 2: 从 Godot 官网直接下载
  # 访问 https://godotengine.org/download/ 并下载适用于 macOS 的 Godot 3.6.2 Mono 版本
  # 或直接使用以下链接下载:
  # https://downloads.godotengine.org/?version=3.6.2&flavor=stable&slug=mono_osx.universal.zip&platform=macos.universal
  ```

### 2. Git
- **用途**: 版本控制和克隆项目
- **安装方法**:
  ```bash
  # 通常随 Xcode Command Line Tools 提供
  xcode-select --install
  ```

### 3. Mono 开发套件 (非必需)
- **注意**: 虽然项目配置文件 project.godot 中包含 `[mono]` 部分，但项目实际上并未使用 C# 代码
- **安装方法**:
  ```bash
  brew install mono
  ```

## 项目设置

### 1. 克隆代码仓库
```bash
git clone https://github.com/LiquidFun/BoppieEvolution.git
cd BoppieEvolution
```

### 2. 在 Godot 编辑器中打开
1. 启动 Godot 引擎
2. 点击 "导入" 并从项目目录中选择 `project.godot` 文件
3. 点击 "编辑" 以在编辑器中打开项目

### 3. 或者：直接运行
```bash
# 从项目目录执行
godot -e project.godot
```

## 硬件优化注意事项

基于配备 32GB 内存的 Mac Mini M4:
- 该模拟使用神经网络，可能计算密集
- 游戏内提供性能模式 (按 'P') 以禁用视觉效果从而提升帧率
- 可使用时间加速 (按键 1-9) 来加快模拟速度
- 项目针对 2D 物理模拟进行了优化，在 Apple Silicon 上运行良好

## 已知问题及解决方案

1. **性能**: 如果遇到性能问题:
   - 按 'P' 键启用性能模式
   - 减少模拟中活跃生物的数量
   - 关闭其他占用内存的应用程序

2. **加载/保存**: 注意 README 中提到的已知错误 "加载和保存功能无法工作"

## 运行模拟

1. 在 Godot 3.6.2 Mono 版本中打开项目 (尽管项目不包含 C# 代码，但此版本确保了所有功能的正常运行)
2. 运行主场景: `res://Levels/Testing/Testing.tscn`
3. 使用键盘控制:
   - `H` - 显示帮助
   - `W`/`A`/`S`/`D` - 移动摄像机
   - `9` - 快速模拟模式
   - `1` - 正常速度
   - `Space` - 暂停/恢复
   - 数字 1-9 - 设置时间倍数 (1x 到 256x)

## Mac Mini M4 开发建议

- M4 芯片的 ARM64 架构为 Godot 3D/2D 游戏提供了出色的性能
- 32GB 内存支持运行多个实例或复杂模拟
- 开发期间使用性能模式以优化迭代速度
- 模拟包含 NEAT (增强拓扑结构的神经演化) 算法，能够充分利用 M4 芯片的处理能力
