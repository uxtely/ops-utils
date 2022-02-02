abort() { # Prints the message in red to stderr
  printf "\033[31m  ABORTED: $1\n\033[0m" >&2
  exit 1
}


user_input() {
  local msg=$1
  local default=$2
  local _temp

  read -p "$msg [$default]: " _temp

  if [ "$_temp" = "" ]; then
    echo "$default"
  else
    echo "$_temp"
  fi
}


make_ssh() {
  local host=$1
  local addr=$2
  local port=$3
  local user=$4
  local pass="$5"
  local key=~/.ssh/$host/id_ed25519

  echo "Creating SSH Keys..."
  test ! -e $(dirname $key) || abort "`dirname $key` exists"

  mkdir -p $(dirname $key)
  ssh-keygen -t ed25519 -a 32 -f $key -N "$pass"
  chmod -R 700 $(dirname $key)
  test -e $key || abort "Failed to create $key"

  cat >> ~/.ssh/config << EOF

Host $host
HostName $addr
Port $port
User $user
IdentityFile $key
EOF
}


make_password() {
  cat /dev/urandom | LC_CTYPE=C tr -cd [:graph:] | head -c $1
}



