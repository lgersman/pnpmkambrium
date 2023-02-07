# contains the make help target

#
# <<EOD
# hihi
# 	huhu
# haha
# EOD
#
.PHONY: bar
bar:

#
# <<EMPTY_:-.HELP
# EMPTY_:-.HELP
#

#
# <<EOF
# whats up ?
# here we <i>go
# EOF
#
.PHONY: foo
foo:
>	declare -A HELP_TOPICS=()
> IFS='\n'
>	# pipe all read makefiles into read loop
>	while read line; do
>		# if help heredoc marker matches /#\s<<([\w\:\-\_]+)/ current line 
>		if [[ "$$line" =~ ^#[[:blank:]]\<\<([[:print:]]+)$$ ]]; then 
>			HEREDOC_KEY="$${BASH_REMATCH[1]}"
>			declare -a HEREDOC_BODY=()
>			# read lines starting with '# ' until a line containing just the heredoc token comes in 
>			while read line; do
>				if [[ "$$line" =~ ^#[[:blank:]]$$HEREDOC_KEY$$ ]]; then
>					# join lines separated by \n
>					HEREDOC_BODY=$$(printf "\n%s" "$${HEREDOC_BODY[@]}")
>					# strip leading \n
>					HEREDOC_BODY=$${HEREDOC_BODY:1}
>					if [[ "$$HEREDOC_BODY" == '' ]]; then
>						echo "[skipped] Help HereDoc(='$$HEREDOC_KEY') : help body is empty" >&2
>					else 
>						echo "'$$HEREDOC_KEY'='$$HEREDOC_BODY'" >&2
> 					while read line; do
# line="$(printf '.PHONY bar\t  foo/x.txt') %.cpp :"; [[ "$line" =~ ^((([A-Za-z0-9_/.\%]+)[[:blank:]]*)+): ]] && [[ "${line::1}" != '.' ]]  && echo "matched '${BASH_REMATCH[0]}'"
> 						if [[ "$$line" =~ ^((([A-Za-z0-9_/.\%]+)[[:blank:]]*)+): ]] && [[ "$${line::1}" != '.' ]]; then
> 							HELP_TOPICS["$${BASH_REMATCH[1]}"]="$$HEREDOC_BODY"
> 							break
> 						fi 
> 					done
>					fi
>					break
>				elif [[ "$$line" =~ ^#[[:blank:]](([[:print:]]|[[:space:]])+)$$ ]]; then
>					HEREDOC_BODY+=($${BASH_REMATCH[1]})
>				else
>					echo "[skipped] Help HereDoc(='$$HEREDOC_KEY') : line '$$line' does not match help line prefix(='# ') nor HereDoc end marker(='$$HEREDOC_KEY')" >&2
>					break
>				fi
>			done
>		fi
>	done < <(cat $(MAKEFILE_LIST))
> 
> if  [[ "$${HELP_MODE:-}" == '' ]]; then
>		echo "############## HELP_MODE is undefined"
>		
>		for TARGET in "$${!HELP_TOPICS[@]}"; do
> 		printf "$${TARGET}:\n$${HELP_TOPICS[$$TARGET]}\n\n" | cat
> 	done
>		
> else
> 	echo "HELP_MODE=$${HELP_MODE:-}"
> fi
> # convert HELP associative bash array into json

#
# <<HELP
# xxx
# 	yyy
# zzz
# HEL
#
.PHONY: xxxx
xxxx:

#
# <<DDD
# mi
# 	ka
# do
# DDD
#
.PHONY: yyyy
yyyy:
