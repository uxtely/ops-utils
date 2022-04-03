#!/bin/sh

# This is just for manual analysis. It shows a list of dependencies that cross
# project boundaries, by searching for patterns in the form /ProjectName/

BOLD='\033[1m'
GREEN='\033[0;32m'
END_STYLE='\033[0m'

cd $UXREPO
source_files=$(find . | grep -Ev "node_modules|.idea|dist|.tmp|.git" | grep "\.js$")

search() {
  printf "\n\n\n$GREEN Searching for $1 $END_STYLE"

  for f in $source_files; do
    out=$(grep -E $1 "$f")
    if [ -n "$out" ]; then
      printf "\n\n$BOLD%s $END_STYLE\n%s" "$f" "$out"
    fi
  done
}

search "/AccountSPA|/ServerSide/|/AppSPA/|/UserDocs/|/Website/|/Blog/"
search "/Shared/"

cd -
