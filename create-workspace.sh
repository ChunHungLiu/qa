#!/bin/bash
set -eu

. lib/functions

assert_no_new_repos

(
    set -eu
    mkdir -p .workspace
    cd .workspace
    init_non_existing_repos
    add_build_remote
    add_origin_remote
    add_public_remote
)
