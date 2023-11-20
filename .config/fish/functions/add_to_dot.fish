function add_to_dot
    set src $argv[1]
    set dst $HOME/.dotfiles/work/(basename $src)

    # Move the file to the destination folder
    mv $src $dst

    # Create a symbolic link pointing to the new location
    ln -s $dst $src
end
