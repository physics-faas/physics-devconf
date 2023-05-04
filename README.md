# physics-devconf

This repository provides an easy way to deploy a KinD cluster with knative (using [1]) on
top of a Fedora 37 VM.

It also provides a couple of sample scripts to deploy a knative service and a function

## Deploy the environment (VM)

    $ vagrant up

## Use the environment

    $ vagrant ssh
    $ sudo su
    # kubectl get pods -A

## Create a new (python) function and invoke it

    # func create -l python test-hw
    # cd test-hw
    # change the code as needed
    # export FUNC_REGISTRY=localhost:50000/kn-user
    # func build --push
    # func deploy --build=false --push=false


[1] https://github.com/knative/func/blob/main/hack/allocate.sh
