#!/bin/bash

# 文件名: F5TTS.sh
# 描述: F5TTS 主程序，用于管理 F5TTS 的安装和配置
# 作者: ai来事
# 创建日期: 2024-12-04
# 版本: 0.0.1
# 详细视频介绍: https://www.bilibili.com/video/BV1BJmSYFE2a/

git clone https://github.com/aigem/ai4u.git
# git clone https://gitee.com/fuliai/ai4u.git
cd ai4u
chmod +x aitools.sh
bash aitools.sh install F5TTS
