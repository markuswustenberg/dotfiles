function git_branch() {
    branch=$(git symbolic-ref HEAD 2> /dev/null | awk 'BEGIN{FS="/"} {print $NF}')
    if [[ $branch == "" ]]; then
        :
    else
        echo ' ('$branch')'
    fi
}

function aws_profile() {
    if [[ $AWS_PROFILE == "" ]]; then
        :
    else
        echo ' ☁️  '$AWS_PROFILE
    fi
}

alias config='/usr/bin/git --git-dir=/Users/markus/.cfg/ --work-tree=/Users/markus'
export GOPATH=~/Developer/go
export PATH="$GOPATH/bin:$PATH"
export AWS_PAGER=""

setopt prompt_subst
PROMPT='%~$(git_branch)$(aws_profile) $ '

autoload -U compinit
compinit

export EDITOR="zed"

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
