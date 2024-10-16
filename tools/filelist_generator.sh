## This script makes a copy of the Physics run artroot files for a set of jobs and moves them 
## into a single directory defined by the user.
## The script then creates the files.list file required by subsequent stages of the 
## processing workflow.

#!/bin/bash
## Configurable parameters defined in the xml
TAG="darknews_overlay"
NAME="darknews_overlay_test"
RELEASE="v08_00_00_84"
STAGE_NAME="reco1"
USER="jbateman"
OUT_DIR="/pnfs/uboone/scratch/users/"$USER"/"$TAG"/"$RELEASE"/"$STAGE_NAME"/"$NAME"/"
WORK_DIR="/exp/uboone/data/users/"$USER"/book/"$TAG"/"$RELEASE"/"$STAGE_NAME"/"$NAME"/"

## Defining where you want to store your files
FINAL_DIR="/pnfs/uboone/persistent/users/"$USER"/production/"$TAG"/"$RELEASE"/"$STAGE_NAME"/"$NAME"/"

JOB_ID="jobids.list"
FileList=$WORK_DIR$JOB_ID
echo $FileList
## Writing each file to a list
PATH_LIST=$WORK_DIR"files.list"
# Overwrite the PATH_LIST file if it exists
> "$PATH_LIST"

# Check if the file exists
if [[ -f "$FileList" ]]; then
  # Read the file line by line
  while IFS= read -r line
  do
    # Set the Internal Field Separator to '@'
    IFS='@'
    read -ra ADDR <<< "$line"
    IFS='.'
    read -ra ADDR_1 <<< "${ADDR[0]}"
    JOB_STR="${ADDR_1[0]}_${ADDR_1[1]}"
    echo $JOB_STR

    DIR_PATH="$OUT_DIR$JOB_STR"
    echo $DIR_PATH

    # Check if the directory exists
    if [[ -d "$DIR_PATH" ]]; then
      # Check if $FINAL_DIR exists, and if not, create it
      if [[ ! -d "$FINAL_DIR" ]]; then
        mkdir -p "$FINAL_DIR"
        echo "Created directory: $FINAL_DIR"
      fi

      # Iterate over files matching the pattern
      for file in $DIR_PATH/Physics*; do
        # Get the base name of the file
        base_file=$(basename "$file")
        
        # Check if the file exists in $FINAL_DIR
        if [[ ! -f "$FINAL_DIR/$base_file" ]]; then
          # Copy the file if it doesn't exist in $FINAL_DIR
          cp "$file" "$FINAL_DIR"
          echo "Copied $file to $FINAL_DIR"
        else
          echo "$FINAL_DIR/$base_file already exists, skipping copy."
        fi
        # Record the path of the file (copied or not)
        echo "$FINAL_DIR/$base_file" >> "$PATH_LIST"
      done

    else
      echo "Directory $DIR_PATH does not exist."
    fi

  done < "$FileList"
else
  echo "$JOB_ID not found!"
fi