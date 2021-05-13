#!/usr/bin/env bash

set -euo pipefail
shopt -s inherit_errexit

checkDep () {
    local dep=$1

    echo "- checking dependency $dep"
    which $dep || { echo "- Depends on '$dep' but was not found"; exit 1; }
}

getVar () {
    local var=$1
    [[ -v "$var" ]] || {
        read -p "- Enter value for $1: " var && \
        echo $var && \
        return
    }
    echo ${!var}
}

buildHugo () {
    local output=$1
    local baseULR=$2

    echo "- building hugo website"
    echo "- using '$1' as output dir"
    mkdir -p $1
    hugo \
        --destination $1 \
        --baseURL $2 \
        --cleanDestinationDir \
        --gc
}

publish () {
    local sourceDir=$1
    local dest=$2
    local port=$3
    local destDir=$4

    echo "- Publish content at $sourceDir to $dest:$port/$destDir"
    cd $sourceDir && { \
        echo $(git log -1) > git.version && \
        rsync -zvhpr --delete --rsh="ssh -p $port" ./ "$dest:$destDir"
    }
}

DEST_URL=$(getVar "DEST_URL")
DEST_PORT=$(getVar "DEST_PORT")
DEST_DIR=$(getVar "DEST_DIR")

checkDep "hugo"
checkDep "git"

buildHugo "build" "https://dharti.life"

publish "build" "$DEST_URL" "$DEST_PORT" "$DEST_DIR"
