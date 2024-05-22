# keycloak-study

# Summary
* adding user attributes for storage providers like provider.example.com works and is reflected in JWT
* we are looking for programatic access, e.g. using it in spotlight or virtuoso docker by adding credentials. Here bash is used. 
* in general using user:pass to get the JWT is ok'ish. Looks weird to give out passwords, maybe we can cloak them as api keys: `base64(success:success) = c3VjY2VzczpzdWNjZXNz`, also it would be beter to have public/private keys and then delegate account permission to certain keys, i.e. this key is allowed to access spotlight artifacts, etc... 

## notes
Client ID can extracted from the download URL for a given databus version, I made a mock up:
```
client_id=$(curl -H "Accept: application/ld+json" "https://databus.dbpedia.org/kurzum/provider.example.com/dataset1/2018.03.11" | jq -r '.["@graph"][] | select(."@type" == "Part") | .downloadURL' | awk -F/ '{print $3}')
echo $client_id
```
## ACL rules
Keycloak allows to set user attributes that can be included in the JWT, such as this:
```
"provider.example.com": {
    "artifact": "https://databus.dbpedia.org/dice/abstracts/extended-abstracts",
    "until": "2024-10-01"
  },
```
User attributes can be enabled via: Realm settings -> unmanaged attributes  and then the client needs to be configured under client - client scopes - provider.example.com-dedicated which defines what is put into the JWT. 
**Current insight**: JWT need to be scoped to the provider like provider.example.com, which is a client in keycloak. We managed to achieve this by authenticating a user to a client and then including user attributes, i.e. ACL rules into the JWT. Other methods of actually retrieving ACL rules are currently not known. 

## User Authentication / Token acquisition
as written above, we have not discovered a way to retrieve scoped acl rules, i.e. rules that are just for one provider. Hence, we investigated alternative ways how a user can retrieve tokens. 

### Methods that require difficult config in keycloak or docker/consumer
* api keys or client_credentials
theoretically, we could set api keys in clients, each bash script would need the correct api keys for each provider, which is very difficult to manage

* .X509/mTLS
seems like all certs need to be signed by keycloak certificate authority. As far as I understood it the publ key certificate is not user specific, but client specific, so while it is true that bash/curl can retrieved a scoped JWT, it would be necessary to add each key to each client

### [working] Getting an access token with user pass:
```
TOKEN=$(curl -s -k -X POST https://localhost:8443/realms/master/protocol/openid-connect/token \
	-H "Content-Type: application/x-www-form-urlencoded" \
	-d "grant_type=password" \
	-d "client_id=provider.example.com" \
	-d "username=success" \
	-d "password=success" \
	-d "scope=openid"  | jq -r '.access_token')
echo $TOKEN |  cut -d "." -f 2 | base64 -d - | jq -r
	
# download
curl -L -o file.txt -H "Authorization: Bearer $TOKEN" https://provider.example.com/databus.dbpedia.org/kurzum/provider.example.com-dataset1/file.txt 
```
### [failure] Token Exchange
In the current version of keycloak token exchange seems to be not working see https://www.google.com/search?q=Client+not+allowed+to+exchange
I tried many different ways, I found online, i.e. started keycloak with `--features token-exchange,preview,admin-fine-grained-authz,impersonation` trying to have an extra client `exchange` for initial login, then changing to `provider.example.com`, configure audience, enable impersonation, use `grant_type=client_credentials`, created policies that allow token exchange, etc.. I added a script token-exchange.sh . According to google, it seems that many people have the same issues. Also it remains unclear how to explicitly allow token-exchange.

# Keycloak

a pre-configured keycloak is included here with clients provider.example.com and provider.business.com and user admin:admin and success:success
```
cd keycloak-study/keycloak-24.0.4/bin
./kc.sh start-dev 
``` 
* user attributes are enabled via Realm settings -> unmanaged attributes 
* conf file contains some absolute paths for server certs:
```
https-enabled=true
https-port=8443
https-certificate-file=/home/kurzum/git/keycloak-study/keycloak-24.0.4/conf/server.crt
https-certificate-key-file=/home/kurzum/git/keycloak-study/keycloak-24.0.4/conf/server.key
https-client-auth=request
https-truststore-file=/home/kurzum/git/keycloak-study/keycloak-24.0.4/conf/ca.crt
```

## quickstart getting an access token with user pass:
```
curl -s -k -X POST https://localhost:8443/realms/master/protocol/openid-connect/token \
	-H "Content-Type: application/x-www-form-urlencoded" \
	-d "grant_type=password" \
	-d "client_id=provider.example.com" \
	-d "username=success" \
	-d "password=success" \
	-d "scope=openid"  | jq -r '.access_token' |  cut -d "." -f 2 | base64 -d - | jq -r
```
