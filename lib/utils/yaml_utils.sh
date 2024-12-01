#!/bin/bash

# 从YAML文件获取值
yaml_get() {
    local file="$1"
    local key="$2"

    python3 -c "
import yaml

def get_value(file_path, key):
    with open(file_path, 'r') as f:
        data = yaml.safe_load(f)
    
    value = data
    for k in key.split('.'):
        value = value.get(k, '')
    
    print(value)

get_value('$file', '$key')
"
}

# 更新YAML文件字段
update_yaml() {
    local file="$1"
    local key="$2"
    local value="$3"

    python3 -c "
import yaml

def update_yaml(file_path, key, value):
    with open(file_path, 'r') as f:
        data = yaml.safe_load(f)
    
    data[key] = value
    
    with open(file_path, 'w') as f:
        yaml.dump(data, f, default_flow_style=False)

update_yaml('$file', '$key', '$value')
"
}

# 从YAML文件获取数组
yaml_get_array() {
    local file="$1"
    local key="$2"

    python3 -c "
import yaml

def get_array(file_path, key):
    with open(file_path, 'r') as f:
        data = yaml.safe_load(f)
    
    value = data
    for k in key.split('.'):
        value = value.get(k, [])
    
    if isinstance(value, list):
        print(' '.join(str(x) for x in value))

get_array('$file', '$key')
"
}