package flyte

import (
	"dagger.io/dagger"
	"github.com/evalsocket/flyte"
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
			"./": read: {
				contents: dagger.#FS
				include: [
					"config.yaml",
				]
			}
			".": write: {
				contents: actions.serialize.serialize_package.contents.output
			}
			"./": write: {
				contents: actions.fast_serialize.serialize_package.contents.output
			}
		}
        network: "unix:///var/run/docker.sock": connect: dagger.#Socket
        env: {
            REGISTRY_USER: string
            REGISTRY_TOKEN: dagger.#Secret
            CLIENT_SECRET: dagger.#Secret
            CLIENT_ID: dagger.#Secret
        }
	}
	actions: {
		params: {
		  dest: string | *"docker.io/evalsocket/dagger-flyte:latest"
		  packages: string | *"flyte.workflows"
		  project: string | *"flytesnacks"
		  domain: string | *"development"
		  config: string | *"config.yaml"
		  version: string | *"v1"
		  endpoint: string | *"dns:///127.0.0.1:30081"
		}
		serialize: flyte.#Serialize & {
			src: client.filesystem.".".read.contents
			image_name: params.dest
			package_path: params.packages
			credentials: flyte.#Credentials & {
				username: client.env.REGISTRY_USER
				secret: client.env.REGISTRY_TOKEN
			}
		}
		fast_serialize: flyte.#Fastserialize & {
			src: client.filesystem.".".read.contents
			image_name: params.dest
			package_path: params.packages
		}
		register: flyte.#Register & {
			source: client.filesystem.".".write.contents
			flytectlConfig: client.filesystem."./".read.contents
			domain: params.domain
			project: params.project
			endpoint: params.endpoint
			version: params.version
			credentials: flyte.#Credentials & {
				clientId: client.env.CLIENT_ID
				clientSecret: client.env.CLIENT_SECRET
			}
		}
		fast_register: flyte.#Register & {
			source: client.filesystem."./".write.contents
			flytectlConfig: client.filesystem."./".read.contents
			domain: params.domain
			project: params.project
			endpoint: params.endpoint
			version: params.version
			credentials: flyte.#Credentials & {
				clientId: client.env.CLIENT_ID
				clientSecret: client.env.CLIENT_SECRET
			}
		}
	}
}
