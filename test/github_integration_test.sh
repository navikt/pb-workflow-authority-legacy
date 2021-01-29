#!/bin/bash

## Use current time to create new and unique workflow file.
DATETIME=$(date +%Y%m%d%H%M%S)

sed -i "s/Datetime - [0-9]\{14\}/Datetime - $DATETIME/" './test/workflows/__DISTRIBUTED_dummy-legacy.yml'


## Use script to apply workflow to remote repository
./push_workflow_files.sh 'navikt/pb-workflow-authority-test-dummy' './test/workflows'


## Find latest commit on main branch
CURRENT_MAIN_SHA=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/navikt/pb-workflow-authority-test-dummy/git/refs/heads/main" | jq -r '.object.sha')

## Find sha of remote workflow file after changes were attempted.
DUMMY_WORKFLOW_SHA=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/navikt/pb-workflow-authority-test-dummy/git/trees/$CURRENT_MAIN_SHA?recursive=1" | jq -r '.tree[] | select(.path == ".github/workflows/dummy-legacy.yml").sha')

## Exit with error if file was not found
if [[ -z $DUMMY_WORKFLOW_SHA ]]; then
  echo "dummy-legacy.yml workflow file was not found in destionation repository."
  exit 1
fi

## Find contents of remote file
curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/navikt/pb-workflow-authority-test-dummy/git/blobs/$DUMMY_WORKFLOW_SHA" | jq -r '.content' | base64 -d >> ./test/workflows/dummy-legacy.yml

## Verify that contents of remote file matches local file
if ! diff -q './test/workflows/dummy-legacy.yml' './test/workflows/__DISTRIBUTED_dummy-legacy.yml' &>/dev/null; then
  echo 'Failed in applying changes to remote repository.'
  exit 1
fi


## Run script again, this time with delete config defined
./push_workflow_files.sh 'navikt/pb-workflow-authority-test-dummy' './test/workflows' './test/delete.conf'

## Fetch remaining files in remote workflow repository
CURRENT_MAIN_SHA=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/navikt/pb-workflow-authority-test-dummy/git/refs/heads/main" | jq -r '.object.sha')

DUMMY_REPOSITORY_CONTENTS=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/navikt/pb-workflow-authority-test-dummy/git/trees/$CURRENT_MAIN_SHA?recursive=1" | jq -r '.tree[]')

## Verify that no files marked for deletion remains in remote repository
while read file_to_delete; do

  REMOTE_FILE_SHA=$(echo "$DUMMY_REPOSITORY_CONTENTS" | jq -r 'select(.path == ".github/workflows/'"$file_to_delete"'").sha')

  if [[ ! -z $REMOTE_FILE_SHA ]]; then
    echo 'Remote file was not deleted as requested.'
    exit 1
  fi
done < ./test/delete.conf
