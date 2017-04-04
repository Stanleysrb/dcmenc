#!/bin/bash
export DCMDICTPATH=/usr/local/share/dcmtk/dicom.dic:/usr/local/share/dcmtk/private.dic:/usr/local/share/dcmtk/diconde.dic:/home/dcmtk/resources/private.dic
PRIVATE_TAG_BLOCK="0909"
PRIVATE_CREATOR=99
FULL_CREATOR="$PRIVATE_TAG_BLOCK,00$PRIVATE_CREATOR"
PRIVATE_TAG_LOCATION="$PRIVATE_TAG_BLOCK,$PRIVATE_CREATOR"00""
echo $PRIVATE_TAG_LOCATION
TAGS=`dcmdump +P "$PRIVATE_TAG_LOCATION" "$1" | awk -F'[][]' '{print $2}'`
ARRAY=($TAGS)
echo $ARRAY
for TAG in "${ARRAY[@]}"; do
        echo $TAG
        DATA=`dcmdump +P "$TAG" "$1" | awk -F'[][]' '{print $2}'`
        ENCRYPTEDDATA=`echo $DATA | awk -F',' '{print $3}'`
        echo $DATA
        echo $ENCRYPTEDDATA
        DECRYPTEDDATA=`echo $ENCRYPTEDDATA | openssl enc -d -base64 -aes-256-ctr -pass pass:stefan`
        FULL_TAG=`echo $DATA | awk -F',' '{print $1","$2}'`
        echo $FULL_TAG
        dcmodify -m $FULL_TAG="$DECRYPTEDDATA" "$1"
        dcmodify -e $TAG "$1"
done
dcmodify -e $FULL_CREATOR "$1"
dcmodify -e $PRIVATE_TAG_LOCATION "$1"

