#!/bin/bash

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$(dirname "$APP_DIR")")"

# 加载工具函数
source "$ROOT_DIR/lib/utils/logger.sh"

# 加载配置文件
source "$APP_DIR/config/settings.sh"
log_info "加载应用配置成功"

# 提示先自行修改配置
echo "本脚本仅支持在 $PLATFORM_NAME 平台运行"
echo "请先自行修改配置文件 $APP_DIR/config/settings.sh"

read -p "按回车键继续..."

# 创建虚拟环境,如果已经存在则询问是否覆盖
if [ ! -d "$VENV_DIR/$VENV_NAME" ]; then
    log_info "创建虚拟环境..."
    conda create -n $VENV_NAME python=$PYTHON_VERSION -y
    log_success "虚拟环境创建成功"
else
    log_info "虚拟环境已存在，是否覆盖？(y/n)"
    read -p "请输入选项: " choice
    if [ "$choice" == "y" ]; then
        conda create -n $VENV_NAME python=$PYTHON_VERSION -y
        log_success "虚拟环境创建成功"
    else
        log_info "虚拟环境已存在"
    fi
fi

# 激活虚拟环境，如果已经激活则继续运行脚本
if ! conda activate $VENV_NAME; then
    log_info "虚拟环境已激活"
fi

# 安装依赖
log_info "安装依赖..."
pip install -r "$APP_DIR/requirements.txt"
pip install torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 --index-url https://download.pytorch.org/whl/cu118

# 下载F5-TTS
log_info "下载F5-TTS..."
cd $WORKSPACE_DIR
# 如果目录不存在则克隆，存在则更新
if [ ! -d "F5-TTS" ]; then
    git clone https://github.com/SWivid/F5-TTS.git
fi
cd F5-TTS
git pull
pip install -e .
log_success "F5-TTS下载并完成依赖安装"

# 下载模型
log_info "下载模型..."
mkdir -p ckpts/F5TTS_Base
eval $ARIA2_CMD1
mkdir -p ckpts/E2TTS_Base
eval $ARIA2_CMD2
log_success "模型下载完成"

# 运行 F5-TTS 命令
run_cmd="f5-tts_infer-gradio --port $APP_PORT --host 0.0.0.0"
log_info "运行 F5-TTS 命令: $run_cmd"

# 创建安装标记
touch "$APP_DIR/.installed"

# 将配置中的主要内容及启动命令、虚拟环境名称及如何启动虚拟环境及其它必要信息写入使用说明
echo "配置文件: $APP_DIR/config/settings.sh" > "$APP_DIR/使用说明.md"
echo "虚拟环境名称: $VENV_NAME" >> "$APP_DIR/使用说明.md"
echo "启动说明: " >> "$APP_DIR/使用说明.md"
echo "先运行命令启动虚拟环境: conda activate $VENV_NAME" >> "$APP_DIR/使用说明.md"
echo "再运行命令启动 F5-TTS: $run_cmd" >> "$APP_DIR/使用说明.md"
echo "访问地址: http://<host>:$APP_PORT" >> "$APP_DIR/使用说明.md"
log_info "使用说明已写入 $APP_DIR/使用说明.md 中，请自行查看"
log_success "安装完成！"

# 运行 F5-TTS
read -p "是否运行 F5-TTS? (y/n): " choice
if [ "$choice" == "y" ]; then
    eval $run_cmd
fi

