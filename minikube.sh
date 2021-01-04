#!/usr/bin/env bash

# Minikube based project - tools and utilities
# Setup a Minikube based golang / cobra / skaffold development environment
# by placing this file in the new project repository scripts directory.

# variables
export project_name="starter"
export project_id="laidback.github.io/starter"
export project_author="Lukas Ciszewski <Lukas.Ciszewski@Gmail.com>"

# usage
USAGE="Usage: script cmd [params]"
if [ "$#" == "0" ]; then # If zero arguments were supplied
    echo "$USAGE"
    exit 1
fi

# script settings
set -o errexit      # fail immediately on the first error occuring
set -o errtrace     # allow clean trapping for ERR
set -o pipefail     # fail also if the call to nested functions fails
set -o nounset      # fail if unset variables are used

# ------------------------------
# set the global error reporting trap
# ------------------------------
function err_report() {
    echo "errexit on line $(caller)"
}
trap err_report ERR

# global exports and paths
export PATH=$PATH

# check if program dependencies exist
command -v docker > /dev/null 2>&1 || { echo "Require docker to be in PATH."; exit 1; }
command -v kubectl > /dev/null 2>&1 || { echo "Require kubectl to be in PATH."; exit 1; }
command -v minikube > /dev/null 2>&1 || { log "Require minikube to be in PATH."; exit 1; }
command -v go > /dev/null 2>&1 || { log "Require golang to be in PATH."; exit 1; }
command -v cobra > /dev/null 2>&1 || { log "Require golang cobra to be in PATH."; exit 1; }

# functions

# setup minikube
function msetup()
{
    minikube start \
        --profile="${project_name}" \
        --insecure-registry="10.0.0.0/24" \
        --container-runtime=docker \
        --driver=docker \
        --alsologtostderr=true

    # enable minikube addons
    minikube addons enable ambassador --profile="${project_name}"
    minikube addons enable registry --profile="${project_name}"

    # setup environment and report stats
    minikube update-context --profile="${project_name}"  # update kubectl
    minikube addons list --profile="${project_name}"
}

# setup golang/cobra project
function psetup()
{
    # setup golang module
    go mod init "${project_id}" || true

    # setup project structure
    mkdir -p api build cmd k8s scripts test

    # setup cobra in cmd directory
    cobra init --pkg-name="${project_id}" --author="${project_author}"

    # setup skaffold
    # skaffold init --XXenableBuildpacksInit
}

# fwreg - forward minikube registry to host machine
# + get the minikube internal registry pod name
# + kube port forward the cluster registry with 5000:5000
# + run socat in docker on host local network to forward the host local
#   port 5000 to the docker internal 5000 which is our registry
function fwreg()
{
    socat=$(docker run --rm --detach --network=host alpine ash -c \
        "apk add socat && socat TCP-LISTEN:5000,reuseaddr,fork TCP:host.docker.internal:5000")
    kubectl port-forward --namespace kube-system service/registry 5000:80
    docker stop "$socat"
}

# --- Main function ---
# It is easier to put more variables into locals if you start
# passing them carefully. The convention C or java style params
# with argc and argv.
main()
{
    cmd=$1; shift 1
    $cmd "$@"
}

# --- shell runmode check
if [ "$0" = "${BASH_SOURCE[0]}" ]; then
    main "$@"
fi

# vim: ft=sh sw=4 ts=4 sts=4 et nowrap:
