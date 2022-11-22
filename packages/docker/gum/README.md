# About

This image provides the most recent [gum](https://github.com/charmbracelet/gum) in a [distroless](https://github.com/GoogleContainerTools/distroless) docker image under 30MB

## Why ?

I needed a way to provide [gum](https://github.com/charmbracelet/gum) on demand and cross platform (Linux/maxOS/Windows).

=> That's exactly what a Docker image can do :-)

# Usage

You can use the image just like the native [gum](https://github.com/charmbracelet/gum) command :

```
docker run -ti --rm pnpm-kambrium/gum [gum-command] [gum-command-options]
```

Example: `docker run -ti --rm pnpm-kambrium/gum choose "fix" "feat" "docs" "style" "refactor" "test" "chore" "revert"`

see [gum](https://github.com/charmbracelet/gum) homepage for all options.
