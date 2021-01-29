#!/bin/bash

export REPOSITORY=$1
IFS=
SOURCE_FOLDER=$2
FILES_TO_DELETE=$3

## Create new file
function createNode {
  WORKFLOW_FILE_NAME=$(basename -- $1 | sed 's/__DISTRIBUTED_//g')
  echo $(jq -n -c \
              --arg path ".github/workflows/$WORKFLOW_FILE_NAME" \
              --rawfile content $1 \
              '{ path: $path, mode: "100644", type: "blob", content: $content }'
  )
}

function deleteNode {
  WORKFLOW_FILE_NAME=$(basename -- $1 | sed 's/__DISTRIBUTED_//g')
  echo $(jq -n -c \
              --arg path ".github/workflows/$WORKFLOW_FILE_NAME" \
              '{ path: $path, mode: "100644", type: "blob", sha: null }'
  )
}

## Get name of main branch
MAIN_BRANCH=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY" | jq -r '.default_branch')

## Get latest commit sha on main
export BASE_TREE_SHA=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY/git/refs/heads/$MAIN_BRANCH" | jq -r '.object.sha')


## Find existing workflows in target repository
EXISTING_WORKFLOWS=$(./find_existing_workflows.sh)


## Iterate through workflow folder and only include those that differ from target workflows
let TOTAL_FILES_CHANGED=0
for file in "$SOURCE_FOLDER"/__DISTRIBUTED_*; do

  TARGET_FILE_NAME=$(basename -- $file | sed 's/__DISTRIBUTED_//g')

  EXISTING_FILE_SHA=$(echo $EXISTING_WORKFLOWS | jq -r '.[] | select(.path == "'"$TARGET_FILE_NAME"'").sha')
  NEW_FILE_SHA=$(git hash-object $file)

  if [[ ! -z $FILES_TO_DELETE ]] && grep -Fxq "$TARGET_FILE_NAME" "$FILES_TO_DELETE"; then
    echo "$TARGET_FILE_NAME was included in both files to delete and as a managed workflow. Deletion takes precedence."
    continue
  elif [[ $EXISTING_FILE_SHA != $NEW_FILE_SHA ]]; then
    let TOTAL_FILES_CHANGED=$TOTAL_FILES_CHANGED+1
    FILES_TO_UPDATE="$FILES_TO_UPDATE$TARGET_FILE_NAME, "
    TREE_NODES="$TREE_NODES$(createNode $file),"
  fi
done

## Iterate through remote workflows and mark requested files for deletion
REMOTE_WORKFLOWS=$(echo $EXISTING_WORKFLOWS | jq -r '.[].path')
while IFS= read FILE_NAME; do
  if [[ ! -z $FILES_TO_DELETE ]] && grep -Fxq "$FILE_NAME" "$FILES_TO_DELETE"; then
      let TOTAL_FILES_CHANGED=$TOTAL_FILES_CHANGED+1
      FILES_TO_UPDATE="$FILES_TO_UPDATE$TARGET_FILE_NAME, "
      TREE_NODES="$TREE_NODES$(deleteNode $FILE_NAME),"
  fi
done <<< "$REMOTE_WORKFLOWS"

## Print status and exit if dry run
if [[ $DRY_RUN == "true" ]]; then
  if [[ -z $FILES_TO_UPDATE ]]; then
    echo "Dry run for $REPOSITORY: No workflow files would have been added, changed or removed."
    exit 0
  else
    FILES_LIST="[$(echo $FILES_TO_UPDATE | sed 's/, $//')]"
    echo "Dry run for $REPOSITORY: These files would have been added or changed $FILES_LIST"
    exit 0
  fi
fi


## Exit if no changes are to be made
if [[ -z $TREE_NODES ]]; then
  echo "Project $REPOSITORY is already up-to-date"
  exit 0
fi

## Remove trailing comma and wrap in square brackets
TREE_NODES="[$(echo $TREE_NODES | sed 's/,$//')]"


## Create new tree on remote and keep its ref
CREATE_TREE_PAYLOAD=$(jq -n -c \
                      --arg base_tree $BASE_TREE_SHA \
                      '{ base_tree: $base_tree, tree: [] }'
)

CREATE_TREE_PAYLOAD=$(echo $CREATE_TREE_PAYLOAD | jq -c '.tree = '"$TREE_NODES")

UPDATED_TREE_SHA=$(curl -s -X POST -u "$API_ACCESS_TOKEN:" --data "$CREATE_TREE_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/git/trees" | jq -r '.sha')


SHORT_SHA=$(echo $GITHUB_SHA | cut -c1-7)

## Create commit based on new tree, keep new tree ref
CREATE_COMMIT_PAYLOAD=$(jq -n -c \
                        --arg message "$TOTAL_FILES_CHANGED file(s) updated by $GITHUB_REPOSITORY, version $SHORT_SHA" \
                        --arg tree $UPDATED_TREE_SHA \
                        --arg name "Personbruker Workflow Authority" \
                        --arg email "personbruker@nav.no" \
                        --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
                        '{ tree: $tree, message: $message, author: { name: $name, email: $email, date: $date }, parents: [] }'
)

CREATE_COMMIT_PAYLOAD=$(echo $CREATE_COMMIT_PAYLOAD | jq -c '.parents = ["'"$BASE_TREE_SHA"'"]')

UPDATED_COMMIT_SHA=$(curl -s -X POST -u "$API_ACCESS_TOKEN:" --data "$CREATE_COMMIT_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/git/commits" | jq -r '.sha')




## Push new commit
PUSH_COMMIT_PAYLOAD=$(jq -n -c \
                      --arg sha $UPDATED_COMMIT_SHA \
                      '{ sha: $sha, force: false }'
)



HEAD_SHA=$(curl -s -X PATCH -u "$API_ACCESS_TOKEN:" --data "$PUSH_COMMIT_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/git/refs/heads/master" | jq -r '.object.sha')


echo "$REPOSITORY is now on commit $HEAD_SHA"
