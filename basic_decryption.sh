#!/bin/bash
export DCMDICTPATH=/usr/local/share/dcmtk/dicom.dic:/usr/local/share/dcmtk/private.dic:/usr/local/share/dcmtk/diconde.dic:/home/dcmtk/resources/private.dic


# Get command options and process them:

while getopts "f:p:e:u:h" arg; do
    case "$arg" in
        f ) FILEPATH="${OPTARG}";;
	p ) PRIVATE_TAG_BLOCK="${OPTARG}";;
	e ) ENC_PASSWORD="${OPTARG}";;
	u ) UNIQUE_ID="${OPTARG}";;
	h ) echo "HELP TEXT GOES HERE, WILL BE DEFINED WHEN ALL OTHER THINGS ARE DONE"; exit 1;;
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

# Check whether Private Tag block has been manually specified:

if [ -z "$PRIVATE_TAG_BLOCK" ]; then
	PRIVATE_TAG_BLOCK="0909"
fi

PRIVATE_CREATOR=99
FULL_CREATOR="$PRIVATE_TAG_BLOCK,00$PRIVATE_CREATOR"
PRIVATE_TAG_LOCATION="$PRIVATE_TAG_BLOCK,$PRIVATE_CREATOR"00""
echo $PRIVATE_TAG_LOCATION
LOCATOR_DATA=`dcmdump +L +P "$PRIVATE_TAG_LOCATION" "$FILEPATH" | awk -F'[][]' '{print $2}'`
if [ -z "$LOCATOR_DATA" ]; then
	echo "No Data in private tag block. Please manually specify if you have used custom Private block while encrypting. Exiting"; exit 1;
fi
UNIQUE_ID=`echo $LOCATOR_DATA | awk -F',' '{print $1}'`
TAGS=`echo $LOCATOR_DATA | awk -F',' '{ st = index($0,",");print substr($0,st+1)}'`

#SEARCH PASSWORD FILE FOR UNIQUE ID AND INJECT PASSWORD INTO VARIABLE


ARRAY=($TAGS)
echo $ARRAY
for TAG in "${ARRAY[@]}"; do
        echo $TAG
        DATA=`dcmdump +L +P "$TAG" "$FILEPATH" | awk -F'[][]' '{print $2}'`
        ENCRYPTEDDATA=`echo $DATA | awk -F',' '{print $3}'`
        echo $DATA
        echo $ENCRYPTEDDATA
        DECRYPTEDDATA=`echo $ENCRYPTEDDATA | openssl enc -d -base64 -aes-256-ctr -pass pass:Y9yfY9DM8gmYKcdgyHdEd6EAIxoHelUeYYs2MD1ypy5dX9V0QwTzIQ4pS2WHzAfB7d1KlofcReR0Si9jCxPUUbZKQrLhDstHhriGCpxYcZr7GRGhmCIneme1VQw3DWMo`
        FULL_TAG=`echo $DATA | awk -F',' '{print $1","$2}'`
        echo $FULL_TAG
        dcmodify -m $FULL_TAG="$DECRYPTEDDATA" "$FILEPATH"
        dcmodify -e $TAG "$FILEPATH"
done
dcmodify -e $FULL_CREATOR "$FILEPATH"
dcmodify -e $PRIVATE_TAG_LOCATION "$FILEPATH"

