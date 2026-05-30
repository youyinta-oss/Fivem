# FiveM 实时调车系统

一套基于独立版 + OxMySQL 的 FiveM 实时车辆调教系统，支持实时物理生效、预装方案管理、权限管控等功能。

## 功能特性

### 🎮 实时物理生效
- 边调边试，无需重新刷车
- 高频覆写，滑块拖动瞬间生效
- 强制刷新车辆物理状态，解决悬挂/重量不实时更新问题

### 🔐 权限管控
- 完全使用 FiveM 原生 Ace 权限
- 服务端验证，杜绝客户端作弊
- 支持临时授权普通玩家

### 📦 预装方案存储
- JSON 序列化存储，高扩展性
- 支持保存、加载、删除调车方案
- 按车型和玩家标识分类管理

### 🎨 现代化 NUI 界面
- 蓝黑渐变风格设计
- 流畅的动画和交互效果
- 实时参数显示

## 安装说明

### 前置要求
- FiveM 服务器
- [OxMySQL](https://github.com/overextended/oxmysql) 资源
- MySQL 数据库

### 安装步骤

1. 下载资源到服务器 `resources` 目录
2. 导入数据库表结构：
   ```sql
   CREATE TABLE IF NOT EXISTS `vehicle_tunes` (
     `id` INT AUTO_INCREMENT PRIMARY KEY,
     `identifier` VARCHAR(50) NOT NULL,
     `vehicle_hash` VARCHAR(20) NOT NULL,
     `tune_name` VARCHAR(100) NOT NULL,
     `tune_data` JSON NOT NULL,
     `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
     INDEX idx_identifier (`identifier`),
     INDEX idx_vehicle (`vehicle_hash`)
   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
   ```
3. 在 `server.cfg` 中配置权限：
   ```
   add_ace group.admin tuning.admin allow
   ensure oxmysql
   ensure [资源名称]
   ```
4. 启动服务器

## 使用说明

### 管理员指令
- `/granttune [玩家ID]` - 为指定玩家临时授权调车权限

### 玩家指令
- `/tune` - 打开调车面板（需要权限）

### 调车参数
系统支持以下参数调节：

| 参数 | 说明 | 范围 |
|------|------|------|
| 重量 (kg) | 车辆重量 | 500-5000 |
| 加速 | 初始驱动力 | 0.1-2.0 |
| 刹车力度 | 刹车强度 | 0.1-3.0 |
| 刹车比例 (前) | 前后刹车分配 | 0.1-0.9 |
| 转向角度 | 最大转向角度 | 10-60 |
| 抓地力 | 轮胎抓地系数 | 0.5-3.0 |
| 悬挂硬度 | 悬挂刚度 | 0.1-5.0 |
| 防倾杆 | 防倾杆强度 | 0.0-5.0 |
| 空气阻力 | 风阻系数 | 0.1-10.0 |
| 驱动比例 (前) | 四驱分配 | 0.0-1.0 |

### 操作流程
1. 获得调车权限后坐进车辆
2. 输入 `/tune` 打开面板
3. 拖动滑块实时调节参数
4. 踩油门/刹车感受效果
5. 满意后点击"保存方案"
6. 可随时从左侧方案列表加载已保存方案

## 文件结构

```
.
├── fxmanifest.lua          # 资源配置文件
├── database.sql            # 数据库表结构
├── server/
│   └── main.lua           # 服务端脚本
├── client/
│   └── main.lua           # 客户端脚本
└── html/
    ├── index.html         # NUI 界面 HTML
    ├── style.css          # 样式文件
    └── script.js          # 交互逻辑
```

## 技术架构

### 权限系统
- 使用 FiveM Ace 权限机制
- 临时权限存储在服务端内存
- 所有权限验证在服务端完成

### 数据存储
- 使用 OxMySQL 进行数据库操作
- JSON 字段存储调车参数，支持扩展
- 按玩家标识符和车型索引优化查询

### 通信机制
- NUI ↔ 客户端：原生 Fetch API
- 客户端 ↔ 服务端：原生事件
- 高频通信保证实时性

## 开发说明

### 添加新参数
1. 在 `client/main.lua` 中添加保存和应用逻辑
2. 在 NUI 界面添加对应控件
3. 在存储 JSON 中添加字段（无需修改表结构）

### 权限配置
```cfg
# 赋予管理员组权限
add_ace group.admin tuning.admin allow

# 赋予特定玩家权限
add_principal identifier.license:xxx tuning.admin
```

## 许可证

本项目仅供学习和交流使用。

## 支持

如有问题或建议，欢迎提交 Issue。
