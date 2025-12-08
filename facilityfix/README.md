# facilityfix

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Docker Build (optional)

You can build a Docker image that serves the built Flutter web app with nginx:

- Recommended (build from inside this folder):

```bash
docker build -t facilityfixfrontend .
```

- Alternative (run from the repository root):

```bash
docker build -f facilityfix/Dockerfile -t facilityfixfrontend facilityfix
```

Note: The Dockerfile expects the Flutter project files to be located at the build context root. If you run the build from the repository root make sure to pass `facilityfix` as the final build-context argument as shown above.

## Run & Deploy

Run the container locally using Docker:

```bash
docker run --rm -p 8080:80 facilityfixfrontendweb
```

Run using Docker Compose (see `docker-compose.yml`):

```bash
docker-compose up -d
```

Create a systemd service on a Linux host to keep the container running (see `deploy/facilityfixfrontend.service`):

1. Copy `deploy/facilityfixfrontend.service` to `/etc/systemd/system/facilityfixfrontend.service` on the server.
2. Edit the `ExecStart` line to point to your Docker image (and set the image tag).
3. Reload and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now facilityfixfrontend
```

To deploy on Google Cloud Run, follow Cloud Run instructions in this repository root README or use the example commands in the repo's documentation.

