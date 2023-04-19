#!/bin/bash

# k.deiss@it-userdesk.de
# radio.net scraper

# Basic version and idea by jungler
# https://github.com/junguler/m3u-radio-music-playlists/blob/main/stuff/scrape-radio.net-manual.sh

# This version try to reduce traffic load to radio.net to a minimum

# V.01.04.04.23 redesign
# V.03.09.04.23 scrape_the_links2m3u - try to find unplausible linecounting
# V.04.16.04.23 html output including url
# V.05.18.04.23 html bugfixing / adding rm-old / upload

BASENAME="radio-net-scraper"

#BASEPATH=`pwd`
BASEPATH="/opt/lissi/scraper/radio.net"
GITPATH="/opt/lissi/"

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

OLD_REMOVER="$BASEPATH/rm-old.sh"
UPLOADER_HTML="$BASEPATH/upload-html.sh"
UPLOADER_M3U="$BASEPATH/upload-m3u.sh"

# edit if necessary
let SLEEPTIME=60
let DIFF_PLAUSI=150


if [ ! -z $1 ] ; then
    let SLEEPTIME=$1
fi

cd $BASEPATH

function scrape_the_links
{
# scrape the links
curl https://www.radio.net/genre | grep -oP 'href="\K[^"]+' | grep "https://www.radio.net/genre/" | sort -r| uniq | cut -c29- > genres.txt
let CURLCTR=$CURLCTR+1
}

function scrape_the_links_fake
{
# use a static list
cp ./genres.txt.1 ./genres.txt
}

# if we use the onebyone loop we need a list file genres-full.txt
# scrape_the_links_fake is feeded with the elements of the full file (one by one)
function scrape_the_links4onebyone
{
# scrape the links
curl https://www.radio.net/genre | grep -oP 'href="\K[^"]+' | grep "https://www.radio.net/genre/" | sort -r| uniq | cut -c29- > genres-full.txt
let CURLCTR=$CURLCTR+1
}


# remove all kind of A*** file
function clean_up
{
# clean up trash
rm -f A-*.txt
rm -f AA-*.txt
rm -f AAA-*.txt
rm -f AAAA-*.txt
rm -f AAAAA-*.txt
rm -f $NULL
rm -f *.txt.tmp
}


function get_the_links_for_the_webpages_ORG
{
# get the links for the webpages
for i in "" \?p={2..25} ; do for j in $(cat genres.txt) ; do curl -s https://www.radio.net/genre/$j$i | $HTMLQ -a href a | grep "https://www.radio.net/s/" | sed "1,20d" | tac | sed "1,30d" | tac >> A-$j.txt ; echo -e "$j - $i" ; done ; done
}


# to minimize the traffic it looks whether a call to a subpage produce more entries.
# value of 25 was to small to get all
function get_the_links_for_the_webpages
{
# get the links for the webpages
#for i in "" \?p={2..25}
for i in "" {2..50}
do 
    for j in $(cat genres.txt) 
    do
	if [ -z $i ];then
	    rm -f A-$j.txt
	    touch A-$j.txt
	    c_url="https://www.radio.net/genre/${j}"
	else
	    c_url="https://www.radio.net/genre/${j}?p=${i}"
	fi
	echo -e "$j - $c_url"
	cp A-$j.txt A-$j.txt.tmp
	curl -s "$c_url" | $HTMLQ -a href a | grep "https://www.radio.net/s/" | sed "1,20d" | tac | sed "1,30d" | tac | sort -u >> A-$j.txt
	let CURLCTR=$CURLCTR+1
	diff A-$j.txt A-$j.txt.tmp > $NULL
	if [ $? -eq 0 ] ; then
	    #echo "No change detected. Stop fetching!"
	    echo "`date` INF Get the links for the webpages done!($i)" | tee -a $LOG
	    rm -f A-$j.txt.tmp
	    break 2
	fi
	rm -f A-$j.txt.tmp
    done
done
}

function remove_duplicates_ORG
{
# remove duplicates links and cut the last 9 stream that are the same in each page
for i in A-*.txt ; do cat $i | awk '!seen[$0]++' | tac | sed "1,9d" | tac > A$i ; echo -e $i ; done
}

function remove_duplicates
{
# remove duplicates links and sort 
for i in A-*.txt
do 
    cat $i | sort -u > A$i
    #echo -e $i 
done
}


function scrape_the_links2m3u_ORG
{
# scrape the links from each text file to a m3u output
for i in AA-*.txt ; do for j in $(cat $i) ; do curl -s $j | grep "id=\"__NEXT_DATA__\"" | grep -Po '"url": *\K"[^"]*"' | sed 's/\"//g' | grep "/" | grep -v "radio.net" | head -n 1 | sed 's/\;//g' | sed '/^$/d' >> A$i ; echo -e "$i - $j" ; done ; done
}


function scrape_the_links2m3u
{
#set -x
# scrape the links from each text file to a m3u output
# working with jq to retrieve details from page
# creates AAA-<category> ==> linkcollection
# creates AAAA-<category> ==> the json data
# creates AAAAA-<category> ==> some data readable for bash
let absctr=0
let proflag=0
let catctr=0
for i in AA-*.txt 
do 
    let catctr=$catctr+1
    let proflag=0
    # check whether there is a difference to the last seen version
    if [ -f ${i//.txt/.lastseen} ];then
	diff ${i//.txt/.lastseen} $i >>$LOG
	if [ $? -eq 0 ] ;then
	    echo "`date` INF No change in $i" | tee -a $LOG
	    #return 1
	    let proflag=1
	    continue
	else
	    #diff detected change - check whether is plausible
	    lseen=`wc -l  ${i//.txt/.lastseen} | cut -f 1 -d " "`
	    actual=`wc -l $i | cut -f 1 -d " "`
	    ((diffc = $lseen-$actual))
	    echo "`date` INF Status => lastseen:$lseen/actual:$actual/difference:$diffc" | tee -a $LOG
	    if [ $diffc -gt $DIFF_PLAUSI ];then
		echo "`date` WAR unplausibe difference between ${i//.txt/.lastseen}($lseen) and ${i}($actual). Skip processing." | tee -a $LOG
		#return 1
		let proflag=1
		continue 
	    fi
	fi
    fi

    cp $i ${i//.txt/.lastseen}
    rm -f A$i
    rm -f AA$i
    rm -f AAA$i
    let mctr=0
    for j in $(cat $i)
    do 
	let mctr=$mctr+1
	let absctr=$absctr+1

	# isolate the json data (rst2)
	rst4=`curl -s $j | grep "id=\"__NEXT_DATA__\""| awk -F '}},' '{print $1}'`
	let CURLCTR=$CURLCTR+1
	rst2=${rst4#*\{\"id\":}
	rst2="{\"id\":${rst2}}}" 
	echo "$rst2" >> "AA$i"


	# retrieve url (rst)
	rst=`echo $rst2 | jq '.streams' | jq '.[].url'`
	# hack if there is more than one url
	rst=`echo $rst|cut -f 1 -d " "`
	# hack if link not properly quoted
	rst=${rst//\"/}

	# build the data (bash readable) for the AAA$i file (rst3)
	rst3="J_ID=`echo $rst2 | jq ".id"`"
	J_NAME=`echo $rst2 | jq ".name"`
	J_NAME=${J_NAME//\`/\\\\\\\`}

	rst3="$rst3;J_NAME=$J_NAME"
	rst3="$rst3;J_LOGO1=`echo $rst2 | jq ".logo100x100"`"
	rst3="$rst3;J_LOGO2=`echo $rst2 | jq ".logo175x175"`"
	rst3="$rst3;J_LOGO3=`echo $rst2 | jq ".logo300x300"`"
	rst3="$rst3;J_URL=\"$rst\""
	echo $rst3 >> "AAA$i"


	echo -e "[$absctr] $i - $j - $rst"
	if [ -z "$rst" ];then
	    echo "$EMPTYLINK" >> A$i
	    
	    # debug this problem
	    echo "`date` $EMPTYLINK in $j" >> $LOGDEB
	    echo "$rst2" >> $LOGDEB
	    echo "" >> $LOGDEB

	    echo "$EMPTYLINK!"
	else
	    echo "\"$rst\"" >> A$i
	fi
    done
    echo "`date` INF Category in file $i processed $mctr pages scraped" | tee -a $LOG
done
if [ $catctr -eq 1 ] ; then
    # in case we use the onebyone mode this will be 1 - so we can exit the function with a value for the calling function
    # to control further processing
    echo "`date` INF Onebyonemode detected!" | tee -a $LOG
    return $proflag
else
    return 0
fi
echo "`date` INF All categories processed $absctr pages scraped" | tee -a $LOG
}


function convert_links2m3u
{
# convert links to m3u streams
for i in AAA-*.txt ; do sed "s/^/#EXTINF:-1\n/" $i | sed '1s/^/#EXTM3U\n/' > $i.m3u ; done
}

function remove_AAA
{
# remove AAA- and double extensions in streams
for i in *.m3u ; do mv "$i" "`echo $i | sed -e 's/AAA-//' -e 's/.txt//'`" ; done
}


function gitti-all
{
# move stream to git folder
#mv *.m3u c:/git/m3u-radio-music-playlists/radio.net/


# there was a problem to run this from rc.local
# so force the HOME explicitly
HOME="/root"
export HOME

# add, commit and push

git -C $GITPATH config -l
git -C $GITPATH add .
git -C $GITPATH commit -m "Autoupdate: `date +'%d/%b/%Y - %H:%M %p'`"
git -C $GITPATH push origin master
}


# Generating templates and m3u files
function WriteOutResult
{
echo "`date` INF Generating templates and m3u files." | tee -a $LOG
let absctr=0
for i in $(cat genres.txt)
do
	mkdir $OUTDIR 2> $NULL
	mkdir $OUTDIR/$i 2> $NULL
	mkdir $M3UDIR 2> $NULL
	rm -f $OUTDIR/$i/*.tmpl

	m3ufile="$M3UDIR/$i.m3u"
	echo "#EXTM3U" > $m3ufile

	fname="AA-$i.txt"
	ufname="AAA-$i.txt" #file containig the links
	extfname="AAAAA-$i.txt" #file containig bash vars related to that station

	if [ ! -f $fname ] ; then
	    echo "`date` WAR $fname not found." | tee -a  $LOG
	    continue
	fi

	if [ ! -f $ufname ] ; then
	    echo "`date` WAR $ufname not found." | tee -a  $LOG
	    continue
	fi

	let lfn=0
	let lufn=0

	lfn=`wc -l $fname | cut -f 1 -d " "`
	lufn=`wc -l $ufname | cut -f 1 -d " "`

	if [ ! $lfn -eq $lufn ] ; then
	    echo "`date` ERR $fname $ufname linecounter not equal!" | tee -a  $LOG
	    continue
	fi

	if [ -f $fname ] ; then
	    let ctr=0
	    let wctr=0
	    while read line
	    do
		let ctr=$ctr+1
		foutname=`basename $line`
		fouturl=`sed -n "${ctr}p" $ufname`

		#this should set the vars defined in AAAAA-files
		J_NAME=""
		eval `sed -n "${ctr}p" $extfname`
		fnamealready=`find -L $OUTDIR -name "$foutname.tmpl"`

#		echo "fnamealready:$fnamealready" >> $LOGDEB
#		echo "J_ID:$J_ID" >> $LOGDEB
#		echo "J_NAME:$J_NAME" >> $LOGDEB
#		echo "find $OUTDIR -name \"$foutname.tmpl\"" >> $LOGDEB
#		echo "" >> $LOGDEB

		# no output if link is marked as empty
		if [ " $fouturl" == " $EMPTYLINK" ] ;then
		    echo "`date` WAR $i/$foutname EMPTY LINK - SKIP" | tee -a  $LOG
		    continue
		fi

		# no tmpl output if this file exist alread in another category
		if [ ! -z "$fnamealready" ] ;then
		    # no templatefile - we want only one file per station!!
		    # echo "`date` WAR $i/$foutname already exists ($fnamealready)" | tee -a  $LOG
		    # add to m3u file anyway
		    if [ -z "$J_NAME" ];then
			echo "#EXTINF:0,$foutname" >> $m3ufile
		    else
			echo "#EXTINF:0,$J_NAME" >> $m3ufile
		    fi
		    echo "${fouturl//\"/}" >> $m3ufile
		    continue
		else
		    # create template file
		    echo "URL=$fouturl" > "$OUTDIR/$i/$foutname.tmpl"
		    if [ -z "$J_NAME" ];then
			echo "STATIONNAME=\"$foutname\"" >> "$OUTDIR/$i/$foutname.tmpl"
		    else
			echo "STATIONNAME=\"$J_NAME\"" >> "$OUTDIR/$i/$foutname.tmpl"
		    fi


		    # add to m3u file
		    if [ -z "$J_NAME" ];then
			echo "#EXTINF:0,$foutname" >> $m3ufile
		    else
			echo "#EXTINF:0,$J_NAME" >> $m3ufile
		    fi
		    echo "${fouturl//\"/}" >> $m3ufile
		    let wctr=$wctr+1
		    let	absctr=$absctr+1
		fi
	    done < $fname
	else
	    echo "`date` ERR $fname not available"  | tee -a $LOG
	    continue
	fi
	echo "`date` INF $wctr files written out in category $i" | tee -a $LOG
	if [ $wctr -eq 0 ];then
	    echo "`date` INF deleting empty directory." | tee -a $LOG
	    rmdir $OUTDIR/$i 2> $NULL
	fi
done
echo "`date` INF $absctr template-files created." | tee -a $LOG
}


# instead of grabbing the entire website we do it category by category
# 
function onebyone
{
let curctr=1
while true
do
    if [ -f $CUR_GENRES_POS_FNAME ];then
	#echo "`date` INF Read ctr from $CUR_GENRES_POS_FNAME" |tee -a $LOG
	curctr=`cat  $CUR_GENRES_POS_FNAME`
    else
	let curctr=1
    fi

#    echo "curctr:$curctr"

    curln=`sed -n "${curctr}p" genres-full.txt`
    if [ -z $curln ];then
	#we are at the end restart from first line
	echo "`date` INF end of genres reached restart at first line" |tee -a $LOG
	let curctr=1
	curln=`sed -n "${curctr}p" genres-full.txt`
	echo $curctr > $CUR_GENRES_POS_FNAME
	rm -f $NULL
	echo "`date` INF Git push" | tee -a $LOG
	gitti-all &>>$LOG
	echo "`date` INF Uploading HTML files now!" |tee -a $LOG
	$UPLOADER_HTML | tee -a $LOG
	echo "`date` INF finished all categories - exit!" |tee -a $LOG
	exit 0
    fi

    echo "" >>$LOG
    echo "`date` INF Checking category ${curln}(${curctr}). " | tee -a $LOG
    echo $curln > ./genres.txt.1
    do_one_category
    let curctr=$curctr+1
    echo $curctr > $CUR_GENRES_POS_FNAME

    if [ -f $0.sem ] ; then
	rm -f $0.sem
	rm -f $NULL
	echo "`date` INF Found semaphore - exit now!" |tee -a $LOG
	exit 0
    fi

    if [ -f $0.restart ] ; then
	rm -f $0.restart
	rm -f $NULL
	echo "`date` INF Found restart semaphore - restarting now!" |tee -a $LOG
	$0 &
	exit 0
    fi


done
}


function do_one_category
{
# deletes all old files in workdir
clean_up

scrape_the_links_fake
#scrape_the_links
#echo "`date` INF Processing genres done!" | tee -a $LOG

get_the_links_for_the_webpages

remove_duplicates
echo "`date` INF Remove duplicates done!" | tee -a $LOG

scrape_the_links2m3u
if [ ! $? -eq 0 ] ; then
    echo "`date` INF (FETCHED: $CURLCTR) No change in $i" | tee -a $LOG
    sleep $SLEEPTIME
    return 1
else
    sleep 1
fi
echo "`date` INF (FETCHED: $CURLCTR) Scrap the links2m3u done!" | tee -a $LOG

# from here on offline processing
WriteOutResult
echo "`date` INF WriteOutResult done!" | tee -a $LOG

create_html
echo "`date` INF Create html done!" | tee -a $LOG

$UPLOADER_M3U | tee -a $LOG
}


function do_all_categories
{
# deletes all old files in workdir
# clean_up

scrape_the_links
echo "`date` INF (FETCHED: $CURLCTR) Processing genres done!" | tee -a $LOG

get_the_links_for_the_webpages

remove_duplicates
echo "`date` INF Remove duplicates done!" | tee -a $LOG

scrape_the_links2m3u
echo "`date` INF (FETCHED: $CURLCTR) Scrap the links2m3u done!" | tee -a $LOG

# from here on offline processing
WriteOutResult
echo "`date` INF WriteOutResult done!" | tee -a $LOG

create_html
echo "`date` INF Create html done!" | tee -a $LOG
}


function create_html
{
mkdir $OUTDIR4HTML 2> $NULL
TMPLFNAME=${0//.sh/.tmpl}
let hctr=0
let stopline=-1

echo "`date` INF Creating HTML." | tee -a $LOG

if [ ! -f $TMPLFNAME ];then
    echo "`date` ERR no file $TMPLFNAME" | tee -a $LOG
    return 1
fi
#echo "`date` INF Using template $TMPLFNAME" | tee -a $LOG

for i in AAAAA-*.txt 
do 

    if [ ! -f $i ] ; then
	echo "`date` ERR no file $i" | tee -a $LOG
	continue
    fi

    echo "`date` INF Processing $i " | tee -a $LOG
    while read line
    do 
	eval $line
	if [ ! $? -eq 0 ];then
	    echo "`date` ERR in $line" | tee -a $LOG
	fi

#	echo "$J_ID"
#	echo "$J_NAME"
#	echo "$J_LOGO1"
#	echo "$J_LOGO2"
#	echo "$J_LOGO3"

	cp "$TMPLFNAME" "$OUTDIR4HTML/$J_ID.html"

#	if [ $hctr -gt $stopline ];then
#	    exit
#	fi

	#<!--TITLE-->
	#<!--IMAGESCR-->
	#<!--NAME_OF_STATION-->
	#<!--URL_TO_STREAM-->

	# clean up the strings
	#echo "$J_NAME"
	J_NAME=${J_NAME//\//\\/}
	#echo "$J_NAME"

	#echo "$J_URL"
	J_URL=${J_URL//\//\\/}
	#echo "$J_URL"
	

	sed -i -e "s/<!--TITLE-->/$J_ID/g" "$OUTDIR4HTML/$J_ID.html"
	sed -i -e "s/<!--NAME_OF_STATION-->/$J_NAME/g" "$OUTDIR4HTML/$J_ID.html"
	sed -i -e "s/<!--URL_TO_STREAM-->/$J_URL/g" "$OUTDIR4HTML/$J_ID.html"

	if [ $hctr -eq $stopline ];then
	    echo $hctr
	    echo "$J_ID"
	    echo "$J_NAME"
	    echo "$J_LOGO1"
	fi


	if [ ! -z "$J_LOGO3" ];then
	    sed -i -e "s/<!--IMAGESCR-->/${J_LOGO3//\//\\/}/g" "$OUTDIR4HTML/$J_ID.html"
	else
	    if [ ! -z "$J_LOGO2" ];then
		sed -i -e "s/<!--IMAGESCR-->/${J_LOGO2//\//\\/}/g" "$OUTDIR4HTML/$J_ID.html"
#	    else
		if [ ! -z "$J_LOGO1" ];then
		    sed -i -e "s/<!--IMAGESCR-->/${J_LOGO1//\//\\/}/g" "$OUTDIR4HTML/$J_ID.html"
		fi
	    fi
	fi
	let hctr=$hctr+1
    done < $i
done
sleep 5
echo "`date` INF $hctr html files written." | tee -a $LOG
}

function preplog
{
mv $LOG.6 $LOG.7 2>$NULL
mv $LOG.5 $LOG.6 2>$NULL
mv $LOG.4 $LOG.5 2>$NULL
mv $LOG.3 $LOG.4 2>$NULL
mv $LOG.2 $LOG.3 2>$NULL
mv $LOG.1 $LOG.2 2>$NULL
mv $LOG $LOG.1 2>$NULL

mv $LOGDEB.2 $LOGDEB.3 2>$NULL
mv $LOGDEB.1 $LOGDEB.2 2>$NULL
mv $LOGDEB $LOGDEB.1 2>$NULL

echo -n "" > $LOG
}


function one-category-main
{
preplog
$OLD_REMOVER
scrape_the_links4onebyone
onebyone
}


# broken at the moment
function all-categories-main
{
preplog
do_all_categories
}


# just do a git push
function gitti-all-main
{
gitti-all
}


##############################################################
#			MAIN
##############################################################


echo "`date` INF startup $0" | tee -a $LOG

todo=`basename $0`
eval ${todo//.sh/-main}

echo "`date` INF exit $0" | tee -a $LOG
echo "" >> $LOG
rm -f $NULL

