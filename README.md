# container_setup_scripts

Scripts to set up Docker and bootstrap a Kubernetes cluster on Ubuntu.

> Run scripts as a standard (non-root) user. `sudo` is invoked internally where needed.

## Docker

Install Docker Engine, CLI, containerd, Buildx, and Compose:

```bash
bash docker/install-docker.sh
```

verify the installation by running the `hello-world` image:

```bash
docker run --rm hello-world
```

### Docker References

- <https://docs.docker.com/engine/install/ubuntu/>
- <https://docs.docker.com/engine/install/linux-postinstall/>


## Kubernetes

Bootstrap a Kubernetes `1.35.0` cluster using `kubeadm`, `containerd`, and Calico `v3.31.4`.

### 1. Every node

Installs containerd, kubeadm, kubelet, and kubectl:

```bash
bash kubernetes/common-setup.sh
```

### 2. Control plane only

Initialises the cluster and installs Calico, then prints the worker join command:

```bash
bash kubernetes/control-plane-init.sh
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

### 4. Verify the cluster

Check that all nodes are `Ready` and system pods are running:

```bash
kubectl get nodes
kubectl get pods -A
```

### 5. Smoke test — nginx

#### Deploy

```bash
kubectl apply -f kubernetes/nginx.yaml
kubectl rollout status deployment/nginx
```

#### Test

Once the rollout is complete, confirm the pod is running and hit nginx on port `30080` of any node:

```bash
kubectl get pods
curl http://<any-node-ip>:30080
```

You should receive the nginx welcome page HTML.

#### Tear down

```bash
kubectl delete -f kubernetes/nginx.yaml
```

### Kubernetes References

- <https://gist.github.com/anantharaman93/81b55a23b262ed46d5ea5afd777938fa>
- <https://github.com/piyushsachdeva/CKA-2024/blob/main/Resources/Day27/readme.md>
- <https://github.com/techiescamp/kubeadm-scripts>
