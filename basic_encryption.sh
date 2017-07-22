#!/bin/bash

# Get command options and process them:

while getopts "f:p:e:u:h" arg; do
    case "$arg" in
#       a ) TAGS=1;;
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

#Dynamic tags, get all tags from a file except meta and pixel data, if parameter "-a" has been supplied, if not, standard set of tags is supplied by DICOM anonymization standard.

# if [ -z "$TAGS" ]; then
#        TAGS=("2,0008,0014" "3,0008,0018" "1,0008,0050" "3,0008,0080" "1,0008,0081" "2,0008,0090" "1,0008,0092" "3,0008,0094" "1,0008,1010" "1,0008,1030" "1,0008,103E" "1,0008,1040" "1,0008,1048" "1,0008,1050" "1,0008,1060" "1,0008,1070" "1,0008,1080" "1,0008,1155" "1,0008,2111" "1,0010,0010" "1,0010,0020" "1,0010,0030" "1,0010,0032" "1,0010,0040" "1,0010,1000" "1,0010,1001" "1,0010,1010" "1,0010,1020" "1,0010,1030" "1,0010,1090" "1,0010,2160" "1,0010,2180" "1,0010,21B0" "1,0010,4000" "1,0018,1000" "1,0018,1030" "1,0020,000D" "1,0020,000E" "1,0020,0010" "1,0020,0052" "1,0020,0200" "1,0020,4000" "1,0040,A124" "1,0040,A730" "1,0088,0140" "1,3006,0024" "1,3006,00C2" "1,0040,0275.0032,1064.0008,0100")
#        else
#        LINE_NUM=`dcmdump "$FILEPATH" | grep -E '(7fe0,0010)' -i -n | awk -F':' '{print $1}'`
#        LINE_NUM=$((LINE_NUM-1))
#        TEMP_TAGS=`dcmdump "$FILEPATH" | head -n$LINE_NUM | awk -F'[)(]' '{print $2}' | grep '[0-9a-fA-F]\{4\},[0-9a-fA-F]\{4\}' | grep -v '0002,' `
#        IFS=' ' read -r -a TAGS <<< $TEMP_TAGS
# fi
#
# Insert thread level logging!!!
#



TAGS=("2,0008,0014" "3,0008,0018" "1,0008,0050" "3,0008,0080" "1,0008,0081" "2,0008,0090" "1,0008,0092" "3,0008,0094" "1,0008,1010" "1,0008,1030" "1,0008,103E" "1,0008,1040" "1,0008,1048" "1,0008,1050" "1,0008,1060" "1,0008,1070" "1,0008,1080" "1,0008,1155" "1,0008,2111" "1,0010,0010" "1,0010,0020" "1,0010,0030" "1,0010,0032" "1,0010,0040" "1,0010,1000" "1,0010,1001" "1,0010,1010" "1,0010,1020" "1,0010,1030" "1,0010,1090" "1,0010,2160" "1,0010,2180" "1,0010,21B0" "1,0010,4000" "1,0018,1000" "1,0018,1030" "1,0020,000D" "1,0020,000E" "1,0020,0010" "1,0020,0052" "1,0020,0200" "1,0020,4000" "1,0040,A124" "1,0040,A730" "1,0088,0140" "1,3006,0024" "1,3006,00C2" "1,0040,0275.0032,1064.0008,0100")

# Generate Unique ID of a file and encryption password if not supplied manually:

if [ -z "$UNIQUE_ID" ]; then
        UNIQUE_ID=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
fi

if [ -z "$ENC_PASSWORD" ]; then
        ENC_PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 192 | head -n 1`
fi
# Check whether Private Tag block has been manually specified:

if [ -z "$PRIVATE_TAG_BLOCK" ]; then
        PRIVATE_TAG_BLOCK="0909"
fi


PRIVATE_CREATOR=99
FULL_CREATOR="$PRIVATE_TAG_BLOCK,00$PRIVATE_CREATOR"
INCREMENT=1

# Check whether data already exists:
echo "Checking for existing data inside Private Tag Block"

EXISTING_DATA=`dcmdump +L "$FILEPATH" | grep "($PRIVATE_TAG_BLOCK,$PRIVATE_CREATOR"'[0-9a-fA-F]\{2\}'")"`
        if [ ! -z "$EXISTING_DATA" ]; then
            echo "ERROR: Data already exists, please manually specify Private Tag Block"
        exit 1;
        fi
NEW_TAGS=""
OLD_TAGS=""
NEW_TAGS_DATA=""
dcmodify -i $FULL_CREATOR="DICOM_ENCRYPTION" "$FILEPATH"
for TAG in "${TAGS[@]}"; do
        HEX_INCREMENT=$( printf "%02x" $INCREMENT );
        CONFIDENTIALITY_LEVEL=`echo $TAG | cut -c 1`
        TAG=`echo $TAG | cut -c 3-`
        TEMP_ENC_PASSWORD=`echo $ENC_PASSWORD | cut -c $(($CONFIDENTIALITY_LEVEL*64-63))-$(($CONFIDENTIALITY_LEVEL*64))`
        if [ ${#TAG} != 9 ]; then
                echo "TAG" $TAG "is LONG"
                LONG_TAG=$TAG
                LONG_TAG_CHECKER=`echo $TAG | awk '{ gsub("\\\.",".*"); print $0}'`
                echo $LONG_TAG_CHECKER
                CUTTER=${#TAG}
                CUTTER=`expr $CUTTER - 8`
                echo $CUTTER
                TAG=`echo $TAG | cut -c $CUTTER-`
                DATA_EXISTS=`dcmdump +L +P "$TAG" +p "$FILEPATH" | grep "$LONG_TAG_CHECKER"`
                echo "DATA_EXISTS:" $DATA_EXISTS
                #REVERT TAG TO LONG VALUE
                TAG=`echo $LONG_TAG | awk '{ gsub("\\\.",")[0].("); print $0}'`
                TAG="("$TAG")"
                echo "LONG TAG IS NOW:" $TAG
        else
                echo "TAG" $TAG "is short"
                DATA_EXISTS=`dcmdump +L +P "$TAG" "$FILEPATH"`
                echo "DATA_EXISTS:" $DATA_EXISTS
                ROW_COUNT=`echo $DATA_EXISTS | grep -e '\s#\s[0-9]*,\s[0-9]*\s[a-zA-Z0-9]*\s([0-9a-fA-F]\{4\},[0-9a-fA-F]\{4\})' -o | wc -l`
                if [ $ROW_COUNT -gt 1 ]; then
                        echo "Warning: Multiple rows for tag, skipping tag $TAG"
                        continue;
                fi
        fi
# Check if tag is empty
        if [ -z "$DATA_EXISTS"  ] || [[ $(echo $DATA_EXISTS | grep -e '([0-9a-fA-F]\{4\},[0-9a-fA-F]\{4\})\s.\{2\}\s(no value available)\s#') ]]; then
                echo "TAG EMPTY $TAG"
                continue;
        fi
        DATA=`echo $DATA_EXISTS | awk -F'[][]' '{print $2}'`
        if [ -z "$DATA" ]; then
                DATA=`dcm2xml "$FILEPATH" | grep "tag=\"${TAG}\"" | awk  'BEGIN {RS="<[^>]+>"} {print $0}' | openssl enc -e -base64 -A -aes-256-ctr -pass pass:$TEMP_ENC_PASSWORD`
        else
#CAN BE SLIGHTLY SHORTER!!!
                DATA=`echo $DATA_EXISTS | awk -F'[][]' '{print $2}' | openssl enc -e -base64 -A -aes-256-ctr -pass pass:$TEMP_ENC_PASSWORD`
        fi
        echo "TAG $TAG OK!!!"
        FULL_TAG="$PRIVATE_TAG_BLOCK,$PRIVATE_CREATOR$HEX_INCREMENT"
#       FULL_TAG="$PRIVATE_TAG_BLOCK,$FULL_TAG"
        NEW_TAGS="$NEW_TAGS$FULL_TAG "
        INCREMENT=$((INCREMENT+1))
#        echo "$TAG"
        DATA=$CONFIDENTIALITY_LEVEL,$TAG,$DATA
        OLD_TAGS="$OLD_TAGS -e $TAG"
#       echo "OLD TAGS:" $OLD_TAGS
      #  dcmodify -m $TAG="" "$FILEPATH"
 #       echo "TAG:" $TAG "FULL TAG:" $FULL_TAG $FILEPATH
        NEW_TAGS_DATA="$NEW_TAGS_DATA -i $FULL_TAG=$DATA"
#       echo "NEW tags data" $NEW_TAGS_DATA
        # dcmodify -i "$FULL_TAG"="$DATA" "$FILEPATH"
done

echo "REMOVING OLD TAG DATA"
dcmodify -nb "$FILEPATH" $OLD_TAGS -v
echo "$OLD_TAGS" \'$FILEPATH\'
#echo "dcmodify" $NEW_TAG_DATA "$FILEPATH"
echo "Inserting new values in new tags"
dcmodify -nb $NEW_TAGS_DATA "$FILEPATH"
FULL_TAG=$(($PRIVATE_CREATOR*100))
FULL_TAG="$PRIVATE_TAG_BLOCK,$FULL_TAG"
DESCRIPTOR_TAG="$UNIQUE_ID,$NEW_TAGS"
echo "dcmodify -i" "$FULL_TAG=""$DESCRIPTOR_TAG" "$FILEPATH"
dcmodify -nb -i $FULL_TAG="$DESCRIPTOR_TAG" "$FILEPATH"

#echo "BUILT DESCRIPTOR TAG: $DESCRIPTOR_TAG"
#echo "ENCRYPTION PASSWORD: $ENC_PASSWORD"
#echo "UNIQUE_ID: $UNIQUE_ID"
#echo "Dumping key data to keyfile $KEYFILE"
echo "$UNIQUE_ID,$ENC_PASSWORD" >> $KEYFILE

