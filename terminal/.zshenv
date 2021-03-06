export BROWSER=firefox
export EDITOR=em

export XDG_CONFIG_HOME="$HOME/.config"

export SXHKD_SHELL="/bin/sh"

export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
export QT_QPA_PLATFORMTHEME="qt5ct"

export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"

export FZF_DEFAULT_OPTS="--exact"

typeset -U PATH path
path+=(
    "$HOME/.local/bin"
    "$HOME/.npm/bin"
    "$HOME/go/bin"
    "$HOME/bin"
)
export PATH
