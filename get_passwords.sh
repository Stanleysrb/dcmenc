#!/bin/bash

# Get command options and process them:

while getopts "d:l:u:h" arg; do
    case "$arg" in
        d ) PASSWORD_FILE="${OPTARG}";;
        l ) CONFIDENTIALITY_LEVEL="${OPTARG}";;
        u ) UNIQUE_ID="${OPTARG}";;
	h ) echo "The following parameters are supported: -d PASSWORD_FILE (File containing decryption password) -l CONFIDENTIALITY_LEVEL (The level of confidentiality you want to extract password for) -u UNIQUE_ID (The unique identifier of a file you need password for)"; exit 1;;
	-- ) ;;
        * ) if [ -z "$1" ]; then break; else echo "$1 is not a valid option."; exit 1; fi;;
    esac
done

# Check whether password file has been supplied, searching for unique ID, and setting ENC_PASSWORD.
if [ ! -z "$PASSWORD_FILE" ]; then
        echo "USING CUSTOM PASSWORD FILE";
else
        echo "Using default password file"
        PASSWORD_FILE="$KEYFILE"
fi

if [ -z "$CONFIDENTIALITY_LEVEL" ]; then
	CONFIDENTIALITY_LEVEL=3
fi

if [ -z "$KEYFILE" ]; then
        echo "Keyfile variable not found in .bashrc"
        exit 1;
else
        echo "Searching for the following UNIQUE_ID $UNIQUE_ID"
        ENC_PASSWORD=`grep "$UNIQUE_ID" "$PASSWORD_FILE" | awk -F',' '{print $2}' | cut -c -$(($CONFIDENTIALITY_LEVEL*64))`
        if [ -z "$ENC_PASSWORD" ]; then
                echo "Unable to find password for this UID"; exit 1;
        fi
fi

echo $UNIQUE_ID,$ENC_PASSWORD
