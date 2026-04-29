#!/usr/bin/env bash

gemini_version=0.40.0
mkdir -p $HOME/.gemini-sandbox
mkdir -p $HOME/.gemini

command=( docker run -it --rm \
                      --entrypoint '' \
                      --user $(id -u):$(id -g) \
                      -e HOME=/home/node \
                      -e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/node/.gemini-sandbox/bin \
                      -v "$PWD":/home/node/`basename "$PWD"` \
                      --workdir /home/node/`basename "$PWD"` \
                      -e NPM_CONFIG_PREFIX=/home/node/.gemini-sandbox \
                      -v $HOME/.gemini-sandbox:/home/node/.gemini-sandbox \
                      -v $HOME/.gemini:/home/node/.gemini \
                      -e GOOGLE_CLOUD_PROJECT \
                      -e TERM=$TERM -e COLORTERM=$COLORTERM \
)

run_in_docker() {
  "${command[@]}" --net host ghcr.io/t7tran/nodedev:lts "$@"
}

ensure_extension() {
  local ext=$1 path=$2
  if [ ! -d $HOME/.gemini/extensions/$ext ]; then run_in_docker gemini extensions install $path --consent --auto-update; fi
}

args=(); for arg in "$@"; do [[ "$arg" != "--no-update" ]] && args+=("$arg"); done

if [[ "$@" != *--no-update* ]]; then
  version=`run_in_docker gemini --version 2>/dev/null`
  if [[ "$(printf '%s\n' "$gemini_version" "${version:-0.0.1}" | sort -rV | tail -n1)" != "$gemini_version" ]]; then
    run_in_docker npm install --loglevel=error -g @google/gemini-cli@latest
  fi
  ensure_extension atlassian-rovo-mcp-server https://github.com/atlassian/atlassian-mcp-server
  ensure_extension conductor                 https://github.com/gemini-cli-extensions/conductor
  ensure_extension Stitch                    https://github.com/gemini-cli-extensions/stitch
  run_in_docker gemini extensions update --all
  docker pull ghcr.io/t7tran/nodedev:lts
fi

if [[ -f $HOME/.gitconfig ]]; then
	command+=( -v $HOME/.gitconfig:/home/node/.gitconfig:ro )
fi
if [[ -f $HOME/.config/gcloud ]]; then
	command+=( -v $HOME/.config/gcloud:/home/node/.config/gcloud:ro )
fi
if [[ -d $HOME/git ]]; then
	command+=( -v $HOME/git:/home/node/git:ro )
fi
if [[ -d $HOME/.sf ]]; then
	command+=( -v $HOME/.sf:/home/node/.sf )
fi
if [[ -d $HOME/.sfdx ]]; then
	command+=( -v $HOME/.sfdx:/home/node/.sfdx )
fi

command+=( ghcr.io/t7tran/nodedev:lts gemini )

if [[ -d $HOME/git ]]; then
	command+=( --include-directories /home/node/git )
fi

exec "${command[@]}" "${args[@]}"
