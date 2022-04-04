package flyte

import (
	"dagger.io/dagger"
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
		}
        network: "unix:///var/run/docker.sock": connect: dagger.#Socket
        env: {
            REGISTRY_USER: string
            REGISTRY_TOKEN: dagger.#Secret
            CLIENT_SECRET: dagger.#Secret
        }
	}
	actions: {
		params: {
		  image: {
			  ref: string | *"docker.io/evalsocket/dagger-flyte"
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
          	dest: "\(params.image.ref):\(params.image.tag)"
          	auth: {
            	username: client.env.REGISTRY_USER
            	secret: client.env.REGISTRY_TOKEN
          	}
		}
		serialize: docker.#Run & {
			input: build.output
			workdir: "/root"
			command: {
				name: "pyflyte"
				args: ["--pkgs", params.packages, "package", "--image", "\(params.image.ref):\(params.image.tag)"]
			}
			export: files: "/root/flyte-package.tgz": string
		}
		register: bash.#Run & {
			input: serialize.output
			script: contents: "echo ${CLIENT_SECRET} >> /tmp/secret && flytectl register files --archive -p ${PROJECT} -d ${DOMAIN} flyte-package.tgz --config=${CONFIG_FILE} --admin.clientSecretLocation=/tmp/secret --version=${VERSION}"
			env: {
				PROJECT: params.project
				DOMAIN: params.domain
				CONFIG_FILE: params.flytectlConfig
				CLIENT_SECRET: client.env.CLIENT_SECRET
				VERSION: params.image.tag
			}
		}
	}
}
