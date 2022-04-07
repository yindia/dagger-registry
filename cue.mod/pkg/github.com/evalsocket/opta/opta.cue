// Run a Opta program
package opta

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
	"universe.dagger.io/aws"
)

#DefaultLinuxVersion: "amazonlinux:2.0.20220121.0@sha256:f3a37f84f2644095e2c6f6fdf2bf4dbf68d5436c51afcfbfa747a5de391d5d62"
#DefaultCliVersion:   "2.4.12"

// Build provides a docker.#Image with the aws cli pre-installed to Amazon Linux 2.
// Can be customized with packages, and can be used with docker.#Run for executing custom scripts.
// Used by default with aws.#Run
#Build: {
	docker.#Build & {
		steps: [
			docker.#Pull & {
				source: #DefaultLinuxVersion
			},
			docker.#Run & {
				command: {
					name: "yum"
					args: ["install", "unzip", "curl", "git","bash", "tar" ,"yum-utils", "-y"]
				}
			},
			docker.#Run & {
				command: {
					name: "yum-config-manager"
					args: ["--add-repo", "https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo"]
				}
			},
			docker.#Run & {
				command: {
					name: "sh"
					args: ["-c","curl -fsSL https://docs.opta-files.dev/install.sh | bash"]
				}
			},
			docker.#Run & {
				command: {
					name: "yum"
					args: ["install", "terraform", "-y"]
				}
			},
			docker.#Run & {
				command: {
					name: "/scripts/install.sh"
					args: [version]
				}
				mounts: scripts: {
					dest:     "/scripts"
					contents: _scripts.output
				}
			},
		]
	}

	_scripts: core.#Source & {
		path: "_scripts"
		include: ["*.sh"]
	}

	// The version of the AWS CLI to install
	version: string | *#DefaultCliVersion
}

// Run a `opta-files Apply`
#Action: {
	_build: #Build

	// Source code of Opta program
	source: dagger.#FS

	// Opta action used for this Opta program
	action: "apply" | "destroy" | "force-unlock"

	// Opta env used for this Opta program
	environment: string

	// Opta extra cli flags used for this Opta program
	extraArgs: string

	// Opta Config name used for this Opta program
	configFile: string | *"opta-files.yaml"

	// credentials provides long or short-term credentials
	credentials: aws.#Credentials

	// Run Opta apply
	container: docker.#Run & {
		input:  _build.output
		command: {
			name: "/scripts/opta-files.sh"
			args: []
		}
		env: {
			ACTION:  action
			ENV:  environment
			CONFIG_FILE:  configFile
			EXTRA_ARGS: extraArgs
		}
		workdir: "/src"
		mounts: scripts: {
			dest:     "/scripts"
			contents: _scripts.output
		}
		mounts: opta: {
			dest:     "/src"
			contents: source
		}
	}

	_scripts: core.#Source & {
		path: "_scripts"
		include: ["*.sh"]
	}
}
