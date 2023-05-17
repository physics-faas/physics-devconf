# physics-devconf

This repository provides an easy way to deploy a [KinD](https://kind.sigs.k8s.io/) cluster with [Knative](https://knative.dev/) (using [[1]](https://github.com/knative/func/blob/main/hack/allocate.sh)) on
top of a Fedora 37 VM.

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
    default: ~/go/src/github.com/knative/func
    default: {"insecure-registries": ["localhost:50000"]}
```

## Access the environment

    $ vagrant ssh
    [vagrant@localhost ~]$ sudo -i

Check if all the pods are running:
```
# kubectl get pods -A
NAMESPACE            NAME                                         READY   STATUS    RESTARTS   AGE
knative-eventing     eventing-controller-64b4b79c45-cnctl         1/1     Running   0          68m
knative-eventing     eventing-webhook-86f7dd95db-hpltb            1/1     Running   0          68m
knative-eventing     imc-controller-769d8b7f66-jc5ph              1/1     Running   0          67m
knative-eventing     imc-dispatcher-55979cf74b-tsq9n              1/1     Running   0          67m
knative-eventing     mt-broker-controller-f97f8747-6h8mk          1/1     Running   0          67m
knative-eventing     mt-broker-filter-77c75d69fb-zsjq4            1/1     Running   0          67m
knative-eventing     mt-broker-ingress-d96f6d8b5-hh4t5            1/1     Running   0          67m
knative-serving      activator-75777fd57c-5x5hz                   1/1     Running   0          69m
knative-serving      autoscaler-57d647d6ff-t8gg2                  1/1     Running   0          69m
knative-serving      controller-677995dc7b-hrhcl                  1/1     Running   0          69m
knative-serving      domain-mapping-5676fb7bcf-g6xkn              1/1     Running   0          69m
knative-serving      domainmapping-webhook-fcbd7dff4-fqhnv        1/1     Running   0          69m
knative-serving      net-kourier-controller-55c99987b4-pccst      1/1     Running   0          67m
knative-serving      webhook-544b958c69-s2w8g                     1/1     Running   0          69m
kourier-system       3scale-kourier-gateway-7b89ff5c79-jkd2w      1/1     Running   0          67m
kube-system          coredns-6d4b75cb6d-4v4wt                     1/1     Running   0          69m
kube-system          coredns-6d4b75cb6d-7gvvn                     1/1     Running   0          69m
kube-system          etcd-func-control-plane                      1/1     Running   0          69m
kube-system          kindnet-zx5wm                                1/1     Running   0          69m
kube-system          kube-apiserver-func-control-plane            1/1     Running   0          69m
kube-system          kube-controller-manager-func-control-plane   1/1     Running   0          69m
kube-system          kube-proxy-fhjxb                             1/1     Running   0          69m
kube-system          kube-scheduler-func-control-plane            1/1     Running   0          69m
local-path-storage   local-path-provisioner-6b84c5c67f-l9gnd      1/1     Running   0          69m
```

## Create a new (python) function and invoke it

1. Create the knative function:
```
# func create -l python test-hw
Created python function in /home/vagrant/test-hw
```

2. Take a look around and change the `func.py` code as follows:
```
# cd test-hw

# ls
app.sh  func.py  func.yaml  Procfile  README.md  requirements.txt  test_func.py

# cat func.py
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
# export FUNC_REGISTRY=localhost:50000/kn-user
# func build --push
🙌 Function image built: localhost:50000/kn-user/test-hw:latest
🕕 Pushing function image to the registry "localhost:50000" using the "" user credentials
```

4. Deploy the function to the kind cluster:
```
# func deploy --build=false --push=false
✅ Function deployed in namespace "default" and exposed at URL:
     http://test-hw.default.127.0.0.1.sslip.io
```

5. Invoke the function:
```
# curl http://test-hw.default.127.0.0.1.sslip.io
DevConf.cz 2023!
```

## Fork the base operator github repository and deploy locally


1. Fork the github repository in your repository:
```
https://github.com/luis5tb/devconf-knative-operator
```

2. Clone your fork locally inside the VM, change YOUR_USER by yours
```
$ vagrant ssh
$ sudo su
# cd
# git clone https://github.com/YOUR_USER/devconf-knative-operator.git
```

   In case you want to start an operator from scratch do the next instead
   (change XXX by your user):
```
$ vagrant ssh
$ sudo su
# cd
# mkdir devconf-knative-operator
# cd devconf-knative-operator

# # Create base operator
# operator-sdk init --domain example.com --repo github.com/XXXX/devconf-knative-operator

# # Add API
# operator-sdk create api --group cache --version v1alpha1 --kind KnativeFunction --resource --controller
```


3. Make your modifications
```
# cd devconf-knative-operator

# # Make code modifications
# make manifests
# make generate

# # Check sample function
# cat config/samples/cache_v1alpha1_knativefunction.yaml
```

4. Test your code by deploying it
```
# # First time only
# # Edit config/manager/manager.yaml so that it does not try to download the image if present
# Add, after "image: controller:latest": imagePullPolicy: IfNotPresent

## Then every time you have new code to check do the next
## Increase the version (v0.0.X) as neeeded
# make docker-build IMG="example.com/devconf-knative-operator:v0.0.X"
# kind load docker-image example.com/devconf-knative-operator:v0.0.X --name func
# make deploy IMG="example.com/devconf-knative-operator:v0.0.X"

# # Check the deployment
# kubectl get deployment -n devconf-knative-operator-system

# # Check the pod
# kubectl get pod -n devconf-knative-operator-system
# kubectl logs -f -n devconf-knative-operator-system POD

# # Create the CR to force reconcile loop for function registration
# kubectl apply -f config/samples/cache_v1alpha1_knativefunction.yaml
# # Check the logs
# kubectl logs -f -n devconf-knative-operator-system POD
```

5. Undeploy (and go loop between step 3 and 5 until needed)
```
# kubectl delete -f config/samples/cache_v1alpha1_knativefunction.yaml
# make undeploy
```

[1] https://github.com/knative/func/blob/main/hack/allocate.sh
