# contains generic make rules 

# generic guard rule to ensure a environment variable is set before using it 
#
# example usage : 
# change-hostname: guard-HOSTNAME
# > ./changeHostname.sh ${HOSTNAME}
#
# see https://stackoverflow.com/a/7367903/1554103
guard-%:
> @ if [ "${${*}}" = "" ]; then \
>     echo "Environment variable $* not set"; \
>     exit 1; \
> fi
