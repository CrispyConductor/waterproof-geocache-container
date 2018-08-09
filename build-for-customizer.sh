#!/bin/bash

function buildForCustomizer {
	cat "$1" | while read -r line; do
		echo "$line" | grep -E '^[ \t]*(use|include)[ \t]*<' >/dev/null
		if [ $? -eq 0 ]; then
			SUBFILE="`echo "$line" | cut -d '<' -f 2 | cut -d '>' -f 1`"
			if [ "$SUBFILE" = 'write/Write.scad' ]; then
				echo "$line"
			else
				buildForCustomizer "$SUBFILE"
			fi
		else
			echo "$line"
		fi
	done
}

buildForCustomizer "$1"


