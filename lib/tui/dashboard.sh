#!/bin/bash

show_dashboard() {
    local stats=$(get_system_stats)
    local apps=$(get_installed_apps)
    
    whiptail --title "系统仪表盘" \
             --msgbox "\
系统状态
--------
已安装应用: ${apps}
系统资源使用:
CPU: ${stats[cpu]}%
内存: ${stats[memory]}%
磁盘: ${stats[disk]}%

最近活动
--------
${stats[recent_activities]}\
" 20 70
} 