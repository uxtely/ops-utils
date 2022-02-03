#!/bin/sh

# https://blog.uxtely.com/finding-outdated-npm

usage() {
  cat << EOF >&2
Usage: $0 {i|o|ob|og}

i   Runs "npm install" on all projects
o   Checks outdated NPMs on all projects
ob  Same as "o" but opens the repos in a browser
og  Checks outdated NPMs globally
EOF
exit 1
}


REPO=~/work/myrepo
apps="
project-a
project-b
"

npmi() { # Runs `npm install` on all the projects
  local pids=""
  for app in $apps; do
    echo "Installing NPMs on $app..."
    cd $REPO/$app
    npm install &
    pids="$pids $!"
  done
  wait $pids
}


# Checks for outdated NPMs on all the projects and prints a pasteable line for updating
# the dependency, along with a comment of the currently installed version, for example:
#   cd $REPO/project-a && npm i foo@2.0.0   ;# foo@1.0.0
npmo() {
  local pids=""
  for app in $apps; do
    cd $REPO/$app
    npm outdated --parseable |\
      awk -v app="$app" -F: \
      '{ printf "cd $REPO/%-11s && npm i %-29s ;# %s\n", app, $4, $2 }' &
    pids="$pids $!"
  done
  wait $pids
}


npmog() { # Checks for outdated global NPMs
  npm outdated -g --parseable |\
    awk -F: \
    '{ printf "npm i -g %-18s ;# %s\n", $4, $3 }'
}


case $1 in
  i)  npmi ;;
  o)  npmo | sort -k6 ;;
  ob) npmo | sort -k6 | tee /dev/tty | awk '{print $6}' | uniq | xargs npm repo ;;
  og) npmog ;;
  *)  usage ;;
esac


