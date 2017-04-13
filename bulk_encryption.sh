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

# Variable to concatenate all input arguments like -e -p etc.
INPUT_ARGS=""

if [ ! -z "$PRIVATE_TAG_BLOCK" ]; then
	INPUT_ARGS="-p $PRIVATE_TAG_BLOCK"
fi

if [ ! -z "$ENC_PASSWORD" ]; then
	INPUT_ARGS="$INPUT_ARGS -e $ENC_PASSWORD"
fi


if [ -z "$FILES" ]; then
	echo "No DICOM files in folder path which was specified. Exiting"; exit 1;
else
#	JOBS=()
#	for FILE in "${FILES[@]}"; do
#		JOBS+=("/bin/bash /home/root/repo/dcmenc/basic_encryption.sh -f \"$FILE\"")
#	done
#	printf '%s\n' "${JOBS[@]}" | 

# find "$FOLDER_PATH" -name "*.dcm" -print0 | xargs -0 -n 1 -I file bash -c /home/root/repo/dcmenc/basic_encryption.sh -f filei
#	find "$FOLDER_PATH" -name "*.dcm" -print0 | xargs -0 -P 1 -n 1 -I file /bin/bash /home/root/repo/dcmenc/basic_encryption.sh -f file > /home/dcmtk/logs/log.txt

find "$FOLDER_PATH" -name "*.dcm" | parallel --joblog /home/smihajlovic/joblog.txt --bar -j 4 /bin/bash /home/root/repo/dcmenc/basic_encryption.sh $INPUT_ARGS -f 

fi

DATE=`date`
echo "end $DATE" >> /home/dcmtk/resources/ANONYMIZE/log.txt
