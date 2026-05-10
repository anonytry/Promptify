#!/bin/bash

promptify_header() {
    if [[ -f "$INSTALL_DIR/assets/.draw" ]]; then
        # Dashboard header always uses 'standard' simple font
        bash "$INSTALL_DIR/assets/.draw" "Promptify" "--no-sig" "--font" "std"
    else
        echo -e "\e[1;35m--- Promptify ---\e[0m\e[K"
    fi
}
