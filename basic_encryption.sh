#!/bin/bash
export DCMDICTPATH=/usr/local/share/dcmtk/dicom.dic:/usr/local/share/dcmtk/private.dic:/usr/local/share/dcmtk/diconde.dic:/home/dcmtk/resources/private.dic

while getopts "f:a" arg; do
    case "$arg" in
        a ) TAGS=("0008,0080" "0008,0090");;
        f ) FILEPATH="${OPTARG}";;
        -- ) ;;
        * ) if [ -z "$1" ]; then break; else echo "$1 is not a valid option"; exit 1; fi;;
    esac
done

if [ -z "$TAGS" ]; then
        TAGS=("0008,0080" "0008,0090" "0008,0060" "0008,0070")
fi

ENC_PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 128 | head -n 1`

PRIVATE_TAG_BLOCK="0909"
PRIVATE_CREATOR=99
FULL_CREATOR="$PRIVATE_TAG_BLOCK,00$PRIVATE_CREATOR"
INCREMENT=1
NEW_TAGS=""
dcmodify -i $FULL_CREATOR="DICOM_ENCRYPTION" "$FILEPATH"
for TAG in "${TAGS[@]}"; do
        FULL_TAG=$(($PRIVATE_CREATOR*100+$INCREMENT))
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
dcmodify -i $FULL_TAG="$NEW_TAGS" "$FILEPATH"
echo "$ENC_PASSWORD"
