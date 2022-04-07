# dagger-flyte

[![asciicast](https://asciinema.org/a/9shHclgS4u46dLA1gIvsh9ATd.svg)](https://asciinema.org/a/9shHclgS4u46dLA1gIvsh9ATd)

## Getting Started (Sandbox Cluster)
- Follow the steps to register the package


```bash
# Install dagger(https://docs.dagger.io/1200/local-dev)
# Install flytectl(https://docs.flyte.org/projects/flytectl/en/latest/index.html)

# Start The Sandbox
flytectl sanbox start

# Add secret in env
export REGISTRY_USER=${YOUR_DOCKER_REGISTER_USERNAME}
export REGISTRY_TOKEN=${YOUR_DOCKER_REGISTER_TOKEN}
export CLIENT_SECRET="SANDBOX"
export CLIENT_ID="SANDBOX"

# Setup is ready, You don't need anything else
dagger project update

# Build & Push image (It will build and push the docker images, If you just want tp build the images then use build in place of push)
dagger do serialize -l debug --log-format plain --with 'actions: params: image_name: "docker.io/evalsocket/dagger-flyte:latest"'

# Register the package (It will first serialize the package and then register it with flyte cluster)
dagger do register -l debug --log-format plain --with 'actions: params: image_name: "docker.io/evalsocket/dagger-flyte:latest"'

# Fast Register the package (It will first serialize the package and then register it with flyte cluster)
dagger do fast_serialize -l debug --log-format plain  --with 'actions: params: image_name: "docker.io/evalsocket/dagger-flyte:latest"'

# Fast Register the package (It will first serialize the package and then register it with flyte cluster)
dagger do fast_register -l debug --log-format plain
```

## Getting Started (Remote Cluster)
- Follow the steps to register the package


```bash
# Install dagger(https://docs.dagger.io/1200/local-dev)

# Add secret in env
export REGISTRY_USER=${YOUR_DOCKER_REGISTER_USERNAME}
export REGISTRY_TOKEN=${YOUR_DOCKER_REGISTER_TOKEN}
export CLIENT_SECRET=${YOUR_FLYTE_CLUSTER_CLIENT_TOKEN}
export CLIENT_ID=${YOUR_FLYTE_CLUSTER_CLIENT_ID}
export FLYTE_ENDPOINT=${YOUR_FLYTE_ENDPOINT}

# Setup is ready, You don't need anything else
dagger project update

# Build & Push image (It will build and push the docker images, If you just want tp build the images then use build in place of push)
dagger do push -l debug --log-format plain --with 'actions: params: endpoint: "dns:///**********"' --with 'actions: params: image_name: "docker.io/evalsocket/dagger-flyte:latest"'

# Register the package (It will first serialize the package and then register it with flyte cluster)
dagger do register -l debug --log-format plain
```
