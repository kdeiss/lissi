#!/bin/bash

# k.deiss@it-userdesk.de
# radio.net scraper
# V.01.04.04.23

BASENAME="radio-net-scraper"
BASENAME="temp"

BASEPATH="/opt/$BASENAME"
BNVARIANT="$BASENAME"

LOG="$BASEPATH/${BNVARIANT}.log"
LOGDEB="$BASEPATH/DEB_${BNVARIANT}.log"
TMPF="/tmp/${BNVARIANT}.tmp"
TMPF1="/tmp/${BNVARIANT}1.tmp"
TMPF2="/tmp/${BNVARIANT}2.tmp"
NULL=./null
OUTDIR="RadioLib"
OUTDIR4HTML="html"
M3UDIR="m3u"

HTMLQ="/root/.cargo/bin/htmlq"
EMPTYLINK="NO_RESULT"

CUR_GENRES_POS_FNAME="./`basename $0`.pos"
let CURLCTR=0
let SLEEPTIME=180

echo "6" >one-category.sh.pos
rm -f AA-tropical.lastseen
./one-category.sh 20

rm -f $NULL
