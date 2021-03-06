#!/bin/bash

# Get command options and process them:

while getopts "f:p:e:u:h" arg; do
    case "$arg" in
        f ) FOLDER_PATH="${OPTARG}";;
        p ) PRIVATE_TAG_BLOCK="${OPTARG}";;
	e ) ENC_PASSWORD="${OPTARG}";;
	u ) UNIQUE_ID="${OPTARG}";;
        h ) echo "The following parameters are supported: -f FOLDER_PATH (Folder containing study you want to encrypt) -p PRIVATE_TAG_BLOCK (Custom Private Tag Block) -e ENC_PASSWORD (Custom 192 character password) -u UNIQUE_ID (Custom Unique ID)"; exit 1;;
        -- ) ;;
        * ) if [ -z "$1" ]; then break; else echo "$1 is not a valid option"; exit 1; fi;;
    esac
done

TIMELOG=`date`

if [ -z "$FOLDER_PATH" ]; then
        echo "No DICOM folder path specified. Exiting"; exit 1;
else
	while IFS= read -r -d $'\0' file; do
		FILES[i]="$file"
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

if [ -z "$UNIQUE_ID" ]; then
        UNIQUE_ID=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
fi

if [ -z "$ENC_PASSWORD" ]; then
        ENC_PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 192 | head -n 1`
elif [ ${#ENC_PASSWORD} != 192 ]; then
        echo "BAD PASSWORD LENGTH, EXITING"
fi

echo "$UNIQUE_ID,$ENC_PASSWORD" >> $KEYFILE
INPUT_ARGS="$INPUT_ARGS -u $UNIQUE_ID -e $ENC_PASSWORD"

find "$FOLDER_PATH" -name "*.dcm" | parallel --joblog $JOBLOG --bar -j 2 /bin/bash $DCMENCHOME/basic_encryption.sh $INPUT_ARGS -f 

fi

echo "JOB STARTED AT:" $TIMELOG
TIMELOG=`date`
echo "JOB FINISHED AT:" $TIMELOG
