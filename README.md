Dotfiles
--------

The dotfiles are managed using
[bare](https://www.saintsjd.com/2011/01/what-is-a-bare-git-repository/) git
repo inspired by this [post](https://www.atlassian.com/git/tutorials/dotfiles).

Apps and command line tools are managed by homebrew.

Install
=========

TL;DR: `curl -LKs https://gist.githubusercontent.com/zhangfand/12f242aff1bf3d1d0906b7472c1c137b/raw/aae5c3687dfe4fab67a8ef1d57f0cc933b30c06f/bootstrap.sh | /bin/bash`

The following steps need to be performed manually to bootstap the 
setup.

Install homebrew: 

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```


Clone dotfiles repo to $HOME:

```
# Clone the bare repo.
git clone --bare https://github.com/zhangfand/dotfiles.git $HOME/.dotfiles.git

# Checkout the actual content from the bare repo.
git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME checkout

# Configure the local repo to use the specific ignore file.
git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME config --local core.excludesFile .gitignore_dotfiles
```

Install clis and apps listed in Brewfile:

```
/opt/homebrew/bin/brew bundle install
```

Set fish shell to be the default shell.
```
# register fish shell as an eligible system shell.
sudo bash -c "echo '/opt/homebrew/bin/fish' >> /etc/shells"
# change default shell to fish
chsh -s '/opt/homebrew/bin/fish'
```

Restart the terminal and fish should be the default shell. Alias `dotfiles`
should be availableto manage dotfiles. 

