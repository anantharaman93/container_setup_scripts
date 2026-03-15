# container_setup_scripts

Scripts to bootstrap a Kubernetes `1.35.0` cluster on Ubuntu/Debian using `kubeadm`, `containerd`, and Calico `v3.31.4`.

> Run scripts as a standard (non-root) user. `sudo` is invoked internally where needed.

## Usage

### 1. Every node

Installs containerd, kubeadm, kubelet, and kubectl:

```bash
bash setup_scripts/common-setup.sh
```

### 2. Control plane only

Initialises the cluster and installs Calico, then prints the worker join command:

```bash
bash setup_scripts/control-plane-init.sh
```

### 3. Each worker node

After running common setup, join using the command printed in step 2:

```bash
sudo kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

Then, from the control plane, label the node so it appears as a worker in `kubectl get nodes`:

```bash
kubectl label node <worker-machine-name> node-role.kubernetes.io/worker=worker
```

### 4. Smoke test — nginx

#### Deploy

```bash
kubectl apply -f manifests/nginx.yaml
kubectl rollout status deployment/nginx
```

#### Test

Once the rollout is complete, hit nginx on port `30080` of any node:

```bash
curl http://<any-node-ip>:30080
```

You should receive the nginx welcome page HTML.

#### Tear down

```bash
kubectl delete -f manifests/nginx.yaml
```
