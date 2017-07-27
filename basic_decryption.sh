#!/bin/bash

# Get command options and process them:

while getopts "f:p:e:d:h" arg; do
    case "$arg" in
        f ) FILEPATH="${OPTARG}";;
        p ) PRIVATE_TAG_BLOCK="${OPTARG}";;
        e ) ENC_PASSWORD="${OPTARG}";;
        d ) PASSWORD_FILE="${OPTARG}";;
        h ) echo "HELP TEXT GOES HERE, WILL BE DEFINED WHEN ALL OTHER THINGS ARE DONE"; exit 1;;
        -- ) ;;
        * ) if [ -z "$1" ]; then break; else echo "$1 is not a valid option. Use -h for help."; exit 1; fi;;
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

# Check whether password file has been supplied, searching for unique ID, and setting ENC_PASSWORD.

if [ -z "$ENC_PASSWORD" ];then
    if [ -z "$PASSWORD_FILE" ]; then
            echo "Using default password file"
            PASSWORD_FILE="$KEYFILE"
	else
	    echo "USING CUSTOM PASSWORD FILE";
    fi
    if [ -z "$KEYFILE" ]; then
            echo "Keyfile variable not found in .bashrc"
            exit 1;
    else
            echo "Searching for the following UNIQUE_ID $UNIQUE_ID"
            ENC_PASSWORD=`grep "$UNIQUE_ID" "$PASSWORD_FILE" | awk -F',' '{print $2}'`
            if [ -z "$ENC_PASSWORD" ]; then
                    echo "Unable to find password for this file, please specify password manually"; exit 1;
            fi
    fi
fi

# Put password file variable , possibly in variables file

if [ ${#ENC_PASSWORD} = 192 ]; then
        ALLOWED_LEVEL=3
elif [ ${#ENC_PASSWORD} = 128 ]; then
        ALLOWED_LEVEL=2
elif [ ${#ENC_PASSWORD} = 64 ]; then
        ALLOWED_LEVEL=1
else
        echo "BAD PASSWORD LENGTH, EXITING!"
        exit;
fi
echo "ALLOWED LEVEL:" $ALLOWED_LEVEL

LOCATOR_DATA="$UNIQUE_ID,"

ARRAY=($TAGS)
echo ${ARRAY[*]}
for TAG in "${ARRAY[@]}"; do
        echo $TAG
        DATA=`dcmdump +L +P "$TAG" "$FILEPATH" | cut -c 17- | awk -F'][[:space:]]+#[[:space:]]' '{print $1}'`
        ENCRYPTEDDATA=`echo $DATA | awk -F'[,]' '{print $NF}'`
        echo "DATA IS:" $DATA
        echo "ENCRYPTED DATA IS:" $ENCRYPTEDDATA
        CONFIDENTIALITY_LEVEL="${DATA:0:1}"
        echo "CONFIDENTIALITY_LEVEL: " $CONFIDENTIALITY_LEVEL
        if [ $CONFIDENTIALITY_LEVEL -gt $ALLOWED_LEVEL ]; then 
            echo "No password for this confidentiality level, skipping"
	    LOCATOR_DATA="$LOCATOR_DATA$TAG "
            continue;
        fi
        TEMP_ENC_PASSWORD=`echo $ENC_PASSWORD | cut -c $(($CONFIDENTIALITY_LEVEL*64-63))-$(($CONFIDENTIALITY_LEVEL*64))`
        DECRYPTEDDATA=`echo $ENCRYPTEDDATA | openssl enc -d -base64 -A -aes-256-ctr -pass pass:$TEMP_ENC_PASSWORD`
        echo "DECRYPTED DATA IS: $DECRYPTEDDATA"
        FULL_TAG=`echo $DATA | awk 'BEGIN{FS=OFS=","}{NF--;print}' | cut -c 3-`
        echo "FULL TAG IS:" $FULL_TAG
        dcmodify -nb -i "$FULL_TAG"="$DECRYPTEDDATA" "$FILEPATH"
        dcmodify -nb -e $TAG "$FILEPATH"
done

if [ $ALLOWED_LEVEL = 3 ]; then
	dcmodify -nb -e $FULL_CREATOR "$FILEPATH"
	dcmodify -nb -e $PRIVATE_TAG_LOCATION "$FILEPATH"
else
	dcmodify -nb -m $PRIVATE_TAG_LOCATION="$LOCATOR_DATA" "$FILEPATH"
fi

