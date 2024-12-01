#!/bin/bash

# 解析YAML文件并导出变量
parse_yaml() {
    local yaml_file="$1"
    local prefix="${2:-}"
    
    if [ ! -f "$yaml_file" ]; then
        log_error "未找到YAML文件：$yaml_file"
        return 1
    fi

    # 使用Python解析YAML（比纯bash更可靠）
    python3 -c '
import yaml
import sys
import os

def flatten(dict_obj, prefix=""):
    flat = {}
    for key, value in dict_obj.items():
        if key is None:
            continue
        new_key = f"{prefix}{key}" if prefix else key
        if isinstance(value, dict):
            flat.update(flatten(value, f"{new_key}_"))
        else:
            flat[new_key] = value
    return flat

try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        try:
            data = yaml.safe_load(f)
            if data is None:
                print("警告：YAML文件为空", file=sys.stderr)
                sys.exit(0)
            if not isinstance(data, dict):
                print(f"错误：YAML内容必须是字典格式，而不是 {type(data)}", file=sys.stderr)
                sys.exit(1)
            flat_data = flatten(data)
            for key, value in flat_data.items():
                if isinstance(value, (str, int, float, bool)):
                    # 处理特殊字符
                    if isinstance(value, str):
                        value = value.replace('"', '\\"').replace("$", "\\$")
                    print(f"export {key}=\"{value}\"")
        except yaml.YAMLError as e:
            print(f"解析YAML时出错：{e}", file=sys.stderr)
            sys.exit(1)
except IOError as e:
    print(f"读取文件时出错：{e}", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f"未知错误：{e}", file=sys.stderr)
    sys.exit(1)
' "$yaml_file" || return 1
}

# 从YAML文件获取值
yaml_get_value() {
    local yaml_file="$1"
    local key="$2"
    
    if [ ! -f "$yaml_file" ]; then
        log_error "未找到YAML文件：$yaml_file"
        return 1
    fi
    
    python3 -c '
import yaml
import sys

def get_nested_value(data, key):
    keys = key.split(".")
    current = data
    for k in keys:
        if not isinstance(current, dict):
            return None
        if k not in current:
            return None
        current = current[k]
    return current

try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        try:
            data = yaml.safe_load(f)
            if data is None:
                print("", file=sys.stderr)
                sys.exit(0)
            value = get_nested_value(data, sys.argv[2])
            if value is not None:
                print(value)
            else:
                print("", file=sys.stderr)
        except yaml.YAMLError as e:
            print(f"解析YAML时出错：{e}", file=sys.stderr)
            sys.exit(1)
except IOError as e:
    print(f"读取文件时出错：{e}", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f"未知错误：{e}", file=sys.stderr)
    sys.exit(1)
' "$yaml_file" "$key"
}

# 检查YAML文件中是否存在字段
yaml_has_field() {
    local yaml_file="$1"
    local key="$2"
    
    if [ ! -f "$yaml_file" ]; then
        log_error "未找到YAML文件：$yaml_file"
        return 1
    fi
    
    local value=$(yaml_get_value "$yaml_file" "$key")
    [ -n "$value" ]
}