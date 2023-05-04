# create a function
func create -l python function-hw
docker images

# build a function
cd function-hw
export FUNC_REGISTRY=localhost:50000/function
# ensure the function is not only built but also pushed
func build --push
docker images


# deploy a function wihourt pushing the image again
func deploy --registry localhost:50000/function --build=false --push=false
docker images

# invoke function
func invoke
# or
curl  -d '{"message": "hello"}' -H "Content-Type: application/json"  -X POST http://function-hw.default.127.0.0.1.sslip.io

