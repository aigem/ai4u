load_config() {
    # 1. 加载默认配置
    source "$SCRIPT_DIR/config/defaults.sh"
    
    # 2. 加载系统配置
    [ -f "/etc/aitools/config.sh" ] && source "/etc/aitools/config.sh"
    
    # 3. 加载用户配置
    [ -f "$HOME/.config/aitools/config.sh" ] && source "$HOME/.config/aitools/config.sh"
    
    # 4. 加载应用配置
    [ -f "$APP_DIR/config/config.sh" ] && source "$APP_DIR/config/config.sh"
    
    # 允许通过环境变量覆盖配置
    [ -n "$AITOOLS_INSTALL_DIR" ] && BASE_INSTALL_DIR="$AITOOLS_INSTALL_DIR"
    [ -n "$AITOOLS_LOG_LEVEL" ] && LOG_LEVEL="$AITOOLS_LOG_LEVEL"
} 