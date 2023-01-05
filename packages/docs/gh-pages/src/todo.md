# TODO

## Documentation

## Development

- make functions like `kambrium_dump_vars`

### Configuration

#### Environment

- KAMBRIUM\_\* config variables

- `*-push-*` environment variables and their .env file relation

### make cheatcheat

- adding `.SHELLFLAGS += -x` in your Makefile will enable shell execution output :

  ```
  include packages/npm/core/make/make.mk

  ...

  .SHELLFLAGS += -x
  ```

- adding `.MAKEFLAGS += --silent` in your Makefile will hide anything except shell output :

  ```
  include packages/npm/core/make/make.mk

  ...

  MAKEFLAGS += --silent
  ```

  _Alternatively you can start make with option `--silent`._
