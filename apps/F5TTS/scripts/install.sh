#!/bin/bash

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$(dirname "$APP_DIR")")"

# 提示先自行修改配置
echo "本脚本仅支持在 $platform 平台运行"
echo "请先自行修改配置文件 $APP_DIR/config/settings.yaml"

read -p "按任意键继续..."

# 加载工具函数
source "$ROOT_DIR/lib/utils/logger.sh"

# 加载应用配置
source "$APP_DIR/config/settings.yaml"
log_info "加载应用配置成功"

# 创建虚拟环境,如果已经存在则询问是否覆盖
if [ ! -d "$venv_dir/$venv_name" ]; then
    log_info "创建虚拟环境..."
    conda create -n $venv_name python=$python_version -y
    log_success "虚拟环境创建成功"
else
    log_info "虚拟环境已存在，是否覆盖？(y/n)"
    read -p "请输入选项: " choice
    if [ "$choice" == "y" ]; then
        conda create -n $venv_name python=$python_version -y
        log_success "虚拟环境创建成功"
    else
        log_error "虚拟环境创建失败"
        exit 1
    fi
fi

# 激活虚拟环境，如果已经激活则继续运行脚本
if ! conda activate $venv_name; then
    log_info "虚拟环境已激活"
fi

# 安装依赖
log_info "安装依赖..."
pip install -r "$APP_DIR/requirements.txt"
pip install torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 --index-url https://download.pytorch.org/whl/cu118

# 下载F5-TTS
log_info "下载F5-TTS..."
cd $workspace_dir
git clone https://github.com/SWivid/F5-TTS.git
cd F5-TTS
pip install -e .
log_success "F5-TTS下载并完成依赖安装"

# 运行 F5-TTS 命令
run_cmd="f5-tts_infer-gradio --port $app_port --host 0.0.0.0"
log_info "运行 F5-TTS 命令: $run_cmd"
# 写入启动命令到配置文件
echo "run_cmd: $run_cmd" >> "$APP_DIR/config/settings.yaml"

# 创建安装标记
touch "$APP_DIR/.installed"

# 将配置中的主要内容及启动命令、虚拟环境名称及如何启动虚拟环境及其它必要信息写入使用说明
echo "配置文件: $APP_DIR/config/settings.yaml" >> "$APP_DIR/使用说明.md"
echo "虚拟环境名称: $venv_name" >> "$APP_DIR/使用说明.md"
echo "如何启动虚拟环境: conda activate $venv_name" >> "$APP_DIR/使用说明.md"
echo "启动命令: $run_cmd" >> "$APP_DIR/使用说明.md"
echo "访问地址: http://<host>:$app_port" >> "$APP_DIR/使用说明.md"
log_success "安装完成！"

# 运行 F5-TTS
read -p "是否运行 F5-TTS? (y/n): " choice
if [ "$choice" == "y" ]; then
    eval $run_cmd
fi

