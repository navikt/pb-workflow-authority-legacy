#!/bin/bash

## Get list of repositories owned by given team
if [[ ! -z $TEAM_NAME ]]; then
  TEAM_SLUG=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/orgs/navikt/teams/$TEAM_NAME" | jq -r '.slug')

  TEAM_REPOSITORIES=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/orgs/navikt/teams/$TEAM_SLUG/repos" | jq -r '.[] | .full_name')
fi



## Add 'navikt/..' to included repositories unless different owner is specified
if [[ ! -z $INCLUDE ]]; then
  REPOSITORIES=$(echo "$INCLUDE" | tr ' ' '\n' | sed 's/\(^[^\/]*$\)/navikt\/\1/g')
fi

## Concatenate lists and filter duplicates
REPOSITORIES=$(echo -e "$REPOSITORIES\n$TEAM_REPOSITORIES" | sort | uniq)



## Remove excluded repostories
IGNORED_REPOSITORIES=$(echo "$EXCLUDE" | tr ' ' '\n' | sed 's/\(^[^\/]*$\)/navikt\/\1/g')

for repository in $IGNORED_REPOSITORIES; do
  REPOSITORIES=$(echo $REPOSITORIES | tr ' ' '\n' | sed 's#'"$repository"'$##g')
done


## Distribute files for each project
for repository in $REPOSITORIES; do
  if [[ $repository == $GITHUB_REPOSITORY || "navikt/$repository" == $GITHUB_REPOSITORY ]]; then
    echo "Should not distribute files to same repository. Skipping $repository"
  else
    ./push_workflow_files.sh $repository
  fi
done