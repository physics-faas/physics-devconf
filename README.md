# physics-devconf

This repository provides an easy way to deploy a [KinD](https://kind.sigs.k8s.io/) cluster with [Knative](https://knative.dev/) (using [this script](https://github.com/knative/func/blob/main/hack/allocate.sh)) on top of a Fedora 37 VM.

It also provides a couple of sample scripts to deploy a Knative service and a function.

## Deploy the environment (VM)

Takes aprox. 10 minutes:
```
$ vagrant up
Bringing machine 'default' up with 'libvirt' provider...
==> default: Checking if box 'fedora/37-cloud-base' version '37.20221105.0' is up to date...
==> default: Creating image (snapshot of base box volume).
==> default: Creating domain with the following settings...
...
    default: configmap/config-br-defaults configured
    default: ⑦ Dapr
    default: ./allocate.sh: line 251: dapr: command not found
    default: popd
    default: ~/go/src/github.com/knative/func
    default: 
    default: cat <<EOF | sudo tee /etc/docker/daemon.json
    default: {"insecure-registries": ["localhost:50000"]}
    default: EOF
    default: {"insecure-registries": ["localhost:50000"]}
```

## Access the environment

1. Login into the virtual machine just created:
```
$ vagrant ssh
```

2. Check if all the pods are running:
```
$ kubectl get pods -A
NAMESPACE            NAME                                         READY   STATUS    RESTARTS   AGE
knative-eventing     eventing-controller-64b4b79c45-ptk85         1/1     Running   0          2m1s
knative-eventing     eventing-webhook-86f7dd95db-2kfdh            1/1     Running   0          2m1s
knative-eventing     imc-controller-769d8b7f66-tcg8h              1/1     Running   0          90s
knative-eventing     imc-dispatcher-55979cf74b-5c992              1/1     Running   0          90s
knative-eventing     mt-broker-controller-f97f8747-d7c6d          1/1     Running   0          78s
knative-eventing     mt-broker-filter-77c75d69fb-bc8l4            1/1     Running   0          79s
knative-eventing     mt-broker-ingress-d96f6d8b5-dqlw9            1/1     Running   0          78s
knative-serving      activator-75777fd57c-sz56g                   1/1     Running   0          2m40s
knative-serving      autoscaler-57d647d6ff-rjmdg                  1/1     Running   0          2m40s
knative-serving      controller-677995dc7b-v4mdh                  1/1     Running   0          2m40s
knative-serving      domain-mapping-5676fb7bcf-rpxdh              1/1     Running   0          2m40s
knative-serving      domainmapping-webhook-fcbd7dff4-l8zcq        1/1     Running   0          2m40s
knative-serving      net-kourier-controller-55c99987b4-6n7k9      1/1     Running   0          61s
knative-serving      webhook-544b958c69-fl5vb                     1/1     Running   0          2m39s
kourier-system       3scale-kourier-gateway-7b89ff5c79-r2j5p      1/1     Running   0          61s
kube-system          coredns-6d4b75cb6d-q4snl                     1/1     Running   0          3m10s
kube-system          coredns-6d4b75cb6d-xpmlj                     1/1     Running   0          3m10s
kube-system          etcd-func-control-plane                      1/1     Running   0          3m22s
kube-system          kindnet-h5qkq                                1/1     Running   0          3m11s
kube-system          kube-apiserver-func-control-plane            1/1     Running   0          3m22s
kube-system          kube-controller-manager-func-control-plane   1/1     Running   0          3m22s
kube-system          kube-proxy-pw8b7                             1/1     Running   0          3m11s
kube-system          kube-scheduler-func-control-plane            1/1     Running   0          3m23s
local-path-storage   local-path-provisioner-6b84c5c67f-pqtcv      1/1     Running   0          3m10s
```

3. Check if the local registry is running:
```
$ docker ps
CONTAINER ID   IMAGE                  COMMAND                  CREATED         STATUS         PORTS                                                                          NAMES
59be051ba43c   registry:2             "/entrypoint.sh /etc…"   2 minutes ago   Up 2 minutes   127.0.0.1:50000->5000/tcp                                                      func-registry
caf78811a6a9   kindest/node:v1.24.6   "/usr/local/bin/entr…"   4 minutes ago   Up 4 minutes   127.0.0.1:39609->6443/tcp, 127.0.0.1:80->30080/tcp, 127.0.0.1:443->30443/tcp   func-control-plane
```


## Create a new (python) function and invoke it

1. Create the knative function:
```
$ func create -l python test-hw
Created python function in /home/vagrant/test-hw
```

2. Take a look around and change the `func.py` code as follows:
```
$ cd test-hw

$ ls
app.sh  func.py  func.yaml  Procfile  README.md  requirements.txt  test_func.py

$ cat func.py
```
```python
from parliament import Context
from flask import Request
import json

# parse request body, json data or URL query parameters
def payload_print(req: Request) -> str:
    if req.method == "GET":
        return "DevConf.cz 2023!"

def main(context: Context):
    """
    Function template
    The context parameter contains the Flask request object and any
    CloudEvent received with the request.
    """

    # Add your business logic here
    print("Received request")

    if 'request' in context.keys():
        return payload_print(context.request), 200
    else:
        print("Empty request", flush=True)
        return "{}", 200
```

3. Build (and push) the function to the internal registry:
```
$ export FUNC_REGISTRY=localhost:50000/kn-user
$ func build --push
🙌 Function image built: localhost:50000/kn-user/test-hw:latest
🕕 Pushing function image to the registry "localhost:50000" using the "" user credentials
```

4. Check that the image has been correctly pushed into the internal registry:
```
$ curl localhost:50000/v2/_catalog
{"repositories":["kn-user/test-hw"]}
```

5. Deploy the function to the kind cluster:
```
$ func deploy --build=false --push=false
✅ Function deployed in namespace "default" and exposed at URL:
     http://test-hw.default.127.0.0.1.sslip.io
```

6. Check that the function has been correctly deployed. After approximately one minute minute the deployment is scaled down to 0 replicas if not used to spare resources:
```
$ kubectl get deploy
NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
test-hw-00001-deployment   0/0     0            0           104s

$ kubectl get route
NAME      URL                                         READY   REASON
test-hw   http://test-hw.default.127.0.0.1.sslip.io   True
```

7. Invoke the function:
```
$ curl http://test-hw.default.127.0.0.1.sslip.io
DevConf.cz 2023!
```

8. Check that the deployment has been scaled up:
```
$ kubectl get deploy
NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
test-hw-00001-deployment   1/1     1            1           3m20s
```


## Fork the base operator github repository and deploy locally


1. Fork this github repository in your github account: `https://github.com/luis5tb/devconf-knative-operator`

2. Clone your fork locally inside the VM (change **YOUR_USER** by yours):
```
$ git clone https://github.com/YOUR_USER/devconf-knative-operator.git
```

In case you want to start an operator from scratch do the next instead (change **YOUR_USER** by yours):
```
$ mkdir devconf-knative-operator
$ cd devconf-knative-operator

# Create base operator
$ operator-sdk init --domain example.com --repo github.com/YOUR_USER/devconf-knative-operator

# Add API
$ operator-sdk create api --group cache --version v1alpha1 --kind KnativeFunction --resource --controller
```


3. Make your modifications
```
$ cd devconf-knative-operator

# Make code modifications
$ make manifests
$ make generate

# Check sample function
$ cat config/samples/cache_v1alpha1_knativefunction.yaml
```

4. Test your code by deploying it
```
# First time only
# Edit config/manager/manager.yaml so that it does not try to download the image if present
# Add, after "image: controller:latest": imagePullPolicy: IfNotPresent

# Then every time you have new code to check do the next
# Increase the version (v0.0.X) as neeeded
$ make docker-build IMG="example.com/devconf-knative-operator:v0.0.X"
$ kind load docker-image example.com/devconf-knative-operator:v0.0.X --name func
$ make deploy IMG="example.com/devconf-knative-operator:v0.0.X"

# Check the deployment
$ kubectl get deployment -n devconf-knative-operator-system

# Check the pod
$ kubectl get pod -n devconf-knative-operator-system
$ kubectl logs -f -n devconf-knative-operator-system POD

# Create the CR to force reconcile loop for function registration
$ kubectl apply -f config/samples/cache_v1alpha1_knativefunction.yaml
# Check the logs
$ kubectl logs -f -n devconf-knative-operator-system POD
```

5. Undeploy (and go loop between step 3 and 5 until needed)
```
$ kubectl delete -f config/samples/cache_v1alpha1_knativefunction.yaml
$ make undeploy
```
