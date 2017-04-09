#!/bin/bash

# export variable - path to private dictionary:

export DCMDICTPATH=/usr/local/share/dcmtk/dicom.dic:/usr/local/share/dcmtk/private.dic:/usr/local/share/dcmtk/diconde.dic:/home/dcmtk/resources/private.dic

# Get command options and process them:

while getopts "f:ap:" arg; do
    case "$arg" in
        a ) TAGS=("0008,0080" "0008,0090");;
        f ) FILEPATH="${OPTARG}";;
	p ) PRIVATE_TAG_BLOCK="${OPTARG}";;
        -- ) ;;
        * ) if [ -z "$1" ]; then break; else echo "$1 is not a valid option"; exit 1; fi;;
    esac
done

# Check whether file path has been specified, and whether file has extension ".dcm".

if [ -z "$FILEPATH" ]; then 
	echo "No DICOM file path specified. Exiting"; exit 1;	
else
	if [[ ${FILEPATH: -4} != ".dcm" ]]; then
		echo "Not a .dcm file. Exiting"; exit 1;
	fi
fi

#DYNAMIC TAGS, GET ALL TAGS FROM A DICOM FILE AND MAKE AN ARRAY

if [ -z "$TAGS" ]; then
        TAGS=("0008,0080" "0008,0090" "0008,0060" "0008,0070")
fi

# Generate Unique ID of a file and encryption password:

UNIQUE_ID=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
ENC_PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 128 | head -n 1`

# Check whether Private Tag block has been manually specified:

if [ -z "$PRIVATE_TAG_BLOCK" ]; then
	PRIVATE_TAG_BLOCK="0909"
fi

#NEEDS TO BE DYNAMIC, TO HAVE A PARAMETERIZED PRIVATE_TAG_BLOCK
PRIVATE_CREATOR=99
FULL_CREATOR="$PRIVATE_TAG_BLOCK,00$PRIVATE_CREATOR"
INCREMENT=1

# Check whether data already exists:
echo "Checking for existing data inside Private Tag Block"
for i in {1..255} 
do
	HEX_INCREMENT=$( printf "%02x" $i );
	FULL_TAG="$PRIVATE_CREATOR$HEX_INCREMENT"
        FULL_TAG="$PRIVATE_TAG_BLOCK,$FULL_TAG"
	EXISTING_DATA=`dcmdump +P "$FULL_TAG" "$FILEPATH"`
	if [ ! -z "$EXISTING_DATA" ]; then
	    echo "ERROR: Data already exists, please manually specify Private Tag Block"
	exit 1;
	fi
done

NEW_TAGS=""
dcmodify -i $FULL_CREATOR="DICOM_ENCRYPTION" "$FILEPATH"
for TAG in "${TAGS[@]}"; do
	HEX_INCREMENT=$( printf "%02x" $INCREMENT );
	FULL_TAG="$PRIVATE_CREATOR$HEX_INCREMENT"      
	FULL_TAG="$PRIVATE_TAG_BLOCK,$FULL_TAG"
        NEW_TAGS="$NEW_TAGS$FULL_TAG "
        INCREMENT=$((INCREMENT+1))
        DATA=`dcmdump +P "$TAG" "$FILEPATH" | awk -F'[][]' '{print $2}' | openssl enc -e -base64 -aes-256-ctr -pass pass:$ENC_PASSWORD`
        echo  "$TAG"
        DATA=$TAG,$DATA
        dcmodify -m $TAG="ENCRYPTED" "$FILEPATH"
        echo "TAG:" $TAG "FULL TAG:" $FULL_TAG $FILEPATH
        dcmodify -i "$FULL_TAG"="$DATA" "$FILEPATH"
done
FULL_TAG=$(($PRIVATE_CREATOR*100))
FULL_TAG="$PRIVATE_TAG_BLOCK,$FULL_TAG"
DESCRIPTOR_TAG="$UNIQUE_ID,$NEW_TAGS"
dcmodify -i $FULL_TAG="$DESCRIPTOR_TAG" "$FILEPATH"

echo "BUILT DESCRIPTOR TAG: $DESCRIPTOR_TAG"
echo "ENCRYPTION PASSWORD: $ENC_PASSWORD" 
echo "UNIQUE_ID: $UNIQUE_ID"
KEYFILE="/home/smihajlovic/keys.txt"
echo "Dumping key data to keyfile $KEYFILE"
echo "$UNIQUE_ID,$ENC_PASSWORD" >> $KEYFILE
