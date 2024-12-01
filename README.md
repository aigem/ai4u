# AI工具安装系统

一个简单高效的AI应用管理和部署系统。本系统提供了统一的接口来安装、管理和配置各种AI工具。

## 系统概述

### 主要特点
- 简单直观的命令行界面
- 统一的AI应用安装流程
- 交互式应用创建向导
- 强大的错误处理和验证
- 实时进度监控
- 标准化配置管理

### 目标用户
- 系统管理员
- AI研究人员和开发者
- DevOps工程师
- 数据科学家

## 安装说明

### 系统要求
- Ubuntu 20.04 LTS或更高版本
- Root权限
- 最少1GB可用磁盘空间
- 最少512MB内存
- Python 3.x
- 必需软件包：curl, wget, git

### 快速开始
```bash
# 克隆仓库
git clone https://github.com/yourusername/aitools.git

# 设置执行权限
chmod +x aitools.sh
chmod +x lib/core/*.sh
chmod +x lib/utils/*.sh
chmod +x lib/tui/*.sh

# 运行系统
./aitools.sh
```

## 基本使用

### 创建新应用

#### 交互式模式（推荐）
```bash
sudo ./aitools.sh create --interactive
```
按照提示完成以下步骤：
1. 输入应用名称
2. 选择应用类型
3. 配置基本设置

#### 快速创建
```bash
sudo ./aitools.sh create myapp --type text_generation
```

### 应用管理

```bash
# 列出所有应用
./aitools.sh list

# 创建新应用（交互式）
./aitools.sh create --interactive

# 创建新应用（非交互式）
./aitools.sh create --type text_generation myapp

# 安装应用
./aitools.sh install myapp

# 查看应用状态
./aitools.sh status myapp

# 更新应用
./aitools.sh update myapp

# 移除应用
./aitools.sh remove myapp
```

## 配置指南

### 全局设置
位于 `config/settings.yaml`：
```yaml
system:
  version: "1.0.0"  # 系统版本
  debug: false      # 调试模式
  log_level: "info" # 日志级别

paths:
  apps: "./apps"        # 应用目录
  templates: "./templates"  # 模板目录
  logs: "./logs"        # 日志目录

defaults:
  timeout: 300           # 超时时间（秒）
  retry_count: 3         # 重试次数
  concurrent_installs: 1 # 并发安装数
```

### 应用配置
每个应用都有自己的配置文件 `apps/<应用名>/config.yaml`：
```yaml
name: ""          # 应用名称
type: ""          # 应用类型
version: "1.0"    # 版本号
deps: []          # 依赖项
env: {}           # 环境变量
steps:            # 安装步骤
  pre: []         # 前置步骤
  main: []        # 主要步骤
  post: []        # 后置步骤
cmd: ""          # 启动命令
```

## 测试功能

系统提供了全面的测试套件，用于验证所有核心功能的正确性。

### 测试覆盖范围

- 应用创建测试
  - 非交互式创建
  - 交互式创建
  - 配置文件验证
  - 目录结构检查
- 应用管理测试
  - 安装流程
  - 更新功能
  - 状态检查
  - 应用列表
  - 重新安装
  - 应用移除
- 错误处理测试
  - 无效输入
  - 缺失依赖
  - 权限问题

### 运行测试

#### 运行所有测试
```bash
# 在项目根目录下运行
./tests/integration_test.sh
```

#### 测试输出说明
测试输出会显示每个测试用例的执行状态：
- ✅ [成功] - 测试通过
- ❌ [错误] - 测试失败
- ℹ️ [信息] - 测试进度信息

### 开发测试

如果您要为系统添加新功能，请确保：
1. 在 `tests/integration_test.sh` 中添加相应的测试用例
2. 测试用例应该包含正常和异常场景
3. 确保所有现有测试仍然通过
4. 使用 `handle_error` 函数处理错误情况

### 测试最佳实践

1. 每次修改代码后运行完整测试套件
2. 保持测试环境的清洁（测试前后清理测试数据）
3. 使用有意义的测试应用名称
4. 验证所有关键配置参数
5. 测试不同类型的应用创建和管理

## 高级功能

### 自定义安装步骤
在 `apps/<应用名>/steps/` 创建自定义安装步骤：
1. 创建新脚本：`custom_step.sh`
2. 在配置中添加步骤：
```yaml
steps:
  pre: ["custom_step"]
```

### 环境变量
在应用配置中设置环境变量：
```yaml
env:
  API_KEY: "你的API密钥"
  MODEL_PATH: "/模型路径"
```

## 故障排除

### 常见问题

#### 安装失败
1. 检查系统要求
2. 验证磁盘空间：`df -h`
3. 查看日志：`config/logs/`
4. 确保有root权限

#### 找不到应用
1. 检查应用名称是否正确
2. 确认应用目录存在
3. 验证配置文件完整性

### 日志查看
- 安装日志：`config/logs/install_<应用名>.log`
- 系统日志：`config/logs/system.log`
- 调试日志：`config/logs/debug.log`

## 开发指南

### 添加新应用类型
1. 在 `templates/app_configs/` 创建新的配置模板
2. 在 `templates/validators/` 添加验证规则
3. 更新应用类型列表

### 自定义验证规则
在 `templates/validators/` 创建新的验证规则：
```yaml
required:
  - name
  - type
  - version

env_rules:
  required:
    - API_KEY
  optional:
    - MODEL_PATH
```

## 贡献指南

### 提交代码
1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 发起合并请求

### 报告问题
- 使用 Issue 模板
- 提供详细的错误信息
- 附加相关日志

## 许可证
本项目采用 MIT 许可证