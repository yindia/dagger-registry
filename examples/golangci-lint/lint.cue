package flyte

import (
	"dagger.io/dagger"
	"github.com/evalsocket/golangcilint"
)

dagger.#Plan & {
	client: {
		filesystem: {
			".": read: {
				contents: dagger.#FS
			}
		}
        network: "unix:///var/run/docker.sock": connect: dagger.#Socket
	}
	actions: {
		lint: golangcilint.#Lint & {
			source: client.filesystem.".".read.contents
			deadline: "5m"
			package_path: "."
			extraArgs: ""
		}
	}
}
