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

- <https://get.docker.com/>
- <https://docs.docker.com/engine/install/ubuntu/>
- <https://docs.docker.com/engine/install/linux-postinstall/>

## Kubernetes

Bootstrap a Kubernetes `1.35.0` cluster using `kubeadm`, `containerd`, and Calico `v3.31.4`.

The cluster uses `172.16.0.0/16` for pod addresses; choose a CIDR that does not overlap node,
Service, VPN, or corporate networks before changing it.

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

### 6. Tear down the entire cluster

Run the worker-node steps first. Run the control-plane steps last. These commands remove the
Kubernetes cluster state and Calico CNI state, but leave the installed packages and containerd in
place so the cluster can be bootstrapped again.

#### Each worker node

From the control plane, optionally drain each worker before resetting it:

```bash
kubectl drain <worker-machine-name> --ignore-daemonsets --delete-emptydir-data
```

Then, on that worker node:

```bash
sudo kubeadm reset --force
sudo rm -rf /etc/cni/net.d
sudo ip link delete vxlan.calico 2>/dev/null || true
sudo ip link delete tunl0 2>/dev/null || true
for iface in $(ip -o link show | awk -F': ' '$2 ~ /^cali/ {sub(/@.*/, "", $2); print $2}'); do
	sudo ip link delete "$iface" 2>/dev/null || true
done
```

#### Control-plane node

After every worker has been reset, run the following on the control-plane node:

```bash
sudo kubeadm reset --force
sudo rm -rf /etc/cni/net.d
sudo ip link delete vxlan.calico 2>/dev/null || true
sudo ip link delete tunl0 2>/dev/null || true
for iface in $(ip -o link show | awk -F': ' '$2 ~ /^cali/ {sub(/@.*/, "", $2); print $2}'); do
	sudo ip link delete "$iface" 2>/dev/null || true
done
rm -rf "$HOME/.kube"
```

If this machine will no longer manage the cluster, remove the local Calico manifest downloaded by
the bootstrap script as well:

```bash
rm -f custom-resources.yaml
```

`kubeadm reset` does not remove `kubeconfig` files, CNI configuration, or network interfaces. The
extra cleanup is needed before recreating this Calico-based cluster, especially when changing the
pod network CIDR.

### Kubernetes References

- <https://gist.github.com/anantharaman93/81b55a23b262ed46d5ea5afd777938fa>
- <https://github.com/piyushsachdeva/CKA-2024/blob/main/Resources/Day27/readme.md>
- <https://github.com/techiescamp/kubeadm-scripts>

### TODOs

- <https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#check-required-ports>

## Other Components

### Secure Local Registry

See [`registry/README.md`](registry/README.md).
