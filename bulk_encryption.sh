#!/bin/bash

# Get command options and process them:

while getopts "f:ap:u:h" arg; do
    case "$arg" in
        a ) TAGS=1;;
        f ) FOLDER_PATH="${OPTARG}";;
        p ) PRIVATE_TAG_BLOCK="${OPTARG}";;
        h ) echo "HELP TEXT GOES HERE, WILL BE DEFINED WHEN ALL OTHER THINGS ARE DONE"; exit 1;;
        -- ) ;;
        * ) if [ -z "$1" ]; then break; else echo "$1 is not a valid option"; exit 1; fi;;
    esac
done

TIMELOG=`date`

if [ -z "$FOLDER_PATH" ]; then
        echo "No DICOM folder path specified. Exiting"; exit 1;
else
	while IFS= read -r -d $'\0' file; do
		FILES[i]="$file"        # or however you want to process each file
		i=$((i+1))
	done < <(find "$FOLDER_PATH" -name "*.dcm" -print0)        
fi

# Variable to concatenate all input arguments like -e -p etc.
INPUT_ARGS="-i "

if [ ! -z "$PRIVATE_TAG_BLOCK" ]; then
	INPUT_ARGS="$INPUT_ARGS -p $PRIVATE_TAG_BLOCK"
fi


if [ -z "$FILES" ]; then
	echo "No DICOM files in folder path which was specified. Exiting"; exit 1;
else

UNIQUE_ID=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
ENC_PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 192 | head -n 1`
echo "$UNIQUE_ID,$ENC_PASSWORD" >> $KEYFILE
INPUT_ARGS="$INPUT_ARGS -u $UNIQUE_ID -e $ENC_PASSWORD"

find "$FOLDER_PATH" -name "*.dcm" | parallel --joblog $JOBLOG --bar -j 4 /bin/bash $DCMENCHOME/basic_encryption.sh $INPUT_ARGS -f 

fi

echo "JOB STARTED AT:" $TIMELOG
TIMELOG=`date`
echo "JOB FINISHED AT:" $TIMELOG
