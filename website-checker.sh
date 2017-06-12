#!/bin/sh
# ---- website-checker.sh ----
# Pings a list of websites using cURL to see if they are up and
# there are no errors. If there are problems, we send an email using mailx
# to let ourselves know about the problem.
################################################################################

# Recipient of the errors email
admin_email=youremail@host.com

# This is a path to a plain text list of URLs to check, one per line
# Make sure this uses proper unix newline characters or you will get 400 Bad Request errors
# when you try to curl the URLs
url_list=url-list.txt

# Init empty variable for storing errors
failures=""

# A special string that will be present if the site is up and working
# See discussion here: http://stackoverflow.com/q/21391776/931860
# I recommend not using an HTML comment for the string because comments are
# automatically stripped by some performance optimization systems
# (e.g. CloudFlare).
validation='HTTP/1.1 401 Unauthorized'

# We need to use an up to date CA cert bundle to verify that our SSL certs are working for https:// URLs
# You can obtain this file from: http://curl.haxx.se/docs/caextract.html
cabundle=/path/to/cert.pem

# Loop through all of the URLs and cURL them
while read siteurl
do
	# curl flags
	# --location = Follow HTTP redirects
	# --include = Include the HTTP headers in the output
	# --silent = Don't show progress bar
	# --show-error = We hide the progress bar with --silent, but we still need errors, this fixes that
	# --max-time = How long to allow curl to run for each try (connection and download)
	# --cacert = See comment above
	# --user-agent = The user agent string to use
	# --write-out = Additional information for curl to write to its output
	result=$(curl -I --location --include --silent --show-error --max-time 12 --header "Cache control: no-cache" --user-agent "Mozilla/5.0 (Windows NT 6.3; WOW64; rv:26.0) Gecko/20100101 Firefox/26.0" --write-out "\nHTTP Code: %{http_code}\n" "$siteurl" 2>&1)
	
	# Search for our string, if it isn't found, the site is down
	# -q is grep's quite flag, makes it not write to standard out
	if ! echo "$result" | grep -q "$validation" ; then
		
		# Add the site url and the curl output to our failures variable
		failures="$failures"''"$siteurl"'\n'""	
		
	fi
	
done < $url_list

# Check for failures, if we have them, send the email
if ! [ -z "$failures" ]; then
	
	# mailx will convert our email body into an attachment (or just fail to send the email)
	# if the newline characters aren't handled properly. So, we pipe the output through iconv and tr.
	# See: http://stackoverflow.com/a/18917677/931860
	echo "$failures" | iconv -c -t UTF-8 | tr -d '\r' > results.txt 
fi
