#!/bin/zsh

###################
# PoliciesID_Extract.sh
# Grab policies ID an name from jamf to import into Splunk
# Martin Piron <mpiron@seek.com.au>
# 
# v1.0.1 (20/02/2023)
###################

## uncomment the next line to output debugging to stdout
#set -x

###############################################################################
## variable declarations - replace with your server credentials

username="*****"
password="*****"
url="*****"

bearerToken=""
tokenExpirationEpoch="0"

###############################################################################
## function declarations

getBearerToken() {
	response=$(curl -s -u "$username":"$password" "$url"/api/v1/auth/token -X POST)
	bearerToken=$(echo "$response" | plutil -extract token raw -)
	tokenExpiration=$(echo "$response" | plutil -extract expires raw - | awk -F . '{print $1}')
	tokenExpirationEpoch=$(date -j -f "%Y-%m-%dT%T" "$tokenExpiration" +"%s")
}

checkTokenExpiration() {
	nowEpochUTC=$(date -j -f "%Y-%m-%dT%T" "$(date -u +"%Y-%m-%dT%T")" +"%s")
	if [[ tokenExpirationEpoch -gt nowEpochUTC ]]
	then
		echo "Token valid until the following epoch time: " "$tokenExpirationEpoch"
	else
		echo "No valid token available, getting new token"
		getBearerToken
	fi
}

invalidateToken() {
	responseCode=$(curl -w "%{http_code}" -H "Authorization: Bearer ${bearerToken}" $url/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
	if [[ ${responseCode} == 204 ]]
	then
		echo "Token successfully invalidated"
		bearerToken=""
		tokenExpirationEpoch="0"
	elif [[ ${responseCode} == 401 ]]
	then
		echo "Token already invalid"
	else
		echo "An unknown error occurred invalidating the token"
	fi
}

###############################################################################
## start the script here

# Check token
checkTokenExpiration
curl -s -H "Authorization: Bearer ${bearerToken}" $url/api/v1/jamf-pro-version -X GET
checkTokenExpiration

# Create stylesheet
tee /tmp/stylesheet.xslt << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:template match="/"> 
<xsl:for-each select="policies/policy"> 
<xsl:value-of select="id"/> 
<xsl:text>,</xsl:text> 
<xsl:value-of select="name"/> 
<xsl:text>&#xa;</xsl:text> 
</xsl:for-each> 
</xsl:template> 
</xsl:stylesheet>
EOF

# Creating file and adding fieldnames
echo "ID,Name" > ~/Desktop/PoliciesExtract.csv

# Populating CSV
curl -X GET -H  "accept: application/xml" -H"Authorization: Bearer ${bearerToken}" "${url}/JSSResource/policies" | xsltproc /tmp/stylesheet.xslt - >> ~/Desktop/PoliciesExtract.csv

# Invalidate token
invalidateToken
curl -s -H "Authorization: Bearer ${bearerToken}" $url/api/v1/jamf-pro-version -X GET
