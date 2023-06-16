# physics-devconf

This repository provides an easy way to deploy a [KinD](https://kind.sigs.k8s.io/) cluster with [Knative](https://knative.dev/) (using [this script](https://github.com/knative/func/blob/main/hack/allocate.sh)) on top of a Fedora 37 VM.

It also provides a couple of sample scripts to deploy a Knative service and a function.

## Goals

 - Get familiar on how to create/test Knative functions
 - Get familiar with the operator SDK

## Index
- [physics-devconf](#physics-devconf)
  - [Goals](#goals)
  - [Index](#index)
  - [Deploy the environment (VM)](#deploy-the-environment-vm)
  - [Access the environment](#access-the-environment)
  - [Create a new (python) function and invoke it](#create-a-new-python-function-and-invoke-it)
  - [Fork the base operator github repository and deploy locally](#fork-the-base-operator-github-repository-and-deploy-locally)
  - [Solution](#solution)
  - [Links](#links)


## Deploy the environment (VM)

The VM requires 4 vCPUs and 6GB of memory. It takes approximately 10 minutes to come up:
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

The provision script installs:
 - Docker
 - Golang
 - Pip
 - Git 
 - Curl
 - Wget
 - Cosign
 - Kubectl
 - [Kn](https://knative.dev/docs/client/install-kn/) - the Knative client
 - [Func](https://knative.dev/docs/functions/install-func/) - Knative functions
 - Kind
 - [Operator-sdk](https://sdk.operatorframework.io/docs/installation/)

## Access the environment

1. Login into the virtual machine just created:
    ```
    $ vagrant ssh
    ```

2. Check if all the pods are running:
    ```
    $ kubectl get pods -A
    NAMESPACE            NAME                                         READY   STATUS    RESTARTS   AGE
    contour-external     contour-56cfd44877-gmzdd                     1/1     Running     0          2m30s
    contour-external     contour-56cfd44877-wj844                     1/1     Running     0          2m30s
    contour-external     contour-certgen-v1.22.0-qbbx6                0/1     Completed   0          2m30s
    contour-external     envoy-4j2vr                                  2/2     Running     0          2m30s
    contour-internal     contour-865fdc98f9-48vv9                     1/1     Running     0          2m29s
    contour-internal     contour-865fdc98f9-l22kw                     1/1     Running     0          2m29s
    contour-internal     contour-certgen-v1.22.0-5t52p                0/1     Completed   0          2m30s
    contour-internal     envoy-vlxrb                                  2/2     Running     0          2m29s
    knative-eventing     eventing-controller-64b4b79c45-bxk6f         1/1     Running     0          4m5s
    knative-eventing     eventing-webhook-86f7dd95db-phc9x            1/1     Running     0          4m5s
    knative-eventing     imc-controller-769d8b7f66-hx2lj              1/1     Running     0          3m33s
    knative-eventing     imc-dispatcher-55979cf74b-8n2w9              1/1     Running     0          3m33s
    knative-eventing     mt-broker-controller-f97f8747-r7nnr          1/1     Running     0          3m21s
    knative-eventing     mt-broker-filter-77c75d69fb-j4972            1/1     Running     0          3m21s
    knative-eventing     mt-broker-ingress-d96f6d8b5-g4ng6            1/1     Running     0          3m21s
    knative-serving      activator-75777fd57c-hwsth                   1/1     Running     0          4m49s
    knative-serving      autoscaler-57d647d6ff-cs2bx                  1/1     Running     0          4m49s
    knative-serving      controller-677995dc7b-9tbmj                  1/1     Running     0          4m48s
    knative-serving      domain-mapping-5676fb7bcf-92xmf              1/1     Running     0          4m48s
    knative-serving      domainmapping-webhook-fcbd7dff4-5v26r        1/1     Running     0          4m48s
    knative-serving      net-contour-controller-847758c4bf-kltdx      1/1     Running     0          2m
    knative-serving      webhook-544b958c69-h7vmz                     1/1     Running     0          4m48s
    kube-system          coredns-6d4b75cb6d-btqsp                     1/1     Running     0          5m16s
    kube-system          coredns-6d4b75cb6d-shbkf                     1/1     Running     0          5m16s
    kube-system          etcd-func-control-plane                      1/1     Running     0          5m35s
    kube-system          kindnet-mr2xx                                1/1     Running     0          5m16s
    kube-system          kube-apiserver-func-control-plane            1/1     Running     0          5m30s
    kube-system          kube-controller-manager-func-control-plane   1/1     Running     0          5m30s
    kube-system          kube-proxy-vpb8z                             1/1     Running     0          5m16s
    kube-system          kube-scheduler-func-control-plane            1/1     Running     0          5m32s
    local-path-storage   local-path-provisioner-6b84c5c67f-575j5      1/1     Running     0          5m16s
    metallb-system       controller-6c58495cbb-j52ls                  1/1     Running     0          3m3s
    metallb-system       speaker-v5hd2                                1/1     Running     0          3m3s
    ```

3. Check if the local registry is running:
    ```
    $ docker ps
    CONTAINER ID   IMAGE                  COMMAND                  CREATED         STATUS         PORTS                                                                          NAMES
    59be051ba43c   registry:2             "/entrypoint.sh /etc…"   2 minutes ago   Up 2 minutes   127.0.0.1:50000->5000/tcp                                                      func-registry
    caf78811a6a9   kindest/node:v1.24.6   "/usr/local/bin/entr…"   4 minutes ago   Up 4 minutes   127.0.0.1:39609->6443/tcp, 127.0.0.1:80->30080/tcp, 127.0.0.1:443->30443/tcp   func-control-plane
    ```


## Create a new (python) function and invoke it

4. Create the Knative function:
    ```
    $ func create -l python test-hw
    Created python function in /home/vagrant/test-hw
    ```

5. Take a look around and change the `func.py` code as follows:
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

6. Build (and push) the function to the internal registry:
    ```
    $ export FUNC_REGISTRY=localhost:50000/kn-user
    $ func build --push
    🙌 Function image built: localhost:50000/kn-user/test-hw:latest
    🕕 Pushing function image to the registry "localhost:50000" using the "" user credentials
    ```

7. Check that the image has been correctly pushed into the internal registry:
    ```
    $ curl localhost:50000/v2/_catalog
    {"repositories":["kn-user/test-hw"]}
    ```

8. Deploy the function to the kind cluster:
    ```
    $ func deploy --build=false --push=false
    ✅ Function deployed in namespace "default" and exposed at URL:
         http://test-hw.default.127.0.0.1.sslip.io
    ```

9. Check that the function has been correctly deployed. A new **Knative service (ksvc)** object is created, which triggers the Knative controllers to create the other k8s objects (deployment and route). After approximately one minute minute the deployment is scaled down to 0 replicas if not used to spare resources:
    ```
    $ kubectl get ksvc
    NAME      URL                                         LATESTCREATED   LATESTREADY     READY   REASON
    test-hw   http://test-hw.default.127.0.0.1.sslip.io   test-hw-00001   test-hw-00001   True

    $ kubectl get deploy
    NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
    test-hw-00001-deployment   0/0     0            0           104s

    $ kubectl get route
    NAME      URL                                         READY   REASON
    test-hw   http://test-hw.default.127.0.0.1.sslip.io   True

    $ kubectl get pods
    (empty if more than a minute has passed)
    ```

10. Invoke the function:
    ```
    $ curl http://test-hw.default.127.0.0.1.sslip.io
    DevConf.cz 2023!
    ```

11. Check that the deployment has been scaled up:
    ```
    $ kubectl get deploy
    NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
    test-hw-00001-deployment   1/1     1            1           3s
    ```


## Fork the base operator github repository and deploy locally


12. Fork [this github repository](https://github.com/luis5tb/devconf-knative-operator) into your github account: `https://github.com/luis5tb/devconf-knative-operator`

13. Clone your fork locally inside the VM (change **YOUR_USER** by yours):
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
    $ operator-sdk create api --group knf --version v1alpha1 --kind KnativeFunction --resource --controller
    ```

14. There are three important files to consider:
   - **controllers/knativefunction_controller.go**: implements the operator reconcile loop
   - **api/v1alpha1/knativefunction_types.go**: the KnativeFunction CRD definition
   - **config/samples/knf_v1alpha1_knativefunction.yaml**: an example KnativeFunction CRD

15. Let's take a look at **api/v1alpha1/knativefunction_types.go**, as you can see it defines an example `Foo` field:
    ```golang
    ...
    type KnativeFunctionSpec struct {
        // Foo is an example field of KnativeFunction. Edit knativefunction_types.go to remove/update
        Foo string `json:"foo,omitempty"`
    }
    ...
    ```

16. Let's modify the operator reconcyle loop in **controllers/knativefunction_controller.go**:
    
    Before:
    ```golang
    func (r *KnativeFunctionReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
        _ = log.FromContext(ctx)

        // TODO(user): your logic here

        return ctrl.Result{}, nil
    }
    ```
    After:
    ```golang
    func (r *KnativeFunctionReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
        log := log.FromContext(ctx)

        function := &knfv1alpha1.KnativeFunction{}
        log.Info("Received a request to create a new knativefunction", "Foo =", function.Spec.Foo)

        return ctrl.Result{}, nil
    }
    ```


    ```
    $ cd devconf-knative-operator

    # Make code modifications
    $ go mod tidy
    $ make manifests
    $ make generate

    # Check sample function
    $ cat config/samples/knf_v1alpha1_knativefunction.yaml
    ```

17. Test your code by deploying it. You will need two terminals, **T1** and **T2**.

    [**T1**] First option is simply doing `make install run`:
    ```
    $ make install run
    test -s /home/vagrant/devconf-knative-operator/bin/controller-gen && /home/vagrant/devconf-knative-operator/bin/controller-gen --version | grep -q v0.11.1 || \
    GOBIN=/home/vagrant/devconf-knative-operator/bin go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.11.1
    /home/vagrant/devconf-knative-operator/bin/controller-gen rbac:roleName=manager-role crd webhook paths="./..." output:crd:artifacts:config=config/crd/bases
    /home/vagrant/devconf-knative-operator/bin/kustomize build config/crd | kubectl apply -f -
    Warning: Detected changes to resource knativefunctions.knf.example.com which is currently being deleted.
    customresourcedefinition.apiextensions.k8s.io/knativefunctions.knf.example.com configured
    /home/vagrant/devconf-knative-operator/bin/controller-gen object:headerFile="hack/boilerplate.go.txt" paths="./..."
    go fmt ./...
    go vet ./...
    go run ./main.go
    I0616 08:11:27.582792   10567 request.go:682] Waited for 1.041837981s due to client-side throttling, not priority and fairness, request: GET:https://127.0.0.1:44399/apis/networking.internal.knative.dev/v1alpha1?timeout=32s
    2023-06-16T08:11:27Z	INFO	controller-runtime.metrics	Metrics server is starting to listen	{"addr": ":8080"}
    2023-06-16T08:11:27Z	INFO	setup	starting manager
    2023-06-16T08:11:27Z	INFO	Starting server	{"path": "/metrics", "kind": "metrics", "addr": "[::]:8080"}
    2023-06-16T08:11:27Z	INFO	Starting server	{"kind": "health probe", "addr": "[::]:8081"}
    2023-06-16T08:11:27Z	INFO	Starting EventSource	{"controller": "knativefunction", "controllerGroup": "knf.example.com", "controllerKind": "KnativeFunction", "source": "kind source: *v1alpha1.KnativeFunction"}
    2023-06-16T08:11:27Z	INFO	Starting Controller	{"controller": "knativefunction", "controllerGroup": "knf.example.com", "controllerKind": "KnativeFunction"}
    2023-06-16T08:11:27Z	INFO	Starting workers	{"controller": "knativefunction", "controllerGroup": "knf.example.com", "controllerKind": "KnativeFunction", "worker count": 1}
    ```

    [**T1**] Second option, if you want to deploy your controller as a container too:
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

    # Check the logs
    $ kubectl logs -f -n devconf-knative-operator-system POD
    ```

18. [**T2**] In a **second terminal** create a sample CRD:
    ```yaml
    $ cat <<EOF | kubectl apply -f -
    ---
    apiVersion: knf.example.com/v1alpha1
    kind: KnativeFunction
    metadata:
    labels:
        app.kubernetes.io/name: knativefunction
        app.kubernetes.io/instance: knativefunction-sample
        app.kubernetes.io/part-of: devconf-knative-operator
        app.kubernetes.io/managed-by: kustomize
        app.kubernetes.io/created-by: devconf-knative-operator
    name: knativefunction-sample
    spec:
       foo: test
    EOF
    ```

19. [**T1**] In the **first terminal** you should see something like:
    ```
    2023-06-16T08:12:54Z	INFO	Received a request to create a new knativefunction	{"controller": "knativefunction", "controllerGroup": "knf.example.com", "controllerKind": "KnativeFunction", "KnativeFunction": {"name":"knativefunction-sample","namespace":"default"}, "namespace": "default", "name": "knativefunction-sample", "reconcileID": "9be34733-bca6-4134-bf6d-8f0ed69106bd", "Foo =": "test"}
    ```

20. Undeploy and iterate (and go loop between step 14 and 19 until needed). If first option was used, just stop the make install run, if the containerized option was chosen, then the next:
    ```
    $ kubectl delete -f config/samples/knf_v1alpha1_knativefunction.yaml
    $ make undeploy
    ```

## Solution

21. Deploy a CR to force the controller to reconcile and get the function deployed. First you need to edit the `config/samples/knf_v1alpha1_knativefunction.yaml` with the desired options:
    ```
    # Get the previously created function docker image information, with digest
    $ kubectl get nodes -oyaml | grep test-hw
      - localhost:50000/kn-user/test-hw@sha256:79c4568eedb9f3366c6ee6b72980eec2aff9a80796328888e10f834c00beb51f

    # Modify the config/samples/knf_v1alpha1_knativefunction.yaml using the above as image
    $ cat config/samples/knf_v1alpha1_knativefunction.yaml
    apiVersion: knf.example.com/v1alpha1
    kind: KnativeFunction
    metadata:
      labels:
        app.kubernetes.io/name: knativefunction
        app.kubernetes.io/instance: knativefunction-sample
        app.kubernetes.io/part-of: devconf-knative-operator
        app.kubernetes.io/managed-by: kustomize
        app.kubernetes.io/created-by: devconf-knative-operator
      name: knativefunction-sample
    spec:
      name: test-function
      image: localhost:50000/kn-user/test-hw@sha256:79c4568eedb9f3366c6ee6b72980eec2aff9a80796328888e10f834c00beb51f
      maxscale: "2"
      minscale: "1"
      concurrency: 1
    ```

    And then deploy/update/remote it with:
    ```
    # Create the CR to force reconcile loop for function registration
    $ kubectl apply -f config/samples/knf_v1alpha1_knativefunction.yaml

    # Update the config/samples/knf_v1alpha1_knativefunction.yaml, for instance changing the minScale to 0 and re-apply:
    $ kubectl apply -f config/samples/knf_v1alpha1_knativefunction.yaml

    # Delete the CR to remove the function
    $ kubectl delete -f config/samples/knf_v1alpha1_knativefunction.yaml
    ```
    
22. To check the operator did its job, beside seeing the `make install run` logs, you can check as before:
    ```
    $ kubectl get ksvc
    NAME           URL                                                LATESTCREATED        LATESTREADY     READY   REASON
    test-hw        http://test-hw.default.127.0.0.1.sslip.io          test-hw-00001        test-hw-00001   True
    test-function  http://test-function.default.127.0.0.1.sslip.io    test-function-00001  test-function-00001      True 

    $ kubectl get deploy
    NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
    test-hw-00001-deployment         0/0     0            0           20m
    test-function-00001-deployment   0/0     0            0           1m38s

    $ kubectl get route
    NAME           URL                                              READY   REASON
    test-hw        http://test-hw.default.127.0.0.1.sslip.io        True
    test-function  http://test-function.default.127.0.0.1.sslip.io  True 
    
    $ kubectl get knativefunction
    NAME                     AGE
    knativefunction-sample   5m8s
    
    $ kubectl get knativefunction knativefunction-sample -o yaml
    ...
    ...
    status:
      deployed: true
      route:  http://test-function.default.127.0.0.1.sslip.io

    $ kubectl get pods
    (empty if more than a minute has passed)
    
    $ curl http://test-function.default.127.0.0.1.sslip.io
    DevConf.cz 2023!
    
    $ kubectl get pods
    NAME                                              READY   STATUS    RESTARTS   AGE
    test-function-00001-deployment-77f8b87654-6krps   2/2     Running   0          6s
    ```

## Links

 - [Knative documentation](https://knative.dev/docs/)
 - [Operator SDK - Go Operator tutorial](https://sdk.operatorframework.io/docs/building-operators/golang/tutorial/)
 - [Intermediate Kubernetes Operators on IBM Developer Skills Network](https://courses.course-dev.skills.network/courses/course-v1:IBMSkillsNetwork+CO0201EN+2021T1/course/)

