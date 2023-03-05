include packages/npm/core/make/make.mk

# supported variables are : 
#   - `VERBOSE` (optional, default=``) enables verbose help parsing informations 
#   - `FORMAT` (optional, default=`text`) the output format of the help information
#      - `text` will print help in text format to terminal
#        - addional option `PAGER=false` may be used to output help without pagination
#     - `json` will print help in json format for further processing
#      - `markdown` will print help in markdown format for integrating output in static documentation
