package golangcilint

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
)

#DefaulGolangCILintImage: docker.#Pull & {
	source: "golangci/golangci-lint:v1.40.1-alpine"
}

// Lint a go package
#Lint: {
	source: dagger.#FS

	_image: #DefaulGolangCILintImage

	deadline: string | *"5m"

	extraArgs: string | *""

	_sourcePath: "/src"

	docker.#Run & {
		input:   _image.output
		workdir: "/src"
		command: {
			name: "sh"
			flags: "-c": "golangci-lint run --deadline $DEADLINE $EXTRA_ARGS"
		}
		env: {
			DEADLINE: deadline
			EXTRA_ARGS: extraArgs
		}
		mounts: {
			"source": {
				dest:     _sourcePath
				contents: source
			}
		}
	}
}
