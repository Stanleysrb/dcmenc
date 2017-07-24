#!/bin/bash

# Get command options and process them:

while getopts "d:l:u:" arg; do
    case "$arg" in
        d ) PASSWORD_FILE="${OPTARG}";;
        l ) CONFIDENTIALITY_LEVEL="${OPTARG}";;
        u ) UNIQUE_ID="${OPTARG}";;
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
