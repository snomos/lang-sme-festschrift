#!/bin/bash

###### Variables: #######
IPAFST=../text2ipa.hfst

#### Actual test: ####
if test -f $INPUTFILE ; then
    if ! /usr/local/bin/hfst-lookup -q $IPAFST < $INPUTFILE > $OUTPUTFILE ; then
        echo turning $INPUTFILE into IPA failed!
        exit 1
    fi
    if ! diff $OUTPUTFILE $EXPECTFILE > /dev/null 2>&1 ; then
        echo $OUTPUTFILE differs from $EXPECTFILE
        exit 1
    fi
    rm $OUTPUTFILE
else
    echo $INPUTFILE not found!
    exit 77
fi
