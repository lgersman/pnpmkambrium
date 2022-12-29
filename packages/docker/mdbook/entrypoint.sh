#!/usr/bin/env bash

# ensure mount point /app bound to host repo directory using docker --mount argument
if [[ ! -d /data ]]; then
  echo "mount point '/data' is not bound to a host directory. Run 'docker ... --mount type=bind,source=<host-repo-directory>,target=/data ...'"
  exit 1
fi 

if [[ $# -eq 0 ]]; then
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [command]

A mdbook runner providing some mdbook extensions 

Available commands:

init                          initialize an empty mdbook project with the required files
mdbook [mdbook-command]       starts mdbook 

see https://rust-lang.github.io/mdBook/cli/index.html for available [mdbook-command]'s 
EOF
  exit 0
fi

cd /data

if [[ $# -eq 1 ]]; then
  if [[ "$1" = "init" ]]; then
    # ensure book.toml exists
    if [[ ! -f /data/book.toml ]]; then
      echo "'/data/book.toml' does not exist - will generate it"
      echo 'n' | mdbook init --title=""

      # for some reason we cannot tell "mdbook init" about our custom build directory
      # all mdbook options document here did not work : https://rust-lang.github.io/mdBook/format/configuration/environment-variables.html 
      mv ./book ./build

      echo "initializing mdbook plugin mdbook-toc"
      printf '\n[preprocessor.toc]\ncommand = "mdbook-toc"\n' >> /data/book.toml
    
      echo "initializing mdbook plugin mdbook-mermaid"
      mdbook-mermaid install |:
      printf '#see more options here : https://rust-lang.github.io/mdBook/format/configuration/renderers.html#html-renderer-options\n' >> /data/book.toml

      echo "(disabled) initializing mdbook plugin mdbook-presentation-preprocessor"
      printf '\n#[preprocessor.presentation-preprocessor]\n' >> /data/book.toml

      echo "configure build output directory"
      printf '\n[build]\nbuild-dir = "./build"\n' >> /data/book.toml      

      exit 0
    else 
      echo "'/data/book.toml' already exists. Remove it and execute 'init' again"
      exit 1
    fi
  fi
fi

# add a entrypoint script to enable CTRL-C abortion in terminal
# (see https://stackoverflow.com/a/57526365/1554103)
$@