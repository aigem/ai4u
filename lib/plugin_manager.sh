#!/bin/bash

# 插件管理
PLUGIN_DIR="$SCRIPT_DIR/plugins"
declare -A LOADED_PLUGINS

# 加载插件
load_plugin() {
    local plugin_name="$1"
    local plugin_file="$PLUGIN_DIR/${plugin_name}.sh"
    
    if [ ! -f "$plugin_file" ]; then
        log_error "插件不存在: $plugin_name"
        return 1
    fi
    
    if [ -n "${LOADED_PLUGINS[$plugin_name]}" ]; then
        return 0
    fi
    
    source "$plugin_file" || {
        log_error "加载插件失败: $plugin_name"
        return 1
    }
    
    LOADED_PLUGINS[$plugin_name]=1
} 