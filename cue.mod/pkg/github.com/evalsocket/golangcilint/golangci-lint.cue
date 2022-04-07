package golangcilint

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

#DefaulGolangCILintImage: docker.#Pull & {
	source: ""
}

// Lint a go package
#Lint: {
	source: dagger.#FS

	_image: #DefaulGolangCILintImage

	deadline: string | *"5m"

	extraArgs:  string | *"-v"

	package:  string | *"./..."

	_sourcePath: "/src"

	docker.#Run & {
		input:   _image.output
		workdir: "/src"
		command: {
			name: "golangcilint"
			args: ["run","./..." , "--deadline", deadline, extraArgs]
		}
		mounts: {
			"source": {
				dest:     _sourcePath
				contents: source
			}
		}
	}
}
