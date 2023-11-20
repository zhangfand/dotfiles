# Environment Variables
# Set GOPATH to rServer go
export GOPATH=$HOME/go # But still install Go binaries in local folders.
export GOBIN=$HOME/go/bin
export EDITOR=nvim
export TERM='xterm-256color'
set PATH /opt/homebrew/bin $HOME/bin $HOME/.local/bin $HOME/.cargo/bin $GOPATH/bin /Users/zhangfan/Library/Python/3.9/bin /opt/homebrew/opt/openjdk/bin $PATH
# Define XDG file structure.
export XDG_DATA_HOME="$HOME/.local/share"

# nvm
export NVM_DIR="$HOME/.nvm"
function nvm
   bass source $NVM_DIR/nvm.sh --no-use ';' nvm $argv
end


# Alias
alias bzl=mbzl
alias rm='rm -i'
alias bgen='git-preflight --bzl-preflight-args="--max-modified-files 50" trigger_names bzl-gen-preflight'
alias mydiff='git log --author=zhangfan'
alias prod="ssh pdx-shell"
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME'
alias gestalt="mbzl tool //dropbox/yaps/gestalt --" 
alias fbzl="mbzl tool //tools:fbzl"

# Init tools
# Enable starship
starship init fish | source

# Set fish greetings
set -U fish_greeting ""

# Init zoxide
zoxide init fish | source

[ -f ~/.inshellisense/key-bindings.fish ] && source ~/.inshellisense/key-bindings.fish