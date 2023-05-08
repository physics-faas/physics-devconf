# physics-devconf

This repository provides an easy way to deploy a [KinD](https://kind.sigs.k8s.io/) cluster with [Knative](https://knative.dev/) (using [[1]](https://github.com/knative/func/blob/main/hack/allocate.sh)) on
top of a Fedora 37 VM.

It also provides a couple of sample scripts to deploy a Knative service and a function.

## Deploy the environment (VM)

    $ vagrant up

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

[1] https://github.com/knative/func/blob/main/hack/allocate.sh
