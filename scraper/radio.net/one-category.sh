#!/bin/bash
# k.deiss@it-userdesk.de
# radio.net scraper

# Basic version and idea by jungler
# https://github.com/junguler/m3u-radio-music-playlists/blob/main/stuff/scrape-radio.net-manual.sh

# This version tries to reduce traffic load to radio.net to a minimum

# V.01.04.04.23 redesign
# V.03.09.04.23 scrape_the_links2m3u - try to find unplausible linecounting
# V.04.16.04.23 html output including url
# V.05.18.04.23 html bugfixing / adding rm-old / upload
# V.06.21.04.23 cachemode
# V.07.24.04.23 onebyone run in endless loop
# V.08.26.04.23 bugfix


BASENAME="radio-net-scraper"

#BASEPATH=`pwd`
BASEPATH="/opt/lissi/scraper/radio.net"
#BASEPATH="/opt/temp"
GITPATH="/opt/lissi/"

BNVARIANT="$BASENAME"

LOG="$BASEPATH/${BNVARIANT}.log"
LOGDEB="$BASEPATH/DEB_${BNVARIANT}.log"
TMPF="/tmp/${BNVARIANT}.tmp"
TMPF1="/tmp/${BNVARIANT}1.tmp"
TMPF2="/tmp/${BNVARIANT}2.tmp"
NULL=./null
OUTDIR="$BASEPATH/RadioLib"
OUTDIR4HTML="$BASEPATH/html"
M3UDIR="$BASEPATH/m3u"
OLDDATA="$BASEPATH/olddata"

HTMLQ="/root/.cargo/bin/htmlq"
EMPTYLINK="NO_RESULT"
CREATE_LASTSEEN=""

CUR_GENRES_POS_FNAME="./`basename $0`.pos"
let CURLCTR=0
let CURLSIZE=0

# external scripts
OLD_REMOVER="$BASEPATH/rm-old.sh"
UPLOADER_HTML="$BASEPATH/upload-html.sh"
UPLOADER_M3U="$BASEPATH/upload-m3u.sh"
STATISTICA="$BASEPATH/statistica.sh"

# edit if necessary
let SLEEPTIME=20
let DIFF_PLAUSI=300
let CACHEMODE=1

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
#rm -f A-*.txt
#rm -f AA-*.txt
#rm -f AAA-*.txt
#rm -f AAAA-*.txt
#rm -f AAAAA-*.txt

mkdir $OLDDATA 2>$NULL
#instead of deleting move it to olddata folder
mv A-*.txt $OLDDATA 2>$NULL
mv AA-*.txt $OLDDATA 2>$NULL
mv AAA-*.txt $OLDDATA 2>$NULL
mv AAAA-*.txt $OLDDATA 2>$NULL
mv AAAAA-*.txt $OLDDATA 2>$NULL

rm -f $NULL 2>$NULL
rm -f *.txt.tmp 2>$NULL
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
#for i in "" {2..500}
for i in "" {2..500}
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
let cachectr=0

mkdir "$OLDDATA/html" 2> $NULL

for i in AA-*.txt 
do 
    let catctr=$catctr+1
    let proflag=0
    # check whether there is a difference to the last seen version
    if [ -f ${i//.txt/.lastseen} ];then
	echo "`date` INF check diff in $i" >> $LOGDEB
	diff ${i//.txt/.lastseen} $i >> $LOGDEB
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
	    
	    if [ $actual -eq 0 ];then
		echo "`date` WAR 0 entries in $i. Skip processing." | tee -a $LOG
		let proflag=1
		continue 
	    fi

	    if [ $diffc -gt $DIFF_PLAUSI ];then
		echo "`date` WAR unplausibe difference between ${i//.txt/.lastseen}($lseen) and ${i}($actual). Skip processing." | tee -a $LOG
		let proflag=1
		continue 
	    fi
	fi
    fi

    #cp $i ${i//.txt/.lastseen}
    CREATE_LASTSEEN="cp $i ${i//.txt/.lastseen}"

    rm -f A$i
    rm -f AA$i
    rm -f AAA$i

    let mctr=0
    let cachectr=0
    let statctr=0

    # j is one line like https://www.radio.net/s/1fmamsterdamtrance (= one radio station)
    for j in $(cat $i)
    do
	let mctr=$mctr+1
	let absctr=$absctr+1
	let statctr=$statctr+1

	if [ $statctr -gt 500 ] ; then
	    let statctr=0
	    echo "`date` INF $mctr pages scraped ($cachectr from cache)." | tee -a $LOG
	fi

	# isolate the json data (rst2)
	if [ $CACHEMODE -eq 0 ];then
	    rst4=`curl -s $j | grep "id=\"__NEXT_DATA__\""| awk -F '}},' '{print $1}'`
	else
	    stationid=`basename $j`
	    #echo "stationid $stationid / find $OLDDATA/html -newermt '-2880 minutes' -name $stationid.html 2>$NULL"
	    html_already_exist=`find $OLDDATA/html -newermt '-5 days' -name $stationid.html 2>$NULL`
	    if [ ! -z "$html_already_exist" ];then
		echo "SKIP FILE $OLDDATA/html/$stationid.html - using cache" 
		let cachectr=$cachectr+1
	    else
		# we fetch only if file in cache is older than x 2 days)
		echo "FETCHING DATA AND SAVE TO $OLDDATA/html/$stationid.html"
		curl -s $j > "$OLDDATA/html/html_temp.html"
		let CURLCTR=$CURLCTR+1
		fsize=`stat --printf="%s" "$OLDDATA/html/html_temp.html"`
		let CURLSIZE=$CURLSIZE+$fsize

		if [ $fsize -lt 10000 ] ;then
		    # we expect a file greater than this - everything else something went wrong
		    # cloudflare sometimes needs a small break! So give it second chance
		    sleep 15
		    curl -s $j > "$OLDDATA/html/html_temp.html"
		    let CURLCTR=$CURLCTR+1
		    fsize=`stat --printf="%s" "$OLDDATA/html/html_temp.html"`
		    let CURLSIZE=$CURLSIZE+$fsize
		fi

		if [ $fsize -gt 10000 ] ;then
		    # we expect a file greater than this - everything else something went wrong
		    mv "$OLDDATA/html/html_temp.html" "$OLDDATA/html/$stationid.html"
		else    
		    echo "`date` WAR curl failed for $stationid" | tee -a $LOG
		    if [ ! -f "$OLDDATA/html/$stationid.html" ];then
			# we have to break curl failed and also no old cached file
			mv "$OLDDATA/html/html_temp.html" "$OLDDATA/html/$stationid.html"
			echo "$EMPTYLINK" >> A$i
			continue
		    else
		        fsize=`stat --printf="%s" "$OLDDATA/html/$stationid.html"`
			if [ $fsize -gt 10000 ] ;then
			    echo "`date` WAR Using cached file for $stationid even is elder than defined" | tee -a $LOG
			    let cachectr=$cachectr+1
			else
			    echo "`date` WAR no valid cache file for $stationid" | tee -a $LOG
			    echo "$EMPTYLINK" >> A$i
			    continue
			fi
		    fi
		fi
	    fi
	    rst4=`cat "$OLDDATA/html/$stationid.html" | grep "id=\"__NEXT_DATA__\""| awk -F '}},' '{print $1}'`
	fi

	# find useable json data inside html (= rst2)
	rst2=${rst4#*\{\"id\":}
	rst2="{\"id\":${rst2}}}" 
	# save json data to file
	echo "$rst2" >> "AA$i"

	# retrieve url (= rst)
	rst=`echo $rst2 | jq '.streams' | jq '.[].url'`
	# hack if there is more than one url
	rst=`echo $rst|cut -f 1 -d " "`
	# hack if link not properly quoted
	rst=${rst//\"/}

	# build the data (bash readable) for the AAA$i file (= rst3)
	J_ID=`echo $rst2 | jq ".id"`
	if [ ! " $J_ID" == " \"$stationid\"" ];then
	    echo "`date` WAR Inconsistent data in $J_ID ==  $stationid" | tee -a $LOG
	fi

	rst3="J_ID=$J_ID"

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
    echo "`date` INF Category in file $i processed $mctr pages scraped ($cachectr from cache)." | tee -a $LOG

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
git -C $GITPATH pull
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
	    let statctr=0
	    while read line
	    do
		let ctr=$ctr+1
		let statctr=$statctr+1
		if [ $statctr -gt 500 ] ; then
		    let statctr=0
		    echo "`date` INF $ctr entries processed." | tee -a $LOG
		fi

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

	echo "`date` INF Uploading HTML files now." |tee -a $LOG
	$UPLOADER_HTML &

	#to do - split m3u if to big

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

	echo "`date` INF finished HTML upload - creating statistics." |tee -a $LOG
	$STATISTICA | tee -a $LOG
	break
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

    if [ -f $0.cfg ] ; then
	source $0.cfg
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
    CREATE_LASTSEEN=""
    return 1
else
    sleep 3
fi
((cs=$CURLSIZE/1024/1024))
#echo "`date` INF (FETCHED: $CURLCTR / SIZE: $CURLSIZE) Scrap the links2m3u for $i done!" | tee -a $LOG
echo "`date` INF (FETCHED: $CURLCTR / SIZE: $cs MB) Scrap the links2m3u for $i done." | tee -a $LOG

# from here on offline processing
WriteOutResult
echo "`date` INF WriteOutResult done." | tee -a $LOG

create_html
echo "`date` INF Create html done." | tee -a $LOG

$UPLOADER_M3U | tee -a $LOG

if [ ! -z "$CREATE_LASTSEEN" ] ; then
    echo "`date` INF Create .lastseen file: $CREATE_LASTSEEN" | tee -a $LOG
    eval $CREATE_LASTSEEN
fi
CREATE_LASTSEEN=""
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

echo "`date` INF startup $0" | tee -a $LOG
}


function one-category-main
{
preplog
$OLD_REMOVER
scrape_the_links4onebyone
onebyone
echo "`date` INF exit $0 - will restart a new instance." | tee -a $LOG
echo "" >> $LOG
sleep 60
$0 &
exit 0
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
exit 0
}


# just look that we can run script without syntax error
function check_syntax-main
{

echo "BASEPATH $BASEPATH"
echo "GITPATH $GITPATH"
echo "BNVARIANT $BNVARIANT"

echo "LOG $LOG"
echo "LOGDEB $LOGDEB"
echo "OUTDIR $OUTDIR"
echo "OUTDIR4HTML $OUTDIR4HTML"
echo "M3UDIR $M3UDIR"
echo "OLDDATA $OLDDATA"

echo "HTMLQ $HTMLQ"
echo "EMPTYLINK $EMPTYLINK"

CUR_GENRES_POS_FNAME="one-category.sh.pos"
echo "CUR_GENRES_POS_FNAME $CUR_GENRES_POS_FNAME `cat $CUR_GENRES_POS_FNAME`" 

echo "OLD_REMOVER $OLD_REMOVER"
echo "UPLOADER_HTML $UPLOADER_HTML"
echo "UPLOADER_M3U $UPLOADER_M3U"


echo "SLEEPTIME $SLEEPTIME"
echo "DIFF_PLAUSI $DIFF_PLAUSI"
echo "CACHEMODE $CACHEMODE"
exit 0
}


# do some stats
function statistica-main
{

#echo "m3u stat"
let linectr=0
rm -f $TMPF
for line in `ls $M3UDIR`
do
    t=`wc -l $M3UDIR/$line|cut -f 1 -d " "`
    ((t = $t-1))
    ((t = $t/2))
    echo "$t $line" >>$TMPF
    let linectr=$linectr+$t
done

cat $TMPF |sort -rn
echo ""
echo "$linectr entries in  $M3UDIR"

t=`ls "$OLDDATA/html" |wc -l`
echo ""
echo "$t cached entries in $OLDDATA/html"
echo "Size of cache in $OLDDATA/html is `du -h $OLDDATA/html | cut -f 1`"
echo ""
echo "`ls $OUTDIR|wc -l` categories found in $OUTDIR"
echo "`find -L $OUTDIR -name \"*.tmpl\" |wc -l` template items in $OUTDIR"

echo ""
echo "`ls $OUTDIR4HTML |wc -l` HTML output files in $OUTDIR4HTML"
echo "Size of generated HTML in $OUTDIR4HTML is `du -h $OUTDIR4HTML | cut -f 1`"

exit 0
}



##############################################################
#			MAIN
##############################################################




todo=`basename $0`
eval ${todo//.sh/-main}

echo "`date` INF exit $0" | tee -a $LOG
echo "" >> $LOG
rm -f $NULL

