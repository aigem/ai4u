#!/bin/bash

# 通用工具库

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 日志函数
log_info() {
    echo -e "\033[32mINFO\033[0m $1"
}

log_warn() {
    echo -e "\033[33mWARN\033[0m $1"
}

log_error() {
    echo -e "\033[31mERROR\033[0m $1"
}

# 检查系统要求
check_system_requirements() {
    # 检查操作系统
    case "$(uname -s)" in
        Linux*)     OS="linux" ;;
        Darwin*)    OS="mac" ;;
        CYGWIN*)    OS="windows" ;;
        MINGW*)     OS="windows" ;;
        *)          OS="unknown" ;;
    esac
    
    # 检查必要的命令
    local required_commands=("curl" "wget" "git" "python3" "pip3")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "必需的命令 '$cmd' 未找到"
            return 1
        fi
    done
    
    # 检查Python版本
    local python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    if [[ "$(echo "$python_version 3.8" | awk '{if ($1 >= $2) print 1; else print 0;}')" == "0" ]]; then
        log_error "Python版本必须 >= 3.8 (当前: $python_version)"
        return 1
    fi
    
    return 0
}

# 检查并创建目录
ensure_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || {
            log_error "创建目录失败: $dir"
            return 1
        }
    fi
}

# 下载文件
download_file() {
    local url="$1"
    local output="$2"
    
    if command -v curl &> /dev/null; then
        log_info "使用 curl 下载: $url"
        curl -sSL "$url" -o "$output"
    elif command -v wget &> /dev/null; then
        log_info "使用 wget 下载: $url"
        wget -q "$url" -O "$output"
    else
        log_error "未找到下载工具 (curl 或 wget)"
        return 1
    fi
}

# 检查端口是否可用
check_port_available() {
    local port="$1"
    if command -v nc &> /dev/null; then
        nc -z localhost "$port" &> /dev/null
        if [ $? -eq 0 ]; then
            log_error "端口 $port 已被占用"
            return 1
        fi
    elif command -v lsof &> /dev/null; then
        if lsof -i :"$port" &> /dev/null; then
            log_error "端口 $port 已被占用"
            return 1
        fi
    else
        log_warn "无法检查端口状态 (需要 nc 或 lsof)"
        return 0
    fi
    return 0
}

# 获取可用端口
get_available_port() {
    local start_port="${1:-8000}"
    local port="$start_port"
    
    while ! check_port_available "$port"; do
        ((port++))
    done
    
    echo "$port"
}

# 检查磁盘空间
check_disk_space() {
    local required_mb="$1"
    local path="${2:-/}"
    
    # 获取可用空间（MB）
    local available_mb
    if [[ "$OS" == "mac" ]]; then
        available_mb=$(df -m "$path" | tail -1 | awk '{print $4}')
    else
        available_mb=$(df -m "$path" | tail -1 | awk '{print $4}')
    fi
    
    if [ "$available_mb" -lt "$required_mb" ]; then
        log_error "磁盘空间不足。需要: ${required_mb}MB, 可用: ${available_mb}MB"
        return 1
    fi
    
    return 0
}

# 检查内存
check_memory() {
    local required_mb="$1"
    local available_mb
    
    if [[ "$OS" == "linux" ]]; then
        available_mb=$(free -m | awk '/^Mem:/{print $7}')
    elif [[ "$OS" == "mac" ]]; then
        available_mb=$(vm_stat | awk '/free/ {free=$3} /speculative/ {spec=$3} END {print (free+spec)*4096/1048576}')
    else
        available_mb=$(wmic OS get FreePhysicalMemory | awk 'NR==2{print $1/1024}')
    fi
    
    if [ "$available_mb" -lt "$required_mb" ]; then
        log_error "内存不足。需要: ${required_mb}MB, 可用: ${available_mb}MB"
        return 1
    fi
    
    return 0
}

# 检查并安装Python包
install_python_package() {
    local package="$1"
    local version="${2:-}"
    
    if [ -n "$version" ]; then
        package="$package==$version"
    fi
    
    log_info "安装 Python 包: $package"
    pip3 install "$package" || {
        log_error "安装 Python 包失败: $package"
        return 1
    }
}

# 检查Git仓库
check_git_repo() {
    local repo_path="$1"
    
    if [ ! -d "$repo_path/.git" ]; then
        log_error "不是有效的 Git 仓库: $repo_path"
        return 1
    fi
    
    if ! git -C "$repo_path" rev-parse --is-inside-work-tree &> /dev/null; then
        log_error "Git 仓库已损坏: $repo_path"
        return 1
    fi
    
    return 0
}

# 克隆Git仓库
clone_git_repo() {
    local repo_url="$1"
    local target_dir="$2"
    local branch="${3:-master}"
    
    log_info "克隆仓库: $repo_url -> $target_dir (分支: $branch)"
    git clone -b "$branch" "$repo_url" "$target_dir"
}

# 生成随机字符串
generate_random_string() {
    local length="${1:-32}"
    tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w "$length" | head -n 1
}

# 验证URL
validate_url() {
    local url="$1"
    local timeout="${2:-5}"
    
    if command -v curl &> /dev/null; then
        if ! curl --output /dev/null --silent --head --fail --max-time "$timeout" "$url"; then
            log_error "无效的 URL: $url"
            return 1
        fi
    else
        if ! wget --spider --quiet --timeout="$timeout" "$url"; then
            log_error "无效的 URL: $url"
            return 1
        fi
    fi
    return 0
}

# 检查进程是否运行
check_process_running() {
    local process_name="$1"
    pgrep -f "$process_name" &> /dev/null
}

# 获取CPU核心数
get_cpu_cores() {
    local cores
    
    if [[ "$OS" == "linux" ]]; then
        cores=$(nproc)
    elif [[ "$OS" == "mac" ]]; then
        cores=$(sysctl -n hw.ncpu)
    else
        cores=$(wmic cpu get NumberOfCores | awk 'NR==2')
    fi
    
    echo "${cores:-1}"
}

# 检查并安装系统包
install_system_package() {
    local package="$1"
    local package_manager
    
    # 检测包管理器
    if command -v apt-get &> /dev/null; then
        package_manager="apt"
    elif command -v yum &> /dev/null; then
        package_manager="yum"
    elif command -v brew &> /dev/null; then
        package_manager="brew"
    else
        log_error "未找到支持的包管理器"
        return 1
    fi
    
    # 安装包
    log_info "使用 $package_manager 安装 $package"
    case "$package_manager" in
        apt)
            sudo apt-get update && sudo apt-get install -y "$package"
            ;;
        yum)
            sudo yum install -y "$package"
            ;;
        brew)
            brew install "$package"
            ;;
    esac
    
    if [ $? -ne 0 ]; then
        log_error "安装包失败: $package"
        return 1
    fi
    
    return 0
}

# 检查目录结构
check_directory_structure() {
    local base_dir="$1"
    local required_dirs=(
        "templates"
        "templates/app_template"
        "apps"
        "lib"
        "utils"
        "logs"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$base_dir/$dir" ]; then
            log_error "缺少必要目录: $dir"
            return 1
        fi
    done
    
    # 检查必要文件
    local required_files=(
        "templates/app_template/install.sh"
        "templates/config_template.sh"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$base_dir/$file" ]; then
            log_error "缺少必要文件: $file"
            return 1
        fi
    done
    
    return 0
}
