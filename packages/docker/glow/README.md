# About

This image provides the most recent [glow](https://github.com/charmbracelet/glow) in a [distroless](https://github.com/GoogleContainerTools/distroless) docker image under 30MB

## Why ?

I needed a way to provide [gum](https://github.com/charmbracelet/glow) on demand and cross platform (Linux/maxOS/Windows).

=> That's exactly what a Docker image can do :-)

# Usage

You can use the image just like the native [gum](https://github.com/charmbracelet/glow) command :

```
docker run -ti --rm pnpmkambrium/glow [glow-options]
```

Example: `cat README.md | docker run -i --rm pnpmkambrium/glow -l -s auto -w 120 -`

see [glow](https://github.com/charmbracelet/glow) homepage for all options.
