this package keeps the documentation of the monorepo

- initialize : `docker run --rm -it --mount type=bind,source=$(pwd)/packages/docs/gh-pages,target=/data -u $(id -u):$(id -g) pnpmkambrium/mdbook init`

- dev: `docker run --rm -it -p 3000:3000 -p 3001:3001 --mount type=bind,source=$(pwd)/packages/docs/gh-pages,target=/data -u $(id -u):$(id -g) pnpmkambrium/mdbook mdbook serve -n 0.0.0.0`

- build: `docker run --rm -it --mount type=bind,source=$(pwd)/packages/docs/gh-pages,target=/data -u $(id -u):$(id -g) pnpmkambrium/mdbook mdbook build`
