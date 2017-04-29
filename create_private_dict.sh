#!/bin/bash

while getopts "f:ap:e:u:h" arg; do
    case "$arg" in
        f ) FILEPATH="${OPTARG}";;
        p ) PRIVATE_TAG_BLOCK="${OPTARG}";;
        h ) echo "HELP TEXT GOES HERE, WILL BE DEFINED WHEN ALL OTHER THINGS ARE DONE"; exit 1;;
        -- ) ;;
        * ) if [ -z "$1" ]; then break; else echo "$1 is not a valid option"; exit 1; fi;;
    esac
done

for i in {0..255}
do
	HEX_INCREMENT=$( printf "%02x" $i );
	echo -e "($PRIVATE_TAG_BLOCK,\"DICOM_ENCRYPTION\",$HEX_INCREMENT)\tLO\tENCRYPTED\t1\tPrivateTag" >> $FILEPATH
done


# STOP IF ITS NOT PRIVATE TAG BLOCK
