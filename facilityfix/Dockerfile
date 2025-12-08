# Build stage
FROM ubuntu:22.04 AS build

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
RUN git clone https://github.com/flutter/flutter.git --depth 1 -b stable /flutter
ENV PATH="/flutter/bin:${PATH}"

# Run flutter doctor to complete setup
RUN flutter doctor

# Copy pubspec files
# NOTE: This Dockerfile expects the project's Flutter files to be in the build context root.
# If you run `docker build` from the repository root, the path would be `facilityfix/pubspec.yaml`.
# When running `docker build` from inside the `facilityfix` folder, use `pubspec.yaml` directly.
COPY pubspec.yaml pubspec.lock* ./

# Get dependencies
RUN flutter pub get

# Copy the entire Flutter project
# The Docker context should include the Flutter project files; when you run
# `docker build -t facilityfixforntend .` from inside `facilityfix`, this copies the current folder.
COPY . ./

# Build the Flutter web app
RUN flutter build web --release

# Serve stage
FROM nginx:alpine

# Copy built web app to nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

## Optional deployment artifacts removed from Dockerfile
## The systemd unit file and docker-compose.yml were accidentally added into this Dockerfile.
## See `deploy/facilityfixfrontend.service` and `docker-compose.yml` in this folder for deployment examples.