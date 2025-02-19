#!/bin/bash

set -e

source ./scripts/bash-color.sh
source ./scripts/spec-file.sh

# Parameters
print_spec="false"
no_update="false"

while [[ "$#" -gt 0 ]]; do
  case $1 in
  --print-spec)
    print_spec="true"
    shift
    ;;
  --no-update)
    no_update="true"
    shift
    ;;
  *)
    echo "Unknown parameter passed: $1"
    exit 1
    ;;
  esac
done

update_status="current"

echo_color "\n=== Checking for changes ===\n"

echo_color "Fetching dependency git commits"

github_uri="https://api.github.com/repos/$author"
github_api_request="-H 'Accept: application/vnd.github.VERSION.sha'"

if [ -n "$GITHUB_TOKEN" ]; then
  echo "Using Github token"
  github_api_request+=" -H 'Authorization: Bearer $GITHUB_TOKEN'"
  else
  echo "Github token not found"
fi

new_main_commit=$(curl -s "$github_api_request" "$github_uri/$main_repo/commits/HEAD")

if [ -z "$new_main_commit" ] || [ ${#new_main_commit} -ne 40 ]; then
  echo_error "Could not fetch new commits"

  echo_color -n "\n$main_repo: \020"
  echo_error "$new_main_commit"

  exit 1
fi

echo_color -n "\n$main_repo commit: \020"
echo "$current_main_commit -> $new_main_commit"

if [ "$current_main_commit" = "$new_main_commit" ]; then

  echo -e "\nNo changes detected"
else
  echo -e "\nChanges detected"

  echo_color "\n=== Updating RPM spec ===\n"

  if [ "$no_update" = "true" ]; then
    echo "RPM spec not updated because '--no-update' was passed"
  else
    sed -i -e "s/maincommit\s.*/maincommit $new_main_commit/" ./$spec_file

    echo "RPM spec updated"
    update_status="updated"
  fi

  if [ "$print_spec" = "true" ]; then
    echo_color "\nNew spec file:"
    cat $spec_file
  fi
fi
