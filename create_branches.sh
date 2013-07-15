#!/bin/bash
set -eu

function repo_lines() {
wget -qO - https://raw.github.com/openstack-dev/devstack/master/stackrc |
    grep "_REPO=" 
}

function non_git_repos() {
    repo_lines | grep -v GIT_BASE
}

function git_repos() {
    repo_lines | grep GIT_BASE
}

function extract_bash_default() {
    sed -e 's/.*:-\(.*\)}$/\1/g'
}

function extract_var_user_repo() {
    sed -e 's,^\(.*\)=.*/\(.*\)/\(.*\)}$,\1 \2 \3,g'
}

function generate_repos() {
    {
        {
            git_repos | extract_var_user_repo
            echo "DEVSTACK_REPO openstack-dev devstack.git"
        } | extract_var_user_repo | sed 's/$/ github/'
        non_git_repos | extract_var_user_repo | sed 's/$/ anongit/'
    } | sort
}

function assert_no_new_repos() {
diff -u \
    <(generate_repos) \
    - \
    << EOF
BM_IMAGE_BUILD_REPO stackforge diskimage-builder.git github
BM_POSEUR_REPO tripleo bm_poseur.git github
CEILOMETERCLIENT_REPO openstack python-ceilometerclient.git github
CEILOMETER_REPO openstack ceilometer.git github
CINDERCLIENT_REPO openstack python-cinderclient.git github
CINDER_REPO openstack cinder.git github
DEVSTACK_REPO openstack-dev devstack.git github
GLANCECLIENT_REPO openstack python-glanceclient.git github
GLANCE_REPO openstack glance.git github
HEATCLIENT_REPO openstack python-heatclient.git github
HEAT_REPO openstack heat.git github
HORIZON_REPO openstack horizon.git github
KEYSTONECLIENT_REPO openstack python-keystoneclient.git github
KEYSTONE_REPO openstack keystone.git github
NEUTRONCLIENT_REPO openstack python-neutronclient.git github
NEUTRON_REPO openstack neutron.git github
NOVACLIENT_REPO openstack python-novaclient.git github
NOVA_REPO openstack nova.git github
NOVNC_REPO kanaka noVNC.git github
OPENSTACKCLIENT_REPO openstack python-openstackclient.git github
PBR_REPO openstack-dev pbr.git github
RYU_REPO osrg ryu.git github
SPICE_REPO spice spice-html5.git anongit
SWIFT3_REPO fujita swift3.git github
SWIFTCLIENT_REPO openstack python-swiftclient.git github
SWIFT_REPO openstack swift.git github
TEMPEST_REPO openstack tempest.git github
EOF
}

function dst_repo() {
    local repo

    repo="$1"

    local reponame

    reponame=$(echo "$repo" | cut -d" " -f 3)

    echo "git://gold.eng.hq.xensource.com/git/internal/builds/$reponame"
}


function source_repo() {
    local repo

    repo="$1"

    local varname
    local username
    local reponame
    local provider

    varname=$(echo "$repo" | cut -d" " -f 1)
    username=$(echo "$repo" | cut -d" " -f 2)
    reponame=$(echo "$repo" | cut -d" " -f 3)
    provider=$(echo "$repo" | cut -d" " -f 4)

    echo "git://gold.eng.hq.xensource.com/git/$provider/$username/$reponame"
}

function var_name() {
    local repo

    repo="$1"

    local varname

    varname=$(echo "$repo" | cut -d" " -f 1)

    echo "$varname"
}

function repo_name() {
    local repo

    repo="$1"

    local reponame

    reponame=$(echo "$repo" | cut -d" " -f 3)

    echo "$reponame"
}

function create_build_branch() {
    local branch
    local repo
    local varname

    branch="$1"

    generate_repos | while read repo; do
        varname=$(var_name "$repo")
        [ -d "$varname" ] || git clone $(source_repo "$repo") "$varname"
        (
            set -e
            cd "$varname"

            git fetch -q origin || true # Ignore fetch errors
            git checkout origin/master -B "$branch"
            if ! git remote -v | grep -q "^build"; then
                git remote add build $(dst_repo "$repo")
            fi
            git push build "$branch"
        )
    done
}

function print_updated_repos() {
    local branch1
    local branch2

    branch1="$1"
    branch2="$2"

    local reponame
    local varname

    generate_repos | while read repo; do
        varname=$(var_name "$repo")
        reponame=$(repo_name "$repo")

        cd "$varname"
        if ! git diff --quiet "$branch1" "$branch2"; then
            echo "$reponame"
        fi
        cd ..
    done
}

function clone_status_repo() {
    local srcrepo
    local ldir

    srcrepo="$1"
    ldir="$2"


if ! [ -d "$ldir" ]; then
    git clone "$srcrepo" "$ldir"
fi
}

function pull_status_repo() {
    local ldir

    ldir="$1"

    (
        cd "$ldir"
        git pull
    )
}

function write_latest_branch() {
    local ldir

    ldir="$1"

    cat > "$ldir/latest_branch"
}

function read_latest_branch() {
    local ldir

    ldir="$1"

    cat "$ldir/latest_branch"
}

function push_status_repo() {
    local ldir

    ldir="$1"

    (
        cd "$ldir"
        git commit -am "Automatic update"
        git push
    )
}

assert_no_new_repos

BRANCH_NAME="build-$(date +%s)"

    
clone_status_repo "git://gold.eng.hq.xensource.com/git/internal/builds/status.git" status

pull_status_repo status

PREV_BRANCH=$(read_latest_branch status)

create_build_branch "$BRANCH_NAME"

if [ -z "$PREV_BRANCH" ]; then
    echo "$BRANCH_NAME" | write_latest_branch status
    push_status_repo status
else
    if ! print_updated_repos "$PREV_BRANCH" "$BRANCH_NAME" | diff -u /dev/null -; then
        echo "$BRANCH_NAME" | write_latest_branch status
        push_status_repo status
    fi
fi
