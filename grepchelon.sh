#!/bin/bash
# Copyright (c) 2011 Anders Sundman <anders@haven-project.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# ===================================================================
# The grepchelon Script will search all files that matches the
# file-pattern (default pdf) for the key words (acctually regexps)
# listed in the keyword-file or on the command line.
# ===================================================================

USAGE="Usage: `basename $0` [-h] [-v] [-f keyword-file] [-k keyword] [-p file-pattern] [-d dir]"

KEYWORDS=""
SEARCH_FILE_PATTERN="*.pdf"
SEARCH_DIR="."

# parse command line arguments
LAST_OPTARG_OPT=0
while getopts "hvf:k:p:d:" OPT; do
    case "$OPT" in
        "h" ) echo $USAGE
              exit 0
              ;;
        "v" ) VERBOSE=1
              ;;
        "k" ) KEYWORDS="${KEYWORDS}|(${OPTARG})"
              ;;
        "p" ) SEARCH_FILE_PATTERN=$OPTARG
              ;;
        "d" ) SEARCH_DIR=`cd \`dirname $OPTARG\`; pwd`/`basename $OPTARG`
              ;;
        "f" ) FILE=`cd \`dirname $OPTARG\`; pwd`/`basename $OPTARG`
              if ! [ -f "$FILE" ] ; then
                echo "Error, no such file: $FILE"
                exit 1
              fi
              IFS_STASH=$IFS
              IFS=$(echo -en "\n\b")
              for KV in `cat $FILE` ; do
                KEYWORDS="${KEYWORDS}|(${KV})"
              done
              IFS=$IFS_STASH
              ;;
        *   ) echo $USAGE >&2
              exit 1
              ;;
    esac
    LAST_OPTARG_OPT=$OPTIND
done

# Trim leading |
KEYWORDS=$(echo "$KEYWORDS" | cut -c2-)

# Find suitable grep program (fall back on strings)
GREP_PROGRAM="strings"
GREP_PROGRAM_ARGS=""
if $(echo $SEARCH_FILE_PATTERN | grep -i -q "pdf") ; then
  GREP_PROGRAM="pdftotext"
  GREP_PROGRAM_ARGS="-"
fi

[ $VERBOSE ] && echo "KEYWORDS=$KEYWORDS"
[ $VERBOSE ] && echo "SEARCH_FILE_PATTERN=$SEARCH_FILE_PATTERN"
[ $VERBOSE ] && echo "SEARCH_DIR=$SEARCH_DIR"

if ! [ "$KEYWORDS" ] ; then
    echo "Must specify at least one search pattern"
    echo $USAGE >&2
    exit 1
fi

# Process files
for FILE in $(find "$SEARCH_DIR" -iname "$SEARCH_FILE_PATTERN") ; do
  [ $VERBOSE ] && echo "Processing: $FILE"
  if $($GREP_PROGRAM "$FILE" $GREP_PROGRAM_ARGS 2>&1 | egrep -i -q "$KEYWORDS") ; then
    echo "$FILE"
    echo "======================================================================"
    echo $($GREP_PROGRAM "$FILE" $GREP_PROGRAM_ARGS 2>&1 | egrep -i "$KEYWORDS")
    echo "======================================================================"
    echo
  fi
done
