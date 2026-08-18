# Secure Local Registry

Run an authenticated Docker registry at `<registry-host>:9050` using `registry:3`.

## 1. Create credentials

```bash
chmod +x generate-htpasswd.sh
./generate-htpasswd.sh <username> <password>
```

This writes the bcrypt-protected credentials to `auth/htpasswd`. Run it again to replace the credentials.

## 2. Start the registry

```bash
docker compose up -d
```

## 3. Push and pull an image

```bash
docker login <registry-host>:9050
docker pull alpine:latest
docker tag alpine:latest <registry-host>:9050/my-alpine:latest
docker push <registry-host>:9050/my-alpine:latest
docker rmi <registry-host>:9050/my-alpine:latest
docker pull <registry-host>:9050/my-alpine:latest
```

To log in with Podman:

```bash
podman login <registry-host>:9050 --username <username> --password <password> --tls-verify=false
```

## 4. Browse images

Open `http://<registry-host>:9051` and authenticate with the registry username and password.

Registry data is stored in `data/`. Stop it with:

```bash
docker compose down
```

For access without TLS, configure each Docker client to trust `<registry-host>:9050` as an insecure registry. Docker permits plain HTTP automatically only for `localhost`.
