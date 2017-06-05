# WIP Kubernetes setup instructions

1) Set up [minikube](https://github.com/kubernetes/minikube) (also see
optional / experimental native Linux support instructions below).
2) Start the mediawiki-containers Kubernetes cluster. From within the minikube
environment (native shell when using native Docker):

```
# Clone k8s branch of mediawiki-containers
git clone git@github.com:wikimedia/mediawiki-containers.git
cd mediawiki-containers
git checkout k8s

# start cluster
kubectl apply -f k8s-alpha.yml

# find the minikube IP
minikube ip
# find the service port
kubectl get service

# Optionally, check out the Kubernetes dashboard at http://<ip>:8080/ui/
# Check out your wiki at http://<ip>:<port>/index.php/Main_Page
```

## Optional: Native docker / kubernetes on Debian sid

This [brand new
feature](https://github.com/kubernetes/minikube/commit/ccb0fb3bd2dddbb172e00197d7ba5e7d3aaf9e0f)
(as of May 31st, 2017) in minikube skips virtualization, and instead directly
uses docker & localkube on Linux hosts. As a result, resource utilization is
significantly reduced.

```
git clone https://github.com/kubernetes/minikube.git
cd minikube
make
sudo ln -s `pwd`/out/* /usr/local/bin
sudo ln -s /etc/systemd/system /usr/lib/systemd/system # minikube assumes non-etc location
sudo CHANGE_MINIKUBE_NONE_USER=true minikube start --vm-driver=none --use-vendored-driver
```
