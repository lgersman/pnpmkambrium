# contains the make help target

#
# <<EOD
# hihi
# 	huhu
# hihi
# EOD
#
.PHONY: bar
bar:

#
# <<EOF
# whats up ?
# here we <i>go
# EOF
#
.PHONY: foo
foo:
> (
>		IFS='\n'
>		cat $(MAKEFILE_LIST) | while read line; do
>			if [[ "$$line" =~ ^#[[:blank:]]\<\<([[:print:]]+)$$ ]]; then 
>				echo "'$$line'"
>				HEREDOC_KEY="$${BASH_REMATCH[1]}"
>				echo "$$HEREDOC_KEY"
>				while read line; do
>					if [[ "$$line" =~ ^#[[:blank:]]$$HEREDOC_KEY$$ ]]; then 
>						echo "end of heredoc : '$$line'"
>						break
>					elif [[ "$$line" =~ ^#[[:blank:]](([[:print:]]|[[:space:]])+)$$ ]]; then
>						COMMENT_LINE="$${BASH_REMATCH[1]}"
>						echo "comment line : '$$COMMENT_LINE'"
>					else 
>						echo "abort comment scanning - line '$$line' doesnt match comment nor HEREDOC end"
>						break
>					fi
>				done
>			fi
>		done
> )

#
# <<EOD
# xxx
# 	yyy
# xxx
# EOf
#
.PHONY: bar
bar:
