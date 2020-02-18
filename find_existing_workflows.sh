#!/bin/bash

## Find version sha for existing files, if present
GITHUB_FOLDER_SHA=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY/git/trees/$BASE_TREE_SHA" | jq -r '.tree[] | select(.path == ".github").sha')

if [[ -z $GITHUB_FOLDER_SHA ]]; then
  echo "[]"
  exit 0
fi

WORKFLOW_FOLDER_SHA=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY/git/trees/$GITHUB_FOLDER_SHA" | jq -r '.tree[] | select(.path == "workflows").sha')

if [[ -z $WORKFLOW_FOLDER_SHA ]]; then
  echo "[]"
  exit 0
fi

curl -s "https://api.github.com/repos/$REPOSITORY/git/trees/$WORKFLOW_FOLDER_SHA" | jq '.tree'