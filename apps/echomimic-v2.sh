#!/bin/bash

# 设置项目名称
project_name="echomimic-v2"
video_url="https://www.bilibili.com/video/BV1mCkEYyEcy/"

# 脚本信息
echo "================================================"
echo "描述: echomimic-v2 主程序，用于管理 echomimic-v2 的安装和配置"
echo "作者: ai来事"
echo "创建日期: 2024-12-17"
echo "参考视频介绍: $video_url"
echo "================================================"

# 检查是否在 /workspace 目录下
if [ "$(pwd)" != "/workspace" ]; then
    echo "请在 /workspace 目录下运行此脚本"
    echo "参考视频教程: $video_url"
    exit 1
fi

# 检查是否安装了git
if ! command -v git &> /dev/null; then
    echo "git 未安装，请先安装git"
    exit 1
fi

# 克隆仓库
if [ ! -d "ai4u" ]; then
    echo "正在克隆 ai4u 仓库..."
    git clone https://gitee.com/fuliai/ai4u.git
else
    echo "ai4u 仓库已存在，正在更新..."
    cd ai4u
    git pull
    cd ..
fi

# 创建必要的目录
echo "创建必要的目录..."
mkdir -p ai4u/apps/echomimic-v2/scripts

# 复制脚本文件
if [ -d "scripts" ]; then
    echo "复制安装脚本..."
    cp -r scripts/* ai4u/apps/echomimic-v2/scripts/
else
    echo "错误：scripts 目录不存在"
    echo "请确保已获取正确的安装脚本并解压到 /workspace 目录下"
    echo "================================================"
    echo "获取链接: https://gf.bilibili.com/item/detail/1107198073"
    echo ""
    echo "先看视频教程：$video_url"
    echo "================================================"
    exit 1
fi

# 检查必要文件是否存在
if [ ! -f "ai4u/apps/echomimic-v2/scripts/install.sh" ]; then
    echo "错误：install.sh 文件不存在"
    echo "请确保已获取正确的安装脚本并解压到 /workspace 目录下"
    echo "================================================"
    echo "获取链接: https://gf.bilibili.com/item/detail/1107198073"
    echo ""
    echo "先看视频教程：$video_url"
    echo "================================================"
    exit 1
fi

# 设置执行权限
chmod +x ai4u/aitools.sh

# 进入 ai4u 目录并运行安装
cd ai4u
echo "开始安装 echomimic-v2..."
bash aitools.sh install echomimic-v2
