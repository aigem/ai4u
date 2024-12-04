#!/bin/bash

# 设置项目名称
project_name="F5TTS"

# 脚本信息
echo "================================================"
echo "描述: F5TTS 主程序，用于管理 F5TTS 的安装和配置"
echo "作者: ai来事"
echo "创建日期: 2024-12-04"
echo "版本: 0.1.0"
echo "详细视频介绍: https://www.bilibili.com/video/BV1BJmSYFE2a/"
echo "================================================"

# 检查是否在 /workspace 目录下
if [ "$(pwd)" != "/workspace" ]; then
    echo "请在 /workspace 目录下运行此脚本"
    exit 1
fi

# 检查是否安装了git
if ! command -v git &> /dev/null; then
    echo "git 未安装，请先安装git"
    exit 1
fi

# 克隆仓库（优先使用 github，如果失败则使用 gitee）,如果仓库存在则git pull更新
if [ ! -d "ai4u" ]; then
    echo "正在克隆 ai4u 仓库..."
    if ! git clone https://github.com/aigem/ai4u.git; then
        echo "从 github 克隆失败，尝试从 gitee 克隆..."
        if ! git clone https://gitee.com/fuliai/ai4u.git; then
            echo "克隆失败，请检查网络连接"
            exit 1
        fi
    fi
else
    echo "ai4u 仓库已存在，正在更新..."
    cd ai4u
    git pull
    cd ..
fi

# 创建必要的目录
echo "创建必要的目录..."
mkdir -p ai4u/apps/$project_name/scripts
mkdir -p ai4u/apps/$project_name/config

# 复制脚本文件
if [ -d "scripts" ]; then
    echo "复制安装脚本..."
    cp -r scripts/* ai4u/apps/$project_name/scripts/
else
    echo "错误：scripts 目录不存在"
    echo "请确保已获取正确的安装脚本并解压到 /workspace 目录下"
    echo "获取方式: https://gf.bilibili.com/item/detail/1107198073"
    exit 1
fi

# 检查必要文件是否存在
if [ ! -f "ai4u/apps/$project_name/scripts/install.sh" ]; then
    echo "错误：install.sh 文件不存在"
    echo "请确保已获取正确的安装脚本"
    echo "获取方式: https://gf.bilibili.com/item/detail/1107198073"
    exit 1
fi

# 设置执行权限
chmod +x ai4u/aitools.sh

# 进入 ai4u 目录并运行安装
cd ai4u
echo "开始安装 $project_name..."
bash aitools.sh install $project_name