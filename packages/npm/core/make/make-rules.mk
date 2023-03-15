# contains generic make rules 

# generic guard rule to ensure a environment variable is set before using it 
#
# example usage : 
# change-hostname: guard-env-HOSTNAME
# > ./changeHostname.sh ${HOSTNAME}
#
# see https://stackoverflow.com/a/7367903/1554103
guard-env-%:
> if [[ "${${*}}" == "" ]]; then
>   echo "Environment variable $* not set" >&2
>   exit 1
> fi
