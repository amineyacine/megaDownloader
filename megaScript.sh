#!/bin/bash
########################################################
#                                                                                         #
#   +-----------------------------+                                                         #
#   |writed by [ Amine Heroual ]  |                                                    #
#   +-----------------------------+                                                      #
#
#
#   script for downloading a list of books 
#   we used megafitch.sh for downloading from mega.nz
#   if you want to modified do from 
#   python script free2.py inside the original script 
#   modified url parameter to your url
#   and changing the scraping parameter for 
#   your choise ok bro
#   Copyright 2018 Azure Zanculmarktum 
#   for the original mega downloader or megafetch.sh
#   
#    
#    
#             All rights reserved.
########################################################

echo "start script...."
echo "----------------"
cat << EOF > free2.py
#!/usr/bin/env python

import requests
import re
import urllib.request
import time
from bs4 import BeautifulSoup as bs4


#url = 'https://hackingresources.com/hacking-security-ebooks/?fbclid=IwAR1qvdO8QAWJV9wAykf8jyA4ZPHO0sJLTLKqrhsuYEamuzHlLpQIaPVLdVM'
url = 'https://hackingresources.com/hacking-security-ebooks/?fbclid=IwAR11U-MstgBKzdRRpP-OKOg2GfDPgv1Emgd5Q8L5QzizjgzqaZO9G-NkVyw'

reponse = requests.get(url)

soup = bs4(reponse.text,"html.parser")
i = 0 
while i < 201:  
    a = soup.findAll('a')[i]
    print(a['href'])
    i +=1

EOF

chmod +x free2.py

./free2.py > text.txt


#python free.py > text.txt

cat text.txt | grep "mega.nz" > links.txt
for line in $(cat links.txt)
do
	URL="$line"

	if [[ $1 =~ ^https?:\/\/mega(\.co)?\.nz ]]; then
		URL="$1"
	fi

	if [[ ! $URL ]]; then
		echo "Usage: ${0##*/} url" >&2
		exit 1
	fi

	CURL="curl -Y 1 -y 10"

	missing=false
	for cmd in openssl; do
		if [[ ! $(command -v "$cmd" 2>&1) ]]; then
			missing=true
			echo "${0##*/}: $cmd: command not found" >&2
		fi
	done
	if $missing; then
		exit 1
	fi

	id="${URL#*!}"; id="${id%%!*}"
	key="${URL##*!}"
	raw_hex=$(echo "${key}=" | tr '\-_' '+/' | tr -d ',' | base64 -d -i 2>/dev/null | od -v -An -t x1 | tr -d '\n ')
	hex=$(printf "%016x" \
		$(( 0x${raw_hex:0:16} ^ 0x${raw_hex:32:16} )) \
		$(( 0x${raw_hex:16:16} ^ 0x${raw_hex:48:16} ))
	)

	json=$($CURL -s -H 'Content-Type: application/json' -d '[{"a":"g", "g":"1", "p":"'"$id"'"}]' 'https://g.api.mega.co.nz/cs?id=&ak=') || exit 1; json="${json#"[{"}"; json="${json%"}]"}"
	file_url="${json##*'"g":'}"; file_url="${file_url%%,*}"; file_url="${file_url//'"'/}"

	json=$($CURL -s -H 'Content-Type: application/json' -d '[{"a":"g", "p":"'"$id"'"}]' 'https://g.api.mega.co.nz/cs?id=&ak=') || exit 1
	at="${json##*'"at":'}"; at="${at%%,*}"; at="${at//'"'/}"

	json=$(echo "${at}==" | tr '\-_' '+/' | tr -d ',' | openssl enc -a -A -d -aes-128-cbc -K "$hex" -iv "00000000000000000000000000000000" -nopad | tr -d '\0'); json="${json#"MEGA{"}"; json="${json%"}"}"
	file_name="${json##*'"n":'}"
	if [[ $file_name == *,* ]]; then
		file_name="${file_name%%,*}"
	fi
	file_name="${file_name//'"'/}"

	#$CURL -s "$file_url" | openssl enc -d -aes-128-ctr -K "$hex" -iv "${raw_hex:32:16}0000000000000000" > "$file_name"

	echo "$file_url"
	echo "$file_name"
	echo "$hex"
	echo "${raw_hex:32:16}0000000000000000"

	###################################################

	wget -O "$file_name" "$file_url"
	cat "$file_name" | openssl enc -d -aes-128-ctr -K "$hex" -iv "${raw_hex:32:16}0000000000000000" > book
	mv -f book "$file_name"
done

mkdir pdf 
mv *.pdf pdf/
rm free2.py
rm text.txt
rm links.txt


