#!/bin/bash

# Get command options and process them:

while getopts "f:ap:e:u:h" arg; do
    case "$arg" in
        a ) TAGS=1;;
        f ) FOLDER_PATH="${OPTARG}";;
        p ) PRIVATE_TAG_BLOCK="${OPTARG}";;
        e ) ENC_PASSWORD="${OPTARG}";;
        h ) echo "HELP TEXT GOES HERE, WILL BE DEFINED WHEN ALL OTHER THINGS ARE DONE"; exit 1;;
        -- ) ;;
        * ) if [ -z "$1" ]; then break; else echo "$1 is not a valid option"; exit 1; fi;;
    esac
done

DATE=`date`
echo "start $DATE" >> /home/dcmtk/resources/ANONYMIZE/log.txt

if [ -z "$FOLDER_PATH" ]; then
        echo "No DICOM folder path specified. Exiting"; exit 1;
else
	while IFS= read -r -d $'\0' file; do
		FILES[i]="$file"        # or however you want to process each file
		i=$((i+1))
	done < <(find "$FOLDER_PATH" -name "*.dcm" -print0)        
fi

if [ -z "$FILES" ]; then
	echo "No DICOM files in folder path which was specified. Exiting"; exit 1;
else
	callencryption(){
			/bin/bash /home/root/repo/dcmenc/basic_encryption.sh -f "$1"
		}
	N=16
	(
	for FILE in "${FILES[@]}"; do
		((i=i%N)); ((i++==0)) && wait
		callencryption "$FILE" &
	done
	)
fi

DATE=`date`
echo "end $DATE" >> /home/dcmtk/resources/ANONYMIZE/log.txt