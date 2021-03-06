#!/usr/bin/env bash

# The purpose of this script is to automate the compilation, installation and update of
# the bspwm window manager (https://github.com/baskerville/bspwm) and panel

packages="bspwm sxhkd xdo sutils xtitle bar"

fedora_deps="xcb-util-devel xcb-util-keysyms-devel xcb-util-wm-devel alsa-lib-devel dmenu rxvt-unicode terminus-fonts"
arch_deps="libxcb xcb-util xcb-util-keysyms xcb-util-wm"
ubuntu_deps="xcb libxcb-util0-dev libxcb-ewmh-dev libxcb-randr0-dev libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-xinerama0-dev libasound2-dev libxcb-xtest0-dev"

clone_urls="https://github.com/baskerville/bspwm.git 
https://github.com/baskerville/sxhkd.git 
https://github.com/baskerville/xdo.git 
https://github.com/baskerville/sutils.git 
https://github.com/baskerville/xtitle.git 
https://github.com/LemonBoy/bar.git"

OS=$(lsb_release -si)

deps() {
    echo ">>> Installing dependencies for $packages"
#`set -x` is used to print executed commands 
    case $OS in
        Fedora)
        set -x
        sudo dnf install $fedora_deps;;
        
        Ubuntu|Debian)
        set -x
        sudo apt install $ubuntu_deps;;

        Arch)
        set -x
        sudo pacman -S $arch_deps;;
    esac
    set +x
}

clone() {
    echo ">>> Cloning repositories of $packages"
    set -x
    for url in $clone_urls
    do
        set -x
        git clone $url
        set +x
    done
}

build_install() {
    echo ">>> Compiling and installing $packages"
    for pkg in $packages
    do
        set -x
        cd ./$pkg
        make
        sudo make install
        cd ..
        set +x
    done
}

configuration() {
    echo ">>> Adding Display Manager configuration"
    sudo cp ./bspwm/contrib/freedesktop/bspwm.desktop /usr/share/xsessions/
    echo ">>> Copying example configuration"
    mkdir -p ~/.config/bspwm/ ~/.config/sxhkd/
    if ! [ -f ~/.config/bspwm/bspwmrc ]; then
        cp ./bspwm/examples/bspwmrc ~/.config/bspwm/bspwmrc
        for file in panel panel_bar panel_colors; do
            cp ./bspwm/examples/panel/$file ~/.config/bspwm/
        done
        chmod +x ~/.config/bspwm/panel ~/.config/bspwm/panel_bar
    fi
    if ! [ -f ~/.config/sxhkd/sxhkdrc ]; then
        cp ./bspwm/examples/sxhkdrc ~/.config/sxhkd/sxhkdrc
    fi
    if ! [ `grep -q panel ~/.config/bspwm/bspwmrc` ] ; then
        echo -e "\npanel &" >> ~/.config/bspwm/bspwmrc
    fi
    echo ">>> Setting environment variables"
    touch ~/.bash_profile
    if ! `grep -q "XDG_CONFIG_HOME" ~/.bash_profile` ; then
        echo 'export XDG_CONFIG_HOME="$HOME/.config"' >> ~/.bash_profile
    fi
    if ! `grep -q "PANEL_FIFO" ~/.bash_profile` ; then
        echo 'export PANEL_FIFO="/tmp/panel-fifo"' >> ~/.bash_profile
    fi 
    if ! `grep -q "PATH:~/.config/bspwm" ~/.bash_profile` ; then
        echo 'export PATH="$PATH:~/.config/bspwm"' >> ~/.bash_profile
    fi 
}

main(){
    mkdir -p ./build && cd ./build
    deps
    clone
    build_install
    configuration
    cd ..
}

main
