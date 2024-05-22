#!/bin/bash

# get initial token
TOKEN_RESPONSE=$(curl -s -k -X POST https://localhost:8443/realms/master/protocol/openid-connect/token \
	-H "Content-Type: application/x-www-form-urlencoded" \
	-d "grant_type=client_credentials" \
	-d "client_id=exchanger" \
	-d "client_secret=5dYBQSAT57SX6BKHHeRI0Cjzn07ZeMF7"
	-d "username=success" \
	-d "password=success" \
	-d "scope=openid" -v)

# echo $TOKEN_RESPONSE | jq -r
ACCESS_TOKEN=$(echo $TOKEN_RESPONSE | jq -r '.access_token')
echo $ACCESS_TOKEN 
echo  $ACCESS_TOKEN | cut -d "." -f 2 | base64 --decode | jq

R2=$(curl -s -k -X POST https://localhost:8443/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
  -d "client_id=exchanger" \
  -d "client_secret=5dYBQSAT57SX6BKHHeRI0Cjzn07ZeMF7" \
  -d "audience=provider.business.com" \
  -d "targetUser=success" \
  -d "subject_token=$ACCESS_TOKEN" \
  -d "subject_issuer=https://localhost:8443/realms/master")

echo $R2 | jq 
  
exit

