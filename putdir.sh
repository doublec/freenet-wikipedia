#! /bin/bash
# putdir.sh <dir> [short] [index] [uripriv]
dir=$(realpath $1)
short=${2:-}
index=${3:-index.html}
key=$4
nserturi=""
requesturi=""
finaluri=""

res=0

function wait_for {
  str=$1
  while read line
  do
    >&2 echo $line
    if [ "$line" == "$str" ]; then
      break
    fi
  done
}

function wait_for2 {
  str=$1
  while read line
  >&2 echo $line
  do
    if [ "$line" == "$str" ]; then
      break
    fi
  done
}

function wait_for_uri {
  while read line
  do
    if [ "$line" == "$str" ]; then
      break
    fi
    if [[ "$line" =~ ^URI=.* ]]; then
      finaluri=${line##URI=}
    fi
  done
}

function handle_sskkeypair {
  while read line
  do
    if [[ "$line" =~ ^InsertURI=.* ]]; then
      inserturi=${line##InsertURI=}
    fi
    if [[ "$line" =~ ^RequestURI=.* ]]; then
      requesturi=${line##RequestURI=}
    fi
    if [ "$line" == "EndMessage" ]; then
      break
    fi
  done
}

function wait_for_key {
  while read line
  do
    if [ "$line" == "SSKKeypair" ]; then
      handle_sskkeypair
      break
    fi
  done
}
function handle_progress {
  local total=0
  local required=0
  local succeeded=0
  local final=""
  local fetchable="$1"

  while read line
  do
   if [[ "$line" =~ ^Total=.* ]]; then
     total="${line##Total=}"
   fi
   if [[ "$line" =~ ^Required=.* ]]; then
     required="${line##Required=}"
   fi
   if [[ "$line" == "FinalizedTotal=true" ]]; then
     final="final"
   fi
   if [[ "$line" =~ ^Succeeded=.* ]]; then
     succeeded="${line##Succeeded=}"
   fi
   if [[ "$line" == "EndMessage" ]]; then
     >&2 echo "Progress: $fetchable $final $succeeded/$required/$total"
     break
   fi
  done
}

function wait_for_complete {
  local fetchable=""
  while read line
  do
    if [ "$line" == "PutFetchable" ]; then
      wait_for_uri "EndMessage"
      fetchable=$finaluri
    fi
    if [ "$line" == "SimpleProgress" ]; then
      handle_progress "$fetchable"
    fi
    if [ "$line" == "PutSuccessful" ]; then
      wait_for_uri "EndMessage"
      break
    fi
    if [ "$line" == "PutFailed" ]; then
      >&2 echo "$line"
      res=1
      wait_for2 "EndMessage"
      break
    fi
  done
}

id=$(uuidgen)
name=$(uuidgen)

exec 3<>/dev/tcp/127.0.0.1/9481
cat >&3 <<HERE
ClientHello
Name=$name
ExpectedVersion=2.0
EndMessage
HERE

wait_for "NodeHello" <&3
wait_for "EndMessage" <&3

cat >&3 <<HERE
GenerateSSK
Identifier=$id
EndMessage
HERE

wait_for_key <&3
uskinsert=U${inserturi:1}$short/0/
uskrequest=U${requesturi:1}$short/-0/
key=${key:-$uskinsert}

cat >&3 <<HERE
ClientPutDiskDir
Identifier=$id
Verbosity=1023
MaxRetries=-1
PriorityClass=3
URI=$key
Persistence=connection
Global=false
DefaultName=$index
Filename=$dir
EarlyEncode=true
ExtraInsertsSingleBlock=2
ExtraInsertsSplitfileHeaderBlock=2
EndMessage
HERE

wait_for_complete <&3

exec 3<&-
exec 3>&-

>&2 echo key: $key
>&2 echo inserturi: $inserturi$short
>&2 echo requesturi: $requesturi$short
>&2 echo uskinsert: $uskinsert
>&2 echo uskrequest: $uskrequest
>&2 echo uri: $finaluri
echo $finaluri $key

