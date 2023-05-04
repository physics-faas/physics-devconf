pip install yq

go env -w GO111MODULE=auto
go get github.com/knative/func
cd $(go env GOPATH)/src/github.com/knative/func

pushd hack
./allocate.sh
popd

cat <<EOF | sudo tee /etc/docker/daemon.json
{"insecure-registries": ["localhost:50000"]}
EOF
