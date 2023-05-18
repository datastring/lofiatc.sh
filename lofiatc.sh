#!/bin/bash

ICAO_CODES=icao.txt
BROADCASTIFY=broadcastify.txt
LOFI_YT=lofiyt.m3u
LOFI_MP3=lofimp3.m3u

function updateinfo()
# hacky but it seems to work
# todo robust error handling
{
    echo "Updating stream information..." >&2

    CHUNK_URL="https://www.lofiatc.com$(curl https://www.lofiatc.com/ 2>/dev/null | grep -o '/static/js/main.[^.]\+.chunk.js')"

    # get youtube links for lofi songs
    echo "Youtube song links" >&2
    echo -e $(curl "$CHUNK_URL" 2>/dev/null) \
        | grep -o 'youtube:"[^"]\+youtube.com/watch[^"]\+' \
        | sed -e 's/youtube:"//' \
        > $LOFI_YT
    echo "DONE" >&2

    # get mp3s as stored on lofiatc.com
    echo "mp3 URIs" >&2
    echo -e $(curl "$CHUNK_URL" 2>/dev/null) \
        | grep -o 'name:"[^"]\+",youtube' \
        | sed -e 's/name:"\([^"]\+\)",youtube/\1/' \
        | perl -MURI::Escape -wlne 'print uri_escape $_' \
        | sed -e 's/\(.*\)/https:\/\/www.lofiatc.com\/assets\/music\/\1.mp3/' \
        > $LOFI_MP3
    echo "DONE" >&2

    # get top broadcastify streams
    echo "Broadcastify top streams" >&2
    curl https://www.broadcastify.com/listen/top 2>/dev/null \
        | awk '/stid/{c=4};c&&((c-- == 4) || (c==0))' \
        > prefilter

    grep -o 'stid/[0-9]\+">[A-Z>]\+' prefilter \
        | sed -e 's/[^A-Z]\+//' \
        > stids

    sed -ne 's/.*\/listen\/feed\/\([0-9]\+">[^<]\+\).*/http:\/\/broadcastify.cdnstream1.com\/\1/p' prefilter \
        | sed -e 's/\(.*\)">\(.*\)/\2;\1/' \
        > feeds

    paste -d ";" stids feeds > $BROADCASTIFY
    rm prefilter stids feeds
    echo "DONE" >&2

    # respect liveact's toc:
    # https://www.liveatc.net/legal/
    
    # get all icao codes
    # echo "ICAO codes" >&2
    # ICAO_CODES_TEMP=$(mktemp)
    # for c in {a..z} ; do
    #     echo "$c" >&2
    #     curl 'https://www.lofiatc.com/autocomplete/'$c'?icao=KAPA:1' 2>/dev/null \
    #         | jq --raw-output '.codes[]' \
    #         >> $ICAO_CODES_TEMP
    # done

    # echo "ICAO links" >&2
    # rm -f $ICAO_CODES
    # for c in $(sort $ICAO_CODES_TEMP | uniq) ; do
    #     echo $c >&2
    #     ICAO_INFO=$(curl "https://www.lofiatc.com/airport/$c" 2>/dev/null)
    #     ICAO_CODE=$(echo $ICAO_INFO | jq --raw-output '.icao')
    #     ICAO_NAME=$(echo $ICAO_INFO | jq --raw-output '.name')
    #     ICAO_FEED=$(echo $ICAO_INFO | jq --raw-output '.feedUrl')
    #     echo "$ICAO_CODE;$ICAO_NAME;$ICAO_FEED" >> $ICAO_CODES
    # done
    # rm -f $ICAO_CODES_TEMP

    # echo "DONE" >&2
}


[[ "${1:-}" == "update" ]] && updateinfo

# play random stream
STREAM_FILE=$ICAO_CODES

# uncomment if broadcastify streams shall be used
# STREAM_FILE=$BROADCASTIFY

STREAM_ENTRY=$(sort --random-sort $STREAM_FILE | head -1)
STREAM_CODE=$(echo $STREAM_ENTRY | cut -d ";" -f1)
STREAM_NAME=$(echo $STREAM_ENTRY | cut -d ";" -f2)
STREAM_FEED=$(echo $STREAM_ENTRY | cut -d ";" -f3)
echo "Playing: $STREAM_CODE - $STREAM_NAME" >&2
echo $STREAM_FEED >&2
# mpv --no-video --loop "$STREAM_FEED" &>/dev/null &
"C:\Users\pimentma\.personal\Portable Apps\Others\mpv\mpv.exe" --no-video --loop "$STREAM_FEED" &>/dev/null &

# lofi playlist
# in case yt videos shall be used for playback:
# https://github.com/yt-dlp/yt-dlp/issues/6496#issuecomment-1463202877
# mpv --no-ytdl --no-video --shuffle --loop-playlist $LOFI_YT
"C:\Users\pimentma\.personal\Portable Apps\Others\mpv\mpv.exe" --no-ytdl --no-video --shuffle --loop-playlist $LOFI_YT

# init
function pause(){
   read -p "$*"
}

# call it
pause 'Press [Enter] key to continue...'