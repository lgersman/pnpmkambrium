#!/busybox/sh

set -e

# ensure stdin is provided using docker -i argument
if ls -Ll /proc/self/fd/0 | grep -q ' 1,  *3 '; then
  echo "container has no access to stdin. Run 'docker run -i ...' to run the container with stdin enabled" >&2
  exit 1
fi

if [[ -z "${FZF_INPUT}" ]]; then
  if [[ -f /FZF_INPUT ]]; then
    # FZF_INPUT=$(</FZF_INPUT) doesnt work since we are executed by busybox :-(
    FZF_INPUT=$(cat /FZF_INPUT)
  else
    echo "missing fzf input : Neither FZF_INPUT environment variable nor file '/FZF_INPUT' given" >&2 
    exit 1
  fi 
fi

fzf "$@" < <(echo "$FZF_INPUT")
