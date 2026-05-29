# Nura

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2018.0%2B-blue.svg" alt="Platform: iOS 18.0+">
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/SwiftUI-Native-green.svg" alt="SwiftUI">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="License: MIT">
</p>

## 📱 关于 Nura

Nura 是一款现代化的育儿记录应用，专为新手父母设计。它帮助您轻松记录和追踪宝宝的日常活动、成长里程碑和健康数据，让育儿过程更加井然有序。

### ✨ 主要功能

- **👶 多宝宝管理** - 支持同时管理多个孩子的记录
- **🍼 喂养记录** - 记录母乳、配方奶和辅食喂养
- **😴 睡眠追踪** - 追踪宝宝的睡眠时间和模式
- **🧷 尿布记录** - 记录换尿布次数和类型
- **📏 成长数据** - 记录体重、身高和头围等体征
- **🎯 里程碑** - 记录宝宝的重要成长时刻
- **📊 数据可视化** - 使用图表展示趋势和统计
- **📱 成长报告** - 生成和分享精美的成长报告
- **🎨 个性化主题** - 为每个宝宝选择专属颜色

## 🏗️ 技术栈

- **SwiftUI** - 现代化的声明式 UI 框架
- **Swift Data** - 使用 @Model 宏的本地数据持久化
- **Swift Charts** - 原生图表可视化
- **Swift Concurrency** - async/await 异步编程
- **ImageRenderer** - 报告图片生成

## 📂 项目结构

```
Nura/
├── App/                      # 应用主入口
│   ├── NuraApp.swift        # App 生命周期
│   └── ContentView.swift    # 主视图
│
├── Models/                   # 数据模型层
│   ├── Child.swift          # 孩子模型
│   ├── FeedingRecord.swift  # 喂养记录
│   ├── SleepRecord.swift    # 睡眠记录
│   ├── DiaperRecord.swift   # 尿布记录
│   ├── GrowthRecord.swift   # 成长数据
│   └── Milestone.swift      # 里程碑
│
├── Views/                    # 视图层
│   ├── Home/                # 主页相关视图
│   ├── Child/               # 孩子管理视图
│   ├── Records/             # 各类记录视图
│   ├── Statistics/          # 统计视图
│   └── Reports/             # 报告生成视图
│
├── Components/              # 可复用组件
│   └── ...
│
└── Utilities/               # 工具类
    ├── Theme.swift          # 设计系统
    └── Extensions/          # 扩展
```

## 🎨 设计系统

### 配色方案

- **主色调**: 柔和紫色 (#A78BFA)
- **活动颜色**:
  - 喂养: 绿色 (#10B981)
  - 睡眠: 紫色 (#8B5CF6)
  - 尿布: 琥珀色 (#F59E0B)
- **孩子主题**: 紫色、粉色、蓝色、青色、琥珀色

### 组件

- `StatBox` - 统计数据卡片
- `NuraBadge` - 标签徽章
- `SectionLabel` - 区块标题
- `EmptyStateRow` - 空状态提示

## 🚀 开始使用

### 环境要求

- Xcode 16.0+
- iOS 18.0+
- macOS Sequoia 15.0+ (for development)

### 安装步骤

1. 克隆仓库
```bash
git clone https://github.com/yourusername/nura.git
cd nura
```

2. 打开项目
```bash
open Nura.xcodeproj
```

3. 选择目标设备或模拟器，点击运行

## 📊 数据模型

### Child (孩子)
```swift
@Model
class Child {
    var name: String
    var birthDate: Date
    var gender: Gender
    var color: ChildColor
    // 关联记录...
}
```

### 记录类型
- **FeedingRecord** - 喂养类型、数量、时间
- **SleepRecord** - 开始/结束时间、睡眠质量
- **DiaperRecord** - 尿布类型、更换时间
- **GrowthRecord** - 体重、身高、头围
- **Milestone** - 标题、描述、日期、emoji

## 🎯 路线图

- [ ] iCloud 同步
- [ ] Widget 桌面小组件
- [ ] Apple Watch 支持
- [ ] 数据导出功能
- [ ] 提醒和通知
- [ ] 多语言支持
- [ ] 暗色模式优化
- [ ] iPad 适配

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 开源协议

本项目采用 MIT 协议 - 查看 [LICENSE](LICENSE) 文件了解详情

## 👨‍💻 作者

由充满爱心的开发者为新手父母打造 ❤️

## 🙏 致谢

- SwiftUI 和 Swift Data 框架
- SF Symbols 图标系统
- 所有使用和反馈的用户

---

**记录宝宝成长的每一刻** 🌟
