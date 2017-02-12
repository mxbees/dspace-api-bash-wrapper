#!/bin/bash

. .token.txt

YORKSPACE='https://yorkspace.library.yorku.ca/rest'
JSON_HEADER='Accept: application/json'
XML_HEADER='Accept: application/json'
CONTENT_HEADER='Content-Type: application/json'
TOKEN_HEADER="rest-dspace-token: $dspace_token"
GET='curl -X GET -s'
POST='curl -X POST -s'
PUT='curl -X PUT -s'
DELETE='curl -X DELETE -s'

#basic auth related stuff and testing

test_api () {
  $CMD $YORKSPACE/test
}

get_documentation () {
  $CMD $YORKSPACE -o rest_api_documentation.html
}

yorkspace_login () {
  email=$1
  password=$2
  auth_data=$(jq -n -c --arg e $email --arg p $password '{"email":$e, "password":$p}')
  token=$($CMD -H "$CONTENT_HEADER" -d $auth_data "$YORKSPACE/login")
  echo "dspace_token=$token" > .token.txt
}

yorkspace_logout () {
  $CMD -X POST -H "$CONTENT_HEADER" -H "$TOKEN_HEADER" $YORKSPACE/logout
  echo "You're now logged out of the API"
}

token_status () {
  status=$($CMD -H "$JSON_HEADER" -H "$CONTENT_HEADER" -H "$TOKEN_HEADER" $YORKSPACE/status)
  echo $status
}

#collections

get_all_collections () {
  #ll_collections=$(sdfs)
  $CMD -H $JSON_HEADER $YORKSPACE/collections > yorkspace_collections.json
}

command=$1
shift

case "$command" in
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
    get_all_collections
  shift
  ;;
esac

#yorkspace_login 'nmpink@yorku.ca' "dspaceisforlosers"
#yorkspace_logout
#token_status
