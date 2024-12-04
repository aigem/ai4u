#!/bin/bash

project_name="F5TTS"


# 描述: F5TTS 主程序，用于管理 F5TTS 的安装和配置
# 作者: ai来事
# 创建日期: 2024-12-04
# 版本: 0.1.0
# 详细视频介绍: https://www.bilibili.com/video/BV1BJmSYFE2a/

# 检查是否安装了git
if ! command -v git &> /dev/null; then
    echo "git 未安装，请先安装git"
    exit 1
fi

git clone https://github.com/aigem/ai4u.git
# git clone https://gitee.com/fuliai/ai4u.git

# 复制 scripts 目录及以下所有文件到 ai4u/apps/F5TTS
if [ ! -d "ai4u/apps/$project_name/scripts" ]; then
    mkdir -p ai4u/apps/$project_name/scripts
fi
cp -r scripts/* ai4u/apps/$project_name/scripts/
cd ai4u

# 检查ai4u/apps/F5TTS目录下是否存在install.sh文件，如果不存在则退出
if [ ! -f "apps/$project_name/scripts/install.sh" ]; then
    echo "apps/$project_name/scripts/install.sh 文件不存在"
    echo "是否获取了正确的安装脚本并复制到 /workspace 下"
    echo "================================================"
    echo "获取方式: https://gf.bilibili.com/item/detail/1107198073"
    exit 1
fi

chmod +x aitools.sh
bash aitools.sh install $project_name

