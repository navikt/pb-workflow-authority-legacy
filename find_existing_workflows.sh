#!/bin/bash

## Find version sha for existing files, if present
WORKFLOW_FOLDER_SHA=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY/git/trees/$BASE_TREE_SHA?recursive=1" | jq -r '.tree[] | select(.path == ".github/workflows").sha')

if [[ -z $WORKFLOW_FOLDER_SHA ]]; then
  echo "[]"
  exit 0
fi

curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY/git/trees/$WORKFLOW_FOLDER_SHA" | jq '.tree'