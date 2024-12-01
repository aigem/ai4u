#!/bin/bash

# 支持多种主题切换
set_theme() {
    local theme="$1"
    case "$theme" in
        "dark")
            export NEWT_COLORS='
                window=,black
                border=white,black
                textbox=white,black
                button=black,white
            '
            ;;
        "light")
            export NEWT_COLORS='
                window=,white
                border=black,white
                textbox=black,white
                button=white,black
            '
            ;;
    esac
} 