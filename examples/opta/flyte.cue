package optadeployment

import (
	"dagger.io/dagger"
	"github.com/evalsocket/opta"
)

dagger.#Plan & {
	client: {
		filesystem: {
			".": read: {
				contents: dagger.#FS
				include: [
					"opta-files",
					"opta.cue",
				]
			}
		}
        network: "unix:///var/run/docker.sock": connect: dagger.#Socket
	}
	// NOTE: Opta dagger package assume that you are running dagger on buildkit remote(In k8s) and buildkit deployment has correct service account
	actions: {
		params: {
		  dest: string | *"evalsocket/testing:latest"
		  configFile: string | *"opta.yaml"
		  environment: string | *"staging"
		  opta_ction: string | *"apply"
		  extraArgs: string | *""
		}
		apply: opta.#Action & {
			source: client.filesystem.".".read.contents
			action: params.optaAction
			environment: params.environment
			extraArgs: params.extraArgs
			configFile: params.configFile
		}
	}
}
