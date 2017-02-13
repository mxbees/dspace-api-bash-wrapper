#!/bin/bash

. .token.txt

YORKSPACE='https://yorkspace.library.yorku.ca/rest'
DATA_TYPE='Accept: application/json'
CONTENT_HEADER='Content-Type: application/json'
TOKEN_HEADER="rest-dspace-token: $dspace_token"
GET='wget --method=GET -q'
POST='wget --method=POST -q'
PUT='wget --method=PUT -q'
DELETE='wget --method=DELETE -q'
WGET='wget -q'

#global options

while getopts ":x" opts; do
  case $opts in
    x)
      DATA_TYPE='Accept: application/xml'
    ;;
  esac
done
shift $((OPTIND -1))

#basic auth related stuff and testing

test_api () {
  $GET -O- $YORKSPACE/test
}

get_documentation () {
  $GET $YORKSPACE -O dspace_api-documentation.html
}

yorkspace_login () {
  email=$1
  password=$2
  token=$($WGET -O- --header="$CONTENT_HEADER" \
  --post-data='{"email":"'"$email"'","password":"'"$password"'"}' \
  "$YORKSPACE/login")
  echo "dspace_token=$token" > .token.txt
}

yorkspace_logout () {
  $POST -O- --header="$CONTENT_HEADER" --header="$TOKEN_HEADER" $YORKSPACE/logout
  echo "You're now logged out of the API"
}

token_status () {
  status=$($GET -O- --header="$DATA_TYPE" --header="$CONTENT_HEADER" --header="$TOKEN_HEADER" $YORKSPACE/status)
  echo $status
}

#collections

get_all_collections () {
  #ll_collections=$(sdfs)
  $GET --header="$DATA_TYPE" $YORKSPACE/collections -O yorkspace_collections.json
}

command=$1
shift

case "$command" in
  documentation)
    get_documentation
    shift
  ;;
  test)
    test_api
    echo ""
    shift
  ;;
  login)
    while getopts ':p:u:' opt; do
      case $opt in
        u)
          email="$OPTARG"
        ;;
        p)
          password="$OPTARG"
        ;;
        /?)
          echo "invalid option"
        ;;
      esac
    done
    shift $((OPTIND -1))
    yorkspace_login $email $password
    shift
  ;;
  logout)
    yorkspace_logout
    shift
  ;;
  status)
    token_status
    shift
  ;;
  collections)
    subcommand=$1
    case "$subcommand" in
      all)
        get_all_collections
      shift
      ;;
    esac
  shift
  ;;
esac
