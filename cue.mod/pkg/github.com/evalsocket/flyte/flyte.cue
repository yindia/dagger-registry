package flyte

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
	"universe.dagger.io/bash"
)

#Credentials: {
	username?: string
	secret?: dagger.#Secret
	clientId?: dagger.#Secret
	clientSecret?: dagger.#Secret
}

#Default: "golang:alpine"

#Build: {
	docker.#Build & {
		steps: [
			docker.#Pull & {
				source: #Default
			},
			docker.#Run & {
				command: {
					name: "apk"
					args: ["add", "curl", "bash"]
				}
			},
			bash.#Run & {
				workdir: "/src"
				script: contents: #"""
					curl -sL https://ctl.flyte.org/install | bash -s -- -b /usr/local/bin
					"""#
			},
		]
	}
}

#Serialize: {

	src: dagger.#FS

	package_path: string

	workdir: string | *"/root"

    image_name: string

	credentials: #Credentials

	build: docker.#Dockerfile & {
		source: src
	}

	push: docker.#Push & {
		image: build.output
		dest: image_name
		auth: {
			username: credentials.username
			secret: credentials.secret
		}
	}

	serialize_package: {
		serialize: docker.#Run & {
			input: build.output
			workdir: workdir
			command: {
				name: "pyflyte"
				args: ["--pkgs", package_path, "package", "--image", image_name, "-f"]
			}
			export: files: {
				"\(workdir)/flyte-package.tgz": _ & {
					contents: "\(workdir)/flyte-package.tgz"
				},
			}
		}
		contents: core.#Subdir & {
			input: serialize.output.rootfs
			path:  "\(workdir)/flyte-package.tgz"
		}
	}
}

#Fastserialize: {

	src: dagger.#FS

	package_path: string

	workdir: string | *"/root"

    image_name: string

	build: docker.#Dockerfile & {
		source: src
	}

	serialize_package: {
		serialize: docker.#Run & {
			input: build.output
			workdir: workdir
			command: {
				name: "pyflyte"
				args: ["--pkgs", package_path, "package", "--image", image_name, "-f", "--fast"]
			}
			export: files: {
				"\(workdir)/flyte-package.tgz": _ & {
					contents: "\(workdir)/flyte-package.tgz"
				},
			}
		}
		contents: core.#Subdir & {
			input: serialize.output.rootfs
			path:  "\(workdir)/flyte-package.tgz"
		}
	}
}

#Register: {
	_build: #Build

	source?: dagger.#FS
	flytectlConfig?: dagger.#FS
	domain: string
	project: string
	version: string | *"v1"
	endpoint: string
	config: string | *"config.yaml"

	credentials: #Credentials

	register: bash.#Run & {
		input: _build.output
		script: contents: "ls -al && 	echo ${CLIENT_SECRET} >> /tmp/secret && flytectl register files --archive -p ${PROJECT} -d ${DOMAIN} /root/flyte-package.tgz --config=/root/config/config.yaml --admin.endpoint=${FLYTE_ENDPOINT} --admin.clientId=${CLIENT_ID}  --admin.clientSecretLocation=/tmp/secret --version=${VERSION}"
		env: {
			PROJECT: project
			DOMAIN: domain
			CLIENT_SECRET: credentials.clientSecret
			CLIENT_ID: credentials.clientId
			VERSION: version
			FLYTE_ENDPOINT: endpoint
		}
		workdir: "/root"
		mounts: {
			flyte: {
				dest:     "/root"
				contents: source
			}
			flyteconfig: {
				dest:     "/root/config"
				contents: flytectlConfig
			}
		}
	}
}
