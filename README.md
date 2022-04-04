# dagger-flyte

[![asciicast](https://asciinema.org/a/9shHclgS4u46dLA1gIvsh9ATd.svg)](https://asciinema.org/a/9shHclgS4u46dLA1gIvsh9ATd)

## Getting Started
- Follow the steps to register the package

```bash
# Install dagger(https://docs.dagger.io/1200/local-dev)

# Add secret in env
export REGISTRY_USER=${YOUR_DOCKER_REGISTER_USERNAME}
export REGISTRY_TOKEN=${YOUR_DOCKER_REGISTER_TOKEN}
export CLIENT_SECRET=${YOUR_FLYTE_CLUSTER_CLIENT_TOKEN}
export CLIENT_ID=${YOUR_FLYTE_CLUSTER_CLIENT_ID}
export FLYTE_ENDPOINT=${YOUR_FLYTE_ENDPOINT}

# Update the flyte cluster url & clientID in your config.yaml

# Setup is ready, You don't need anything else
dagger project update

# Build & Push image (It will build and push the docker images, If you just want tp build the images then use build in place of push)
dagger do push -l debug --log-format plain --with 'actions: params: image: tag: "v0.0.4"'

# Register the package (It will first serialize the package and then register it with flyte cluster)
dagger do register -l debug --log-format plain --with 'actions: params: image: tag: "v0.0.4"' 

# Fast Register the package (It will first fast serialize the package and then fast register it with flyte cluster)
# Fast Register will not work because of storage, Waiting for the issue https://github.com/flyteorg/flyte/issues/2263
dagger do fast_register -l debug --log-format plain --with 'actions: params: image: tag: "v0.0.4"' 
```

NOTE: Currently It doesn't support sandbox because of some limitation[WIP] 
