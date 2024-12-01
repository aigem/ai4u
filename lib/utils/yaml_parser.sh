#!/bin/bash

# 解析YAML文件并导出变量
parse_yaml() {
    local yaml_file="$1"
    local prefix="${2:-}"
    
    if [ ! -f "$yaml_file" ]; then
        log_error "未找到YAML文件：$yaml_file"
        return 1
    }

    # 使用Python解析YAML（比纯bash更可靠）
    python3 -c '
import yaml
import sys
import os

def flatten(dict_obj, prefix=""):
    flat = {}
    for key, value in dict_obj.items():
        new_key = f"{prefix}{key}" if prefix else key
        if isinstance(value, dict):
            flat.update(flatten(value, f"{new_key}_"))
        else:
            flat[new_key] = value
    return flat

with open(sys.argv[1], "r") as f:
    try:
        data = yaml.safe_load(f)
        flat_data = flatten(data)
        for key, value in flat_data.items():
            if isinstance(value, (str, int, float, bool)):
                print(f"export {key}=\"{value}\"")
    except yaml.YAMLError as e:
        print(f"解析YAML时出错：{e}", file=sys.stderr)
        sys.exit(1)
' "$yaml_file" || return 1
}

# 从YAML文件获取值
yaml_get_value() {
    local yaml_file="$1"
    local key="$2"
    
    python3 -c "
import yaml
with open('$yaml_file') as f:
    data = yaml.safe_load(f)
    print(data.get('$key', ''))
"
}

# 检查YAML文件中是否存在字段
yaml_has_field() {
    local yaml_file="$1"
    local field="$2"
    
    python3 -c "
import yaml
with open('$yaml_file') as f:
    data = yaml.safe_load(f)
    exit(0 if '$field' in data else 1)
"
}