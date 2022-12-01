# About

This image provides the most recent [fzf](https://github.com/junegunn/fzf) in a [distroless](https://github.com/GoogleContainerTools/distroless) image (~24MB)

## Why ?

I needed a way to provide [fzf](https://github.com/junegunn/fzf) on demand and cross platform (Linux/maxOS/Windows).

=> That's exactly what a Docker image can do :-)

# Usage

Since [fzf](https://github.com/junegunn/fzf) needs a TTY AND interactive STDIN we cannot provide input via STDIN when running in Docker.

## `fzf` Input

You can provide [fzf](https://github.com/junegunn/fzf) input using

- environment variable `FZF_INPUT`.

  Example : `docker run -it -e FZF_INPUT="$(ls /)" --rm pnpmkambrium/fzf'`

- or by providing a file `/FZF_INPUT`

  Example : `docker run -it -v $(ls / > FZF_INPUT && echo $(pwd)/FZF_INPUT):/FZF_INPUT --rm pnpmkambrium/fzf`

## `fzf` options

All options provided to the container will be delegated to [fzf](https://github.com/junegunn/fzf).

Example: `docker run -it -e FZF_INPUT="$(ls $(pwd)/foo)" -v $(pwd)/foo:/foo --rm pnpmkambrium/fzf --preview='ls -la /foo/{}'`
