#!/bin/bash

# 通用工具库

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
            echo "Error: Required command '$cmd' not found"
            return 1
        fi
    done
    
    # 检查Python版本
    local python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    if [[ "$(echo "$python_version 3.8" | awk '{if ($1 >= $2) print 1; else print 0;}')" == "0" ]]; then
        echo "Error: Python version must be >= 3.8 (current: $python_version)"
        return 1
    fi
    
    return 0
}

# 检查并创建目录
ensure_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || {
            echo "Error: Failed to create directory: $dir"
            return 1
        }
    fi
}

# 下载文件
download_file() {
    local url="$1"
    local output="$2"
    
    if command -v curl &> /dev/null; then
        curl -L -o "$output" "$url"
    elif command -v wget &> /dev/null; then
        wget -O "$output" "$url"
    else
        echo "Error: Neither curl nor wget is available"
        return 1
    fi
}

# 检查端口是否可用
check_port_available() {
    local port="$1"
    if ! command -v nc &> /dev/null; then
        return 0  # 如果没有nc命令，假设端口可用
    fi
    
    nc -z localhost "$port" &> /dev/null
    if [ $? -eq 0 ]; then
        echo "Error: Port $port is already in use"
        return 1
    fi
    return 0
}

# 获取可用端口
get_available_port() {
    local start_port="$1"
    local port="$start_port"
    
    while ! check_port_available "$port"; do
        ((port++))
    done
    echo "$port"
}

# 检查磁盘空间
check_disk_space() {
    local required_space="$1"  # 以MB为单位
    local install_path="$2"
    
    local available_space
    if [[ "$OS" == "mac" ]]; then
        available_space=$(df -m "$install_path" | awk 'NR==2 {print $4}')
    else
        available_space=$(df -m "$install_path" | awk 'NR==2 {print $4}')
    fi
    
    if [ "$available_space" -lt "$required_space" ]; then
        echo "Error: Not enough disk space. Required: ${required_space}MB, Available: ${available_space}MB"
        return 1
    fi
    return 0
}

# 检查内存
check_memory() {
    local required_mem="$1"  # 以MB为单位
    
    local total_mem
    if [[ "$OS" == "mac" ]]; then
        total_mem=$(($(sysctl -n hw.memsize) / 1024 / 1024))
    else
        total_mem=$(($(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024))
    fi
    
    if [ "$total_mem" -lt "$required_mem" ]; then
        echo "Error: Not enough memory. Required: ${required_mem}MB, Available: ${total_mem}MB"
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
    
    pip3 install --no-cache-dir "$package"
}

# 检查Git仓库
check_git_repo() {
    local repo_url="$1"
    local branch="${2:-main}"
    
    if ! git ls-remote --exit-code "$repo_url" "refs/heads/$branch" &> /dev/null; then
        echo "Error: Git repository or branch not found: $repo_url#$branch"
        return 1
    fi
    return 0
}

# 克隆Git仓库
clone_git_repo() {
    local repo_url="$1"
    local target_dir="$2"
    local branch="${3:-main}"
    
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
    if curl --output /dev/null --silent --head --fail "$url"; then
        return 0
    else
        echo "Error: Invalid URL: $url"
        return 1
    fi
}

# 检查进程是否运行
check_process_running() {
    local process_name="$1"
    pgrep -f "$process_name" &> /dev/null
}

# 获取CPU核心数
get_cpu_cores() {
    if [[ "$OS" == "mac" ]]; then
        sysctl -n hw.ncpu
    else
        nproc
    fi
}

# 检查并安装系统包
install_system_package() {
    local package="$1"
    
    if [[ "$OS" == "linux" ]]; then
        if command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y "$package"
        elif command -v yum &> /dev/null; then
            yum install -y "$package"
        else
            echo "Error: Unsupported package manager"
            return 1
        fi
    elif [[ "$OS" == "mac" ]]; then
        if ! command -v brew &> /dev/null; then
            echo "Error: Homebrew not installed"
            return 1
        fi
        brew install "$package"
    else
        echo "Error: Unsupported operating system"
        return 1
    fi
}
