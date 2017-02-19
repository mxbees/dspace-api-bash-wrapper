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
      #This allows the user to get XML as their response from the API. The default is JSON. If the '-x' flag is present, then the API will return XML. 
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

#communities

get_all_communities () {
  $GET --header="$DATA_TYPE" $YORKSPACE/communities -O yorkspace_all_communities.$data_ext
}

get_top_communities () {
  $GET --header="$DATA_TYPE" $YORKSPACE/communities/top-communities -O top_communities.$data_ext
}

get_community_info () {
  $GET --header="$DATA_TYPE" $YORKSPACE/communities/$id -O $id.$data_ext
}

get_community_communities () {
  $GET --header="$DATA_TYPE" $YORKSPACE/communities/$id/communities -O community$id-sub_communities.$data_ext
}

get_community_collections () {
  $GET --header="$DATA_TYPE" $YORKSPACE/communities/$community_id/collections -O community$id-collections.$data_ext
}

post_new_community () {
  community_name=$1
  $POST -O- --header=$CONTENT_HEADER --header=$TOKEN_HEADER \
        --post_data='{"name":"'"$community_name"'"}' \
        $YORKSPACE/communities
}

#collections

get_all_collections () {
  $GET --header="$DATA_TYPE" $YORKSPACE/collections -O yorkspace_all_collections.$data_ext
}

get_top_collections () {
  $GET --header="$DATA_TYPE" $YORKSPACE/collections/top-collections -O top_collections.$data_ext
}

get_collection_items () {
  $GET --header="$DATA_TYPE" $YORKSPACE/collections/$id/items
}

#misc functions

json_or_xml () {
  api_call=$1
  id=$2
  if [ "$DATA_TYPE" == 'Accept: application/json' ]; then
    data_ext='json'
    $api_call
  elif [ "$DATA_TYPE" == 'Accept: application/xml' ]; then
    data_ext='xml'
    $api_call
  fi
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
  communities)
    subcommand=$1
    case "$subcommand" in
      all)
        json_or_xml get_all_communities
      shift
      ;;
      top)
        json_or_xml get_top_communities
      shift
      ;;
      info)
        json_or_xml get_community_info $2
      shift
      ;;
      communities)
        json_or_xml get_community_communities $2
      shift
      ;;
      collections)
        json_or_xml get_community_communities $2
      shift
      ;;
      new)
        post_new_community $2
      shift
      ;;
    esac
  shift
  ;;
  collections)
    subcommand=$1
    case "$subcommand" in
      all)
        json_or_xml get_all_collections
      shift
      ;;
    esac
  shift
  ;;
esac
