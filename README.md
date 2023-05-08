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


1. Create the knative function:
```
# func create -l python test-hw
Created python function in /home/vagrant/test-hw
```

2. Take a look and change the code as follows:
```python
# cd test-hw

# cat func.py
from parliament import Context
from flask import Request
import json


# parse request body, json data or URL query parameters
def payload_print(req: Request) -> str:
    if req.method == "GET":
        return "DevConf.cz 2023!"


# pretty print the request to stdout instantaneously
def pretty_print(req: Request) -> str:
    ret = str(req.method) + ' ' + str(req.url) + ' ' + str(req.host) + '\n'
    for (header, values) in req.headers:
        ret += "  " + str(header) + ": " + values + '\n'

    if req.method == "POST":
        ret += "Request body:\n"
        ret += "  " + payload_print(req) + '\n'

    elif req.method == "GET":
        ret += "URL Query String:\n"
        ret += "  " + payload_print(req) + '\n'

    return ret

 
def main(context: Context):
    """ 
    Function template
    The context parameter contains the Flask request object and any
    CloudEvent received with the request.
    """

    # Add your business logic here
    print("Received request")

    if 'request' in context.keys():
        ret = pretty_print(context.request)
        print(ret, flush=True)
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
