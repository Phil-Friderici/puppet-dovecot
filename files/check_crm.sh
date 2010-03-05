#!/bin/sh

function usage {

cat << EOF

Usage:

  $0 <file> <node regex>

Example:

  $0 /etc/ha.d/my-cluster-status "server(1|2)\.example\.com"

Setup:

  # first check if your cluster status is OK:
  crm_mon

  # then dump its status to a file
  crm_mon -1 > /etc/ha.d/my-cluster-status

  # then find a regex which matches every node present in your cluster
  egrep --color "server(1|2)\.example\.com" /etc/ha.d/my-cluster-status

  # finally, configure nagios
  cat << NAGIOS >> /etc/nagios/commands.cfg
  define command {
    command_name  check_crm_status
    command_line  $0 /etc/ha.d/my-cluster-status "server(1|2)\.example\.com"
  }
  NAGIOS

EOF
}

# minimal attempt to obtain crm status in a failsafe manner. nagios user
# needs to be in haclient group on systems where crm sockets are only
# accessible to members of this group (redhat & debian for instance).
function getstatus {

  if [ -d /var/run/crm ]; then
    sockets="/var/run/crm"
  elif [ -d /var/run/heartbeat/crm ]; then
    sockets="/var/run/heartbeat/crm"
  else
    return 3
  fi

  if [ -r $sockets/cib_ro ] && [ -r $sockets/cib_callback ]; then
    crm_mon -1
  else
    sg haclient -c "crm_mon -1"
  fi
}


if [ $# -ne 2 ]; then
  echo "Error: 2 parameters expected"
  usage
  exit 1
fi

sourcefile="$1"
noderegex="$2"
error=0

sedcmd="sed -r \"/^=+$/,/^=+$/d; s/$noderegex/node/g\""

tmpdir=$(mktemp -d)
error=$(($error || $?))

getstatus | eval $sedcmd > $tmpdir/file1
error=$(($error || $?))

test -r $sourcefile
error=$(($error || $?))

cat $sourcefile | eval $sedcmd > $tmpdir/file2
error=$(($error || $?))

if [[ $error == 0 ]]; then
  cmp $tmpdir/{file1,file2} > /dev/null 2>&1
  differ=$?
else
  differ=2
fi

rm -f $tmpdir/{file1,file2} && rmdir $tmpdir

case $differ in

  0)
    echo "cluster status is OK"
    exit 0
  ;;

  1)
    echo 'cluster has problems, please check with "crm status"'
    exit 2
  ;;

  *)
    echo "nagios plugin failure: try running $0 $1 \"$2\""
    exit 3
  ;;

esac
