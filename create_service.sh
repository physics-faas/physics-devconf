cat <<EOF | sudo tee hello.yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: hello
spec:
  template:
    spec:
      containers:
        - image: gcr.io/knative-samples/helloworld-go
          ports:
            - containerPort: 8080
          env:
            - name: TARGET
              value: "World"
EOF

kn service list
kubectl apply -f hello.yaml
kn service list
kubectl get ksvc
kubectl get pods

echo "Accessing URL $(kn service describe hello -o url)"
curl "$(kn service describe hello -o url)"
