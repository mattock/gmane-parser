#!/bin/bash
#
# A crude but functional script that generates per-user post counts from 
# information available in Gmane archives. Fortunately Gmane provides fairly 
# easily parseable lists of postings using URLs like this:
#
# http://news.gmane.org/group/gmane.network.openvpn.user/last=0/force_load=very/?page=2&action=--Action--
# doctored up a little by krzee on 4-20-14 (it was hurting my eyes)


# Variables
BASEURL="http://news.gmane.org/group/gmane.network"
LIST=$1
LASTPAGE=$2
TEMPFILE=/tmp/temp.html
POSTSFILE=/tmp/posts.txt
AUTHORSFILE=/tmp/authors.txt
RESULTSFILE=/tmp/results.txt

# Usage
help(){
    echo "Usage: gmane-parser.sh list pages"
    echo
    echo "Example: gmane-parser.sh openvpn.user 20"
    exit 1
}

[ -z $2 ] && help

# Remove files left from previous runs
rm -f "$TEMPFILE" "$POSTSFILE" "$AUTHORSFILE" "$RESULTSFILE"

# Load and save the webpages we're interested in into a temporary file
PAGE=0
while [ $PAGE -le $LASTPAGE ]; do
    wget -q "$BASEURL.$LIST/last=0/force_load=very/?page=$PAGE&action=--Action--" -O - >> "$TEMPFILE"
    PAGE=$(( $PAGE + 1 ))
done

# Get author names and post counts
grep "class=\"unread\"" "$TEMPFILE"|cut -d ">" -f 5|cut -d "<" -f 1 > "$POSTSFILE"
sort -u "$POSTSFILE"|grep -v "^\.$"|grep -x "^.*[[:alpha:]].*$" > "$AUTHORSFILE"

# Count posts by author
while read AUTHOR; do
    POSTCOUNT=$(grep -c "^$AUTHOR$" "$POSTSFILE")

    # Add zero padding to post counts if necessary
    if   [ ${#POSTCOUNT} -eq 2 ]; then
        POSTS=0$POSTCOUNT
    elif [ ${#POSTCOUNT} -eq 1 ]; then
        POSTS=00$POSTCOUNT
    else
        POSTS=$POSTCOUNT
    fi

    echo "$POSTS: $AUTHOR" >> "$RESULTSFILE".2
done < "$AUTHORSFILE"
sort -r "$RESULTSFILE".2 > "$RESULTSFILE"
rm "$RESULTSFILE".2
