function gb -a branch -d "Rebase the branch onto master" -w 'git branch'
    set -l branch $argv[1]
    set -l base (git rev-parse --abbrev-ref $branch@{upstream})
    command git rebase --onto $base "$branch^1" "$branch"
end

