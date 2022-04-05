package flyte

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
	"universe.dagger.io/bash"
)

dagger.#Plan & {
	client: {
		filesystem: {
			".": read: {
				contents: dagger.#FS
				exclude: [
					"README.md",
					"flyte.cue",
					"LICENSE",
				]
			}
			".": write: {
				contents: actions.serialize.contents.output
			}
		}
        network: "unix:///var/run/docker.sock": connect: dagger.#Socket
        env: {
            REGISTRY_USER: string
            REGISTRY_TOKEN: dagger.#Secret
            CLIENT_SECRET: dagger.#Secret
            CLIENT_ID: dagger.#Secret
            FLYTE_ENDPOINT: dagger.#Secret
        }
	}
	actions: {
		params: {
		  image: {
			  ref: string | *"dagger-flyte"
			  tag: string | *"latest"
		  }
		  packages: string | *"flyte.workflows"
		  project: string | *"flytesnacks"
		  domain: string | *"development"
		  flytectlConfig: string | *"config.yaml"
		}
		build: docker.#Dockerfile & {
			source: client.filesystem.".".read.contents
		}
		push: docker.#Push & {
			image: build.output
          	dest: "\(client.env.REGISTRY_USER)/\(params.image.ref):\(params.image.tag)"
          	auth: {
            	username: client.env.REGISTRY_USER
            	secret: client.env.REGISTRY_TOKEN
          	}
		}
		serialize: {
			serialize_package: docker.#Run & {
				input: build.output
				workdir: "/root"
				command: {
					name: "pyflyte"
					args: ["--pkgs", params.packages, "package", "--image", "\(params.image.ref):\(params.image.tag)", "-f"]
				}
				export: files: {
					"/root/flyte-package.tgz": _ & {
						contents: "/root/flyte-package.tgz"
					},
				}
			}

			contents: core.#Subdir & {
				input: serialize_package.output.rootfs
				path:  "/root/flyte-package.tgz"
			}
		}
	    // TODO(Yuvraj) Currently Fast Register needs more configuration for blob storage, Will work without any issue after https://github.com/flyteorg/flyte/issues/2263
		register: bash.#Run & {
			input: serialize.serialize_package.output
			workdir: "/root"
			script: contents: "echo ${CLIENT_SECRET} >> /tmp/secret && flytectl register files --archive -p ${PROJECT} -d ${DOMAIN} flyte-package.tgz --config=${CONFIG_FILE} --admin.endpoint=${FLYTE_ENDPOINT} --admin.clientId=${CLIENT_ID}  --admin.clientSecretLocation=/tmp/secret --version=${VERSION}"
			env: {
				PROJECT: params.project
				DOMAIN: params.domain
				CONFIG_FILE: params.flytectlConfig
				CLIENT_SECRET: client.env.CLIENT_SECRET
				CLIENT_ID: client.env.CLIENT_ID
				VERSION: params.image.tag
				FLYTE_ENDPOINT: client.env.FLYTE_ENDPOINT
			}
		}
	}
}
