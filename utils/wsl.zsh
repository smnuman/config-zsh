# Better WSL opener than wslview/wslu
open() {
    if [[ -z "$1" ]]; then
        echo "usage: open <url-or-path>"
        return 1
    fi

    cmd.exe /C start "" "$1" >/dev/null 2>&1
}

# WSLg PulseAudio bridge
export PULSE_SERVER=unix:/mnt/wslg/PulseServer