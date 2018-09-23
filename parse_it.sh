#!/bin/bash

########################################
#
# Steve Willson
# parse_it.sh
# 9/20/18
#
# parse_it.sh takes a pre-defined note file (written in asciidoc)
# and separates out commands, research, techniques, hostinfo and
# generates an .html of the .adoc file using asciidoctor and
# saves all of the information in a directory based off of the file name
#
########################################

# enable debugging output
DEBUG="1"

# the note file name should have the syntax 
# YYYY-MM-DD-MACHINE_NOTES.adoc
INPUT_NOTE_FILE=$1

if [ "$DEBUG" = "1" ]; then echo "DEBUG: Setting input file to $INPUT_NOTE_FILE"; fi

# parse the file name and make a directory with that filename (strip off the extension)
FULL_FILE_NAME=$(basename -- "$INPUT_NOTE_FILE")
FILE_NAME="${FULL_FILE_NAME%.*}"
FILE_EXTENSION="${FULL_FILE_NAME##*.}"

OUTPUT_DIR=$FILE_NAME

if [ "$DEBUG" = "1" ]; then echo "DEBUG: Setting FULL_FILE_NAME to $FULL_FILE_NAME"; fi
if [ "$DEBUG" = "1" ]; then echo "DEBUG: Setting FILE_NAME to $FILE_NAME"; fi
if [ "$DEBUG" = "1" ]; then echo "DEBUG: Setting FILE_EXTENSION to $FILE_EXTENSION"; fi
if [ "$DEBUG" = "1" ]; then echo "DEBUG: Setting OUTPUT_DIR to $OUTPUT_DIR"; fi

if [ "$DEBUG" = "1" ]; then echo "DEBUG: Creating output directory ./$OUTPUT_DIR"; fi

mkdir -p $OUTPUT_DIR


# check to see if there is a need to create the COMMANDS file
if grep -qE "^ (\\$|\#)" $INPUT_NOTE_FILE; then
    if [ "$DEBUG" = "1" ]; then echo "DEBUG: Writing COMMANDS file to ./$OUTPUT_DIR/COMMANDS_$INPUT_NOTE_FILE.sh"; fi
    cat << EOF > ./$OUTPUT_DIR/COMMANDS_$FILE_NAME.txt
# This file contains commands that were issued during date DATE on machine MACHINE
# lines that begin with '$' are issued as a regular user
# lines that begin with '#' are issued as a regular user

EOF
    grep -E "^ (\\$|\#)" $INPUT_NOTE_FILE >> ./$OUTPUT_DIR/COMMANDS_$FILE_NAME.txt
else 
    if [ "$DEBUG" = "1" ]; then echo "DEBUG: No commands found, skipping"; fi
fi

# check to see if there is a need to create the RESEARCH file
if grep -qE "^RESEARCH:" $INPUT_NOTE_FILE; then
    # make other files that have RESEARCH and TECHNIQUE topics in them
    cat << EOF > ./$OUTPUT_DIR/RESEARCH_$FILE_NAME.txt
# This file contains topics for further research that were encountered
EOF
    grep -E "^RESEARCH:" $INPUT_NOTE_FILE >> ./$OUTPUT_DIR/RESEARCH_$FILE_NAME.txt
else 
    if [ "$DEBUG" = "1" ]; then echo "DEBUG: No RESEARCH tags found, skipping"; fi
fi

# check to see if there is a need to create the TECHNIQUE file
if grep -qE "^TECHNIQUE:" $INPUT_NOTE_FILE; then
    cat << EOF > ./$OUTPUT_DIR/TECHNIQUE_$FILE_NAME.txt
# This file contains techniques that are valuable to retain
EOF
    grep -E "^TECHNIQUE:" $INPUT_NOTE_FILE >> ./$OUTPUT_DIR/TECHNIQUE_$FILE_NAME.txt
else 
    if [ "$DEBUG" = "1" ]; then echo "DEBUG: No TECHNIQUE tags found, skipping"; fi
fi

# save the hostinfo out of the file
# read the file line by line, look for the beginning of hostinfo
hostinfo=0
while IFS="" read -r line || [ -n "$line" ]; do
    if [[ $line = *"source, hostinfo"* ]]; then
        # the start of a hostinfo section, should be surrounded by '----', this will allow nesting hostinfo within hostinfo. But is this necessary?
        hostinfo=$(($hostinfo + 2))
        if [ "$DEBUG" = "1" ]; then echo "DEBUG: hostinfo section found, hostinfo is $hostinfo"; fi
    fi
    if [ $hostinfo -ge 1 ]; then
        echo $line >> ./$OUTPUT_DIR/HOSTINFO_$FILE_NAME.txt
        # look at least one line past to find the next '----' 
        if [[ $line = "----" ]]; then
            hostinfo=$(($hostinfo - 1))
        fi
    fi
done < "$FULL_FILE_NAME"

# parse the file using asciidoctor or save the raw input file if asciidoctor is not installed
if $(which asciidoctor > /dev/null 2>&1); then
    if [ "$DEBUG" = "1" ]; then echo "DEBUG: Asciidoctor is installed, parsing the file and saving it to the ./$OUTPUT_DIR directory"; fi
    #parse with asciidoctor
    asciidoctor --quiet -D ./$OUTPUT_DIR $FULL_FILE_NAME
else
   if [ "$DEBUG" = "1" ]; then echo "Asciidoctor not found, copying raw .adoc file to the ./$OUTPUT_DIR directory"; fi
   cp $FULL_FILE_NAME ./$OUTPUT_DIR/
fi

