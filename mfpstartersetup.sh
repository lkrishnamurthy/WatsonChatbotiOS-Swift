#!/bin/sh

# register app
source mfpregisterapp.sh

#######################################################################################
# Note :
# (1) BMSCredentials.plist has populated mobilefoundationUrl, mobilefoundationPassword,
#  conversationUsername and conversationPassword
# (2) mobile foundation server (mobilefoundationUrl) is up and running
#######################################################################################

keys=$(awk -F '[<>]' '/key/{print $3}' $(pwd)/$(find . -name BMSCredentials.plist))
keyArray=(${keys// / })
values=$(awk -F '[<>]' '/string/{print $3}' $(pwd)/$(find . -name BMSCredentials.plist))
valuesArray=(${values// / })

count=0;
for i in "${keyArray[@]}"
do
    if [ "$i" == "mobilefoundationPassword" ]
    then
        mobilefoundationPassword=${valuesArray[count]}
    elif [ "$i" == "mobilefoundationUrl" ]
    then
       mobilefoundationUrl=${valuesArray[count]}
    elif [ "$i" == "conversationUsername" ]
    then
        conversationUsername=${valuesArray[count]}
    elif [ "$i" == "conversationPassword" ]
    then
        conversationPassword=${valuesArray[count]}
    fi
    count=$((count+1))
done

OPERATION="Download Adapter"
HTTP_STATUS=$( curl -s -w '%{http_code}' -X GET -u admin:$mobilefoundationPassword -o WatsonConversation.adapter "https://git.ng.bluemix.net/imfsdkt/console-samples/raw/master/WatsonConversation.adapter" )

if [ "$HTTP_STATUS" == "200" ]
then
    echo "SUCCESS: $OPERATION"
    OPERATION="Deploy Adapter"
    HTTP_STATUS=$( curl -s -o /dev/null -w '%{http_code}' -X POST -u admin:$mobilefoundationPassword -F file=@WatsonConversation.adapter "$mobilefoundationUrl/mfpadmin/management-apis/2.0/runtimes/mfp/adapters" )
else
  echo "FAILED: $OPERATION"
  echo $HTTP_STATUS
  exit 1
fi

if [ "$HTTP_STATUS" == "200" ]
then
    echo "SUCCESS: $OPERATION"
    OPERATION="Upload Adapter Configuration"
    adapterJsonPart1='{"adapter" : "WatsonConversation","properties" : {"username" :"'
    adapterJsonPart2='","password" :"'
    adapterJsonPart3='"'}}''
    adapterJson=$adapterJsonPart1$conversationUsername$adapterJsonPart2$conversationPassword$adapterJsonPart3
    HTTP_STATUS=$( curl -s -o /dev/null -w '%{http_code}' -u admin:$mobilefoundationPassword -H "Content-Type: application/json" -X PUT -d "$adapterJson" "$mobilefoundationUrl/mfpadmin/management-apis/2.0/runtimes/mfp/adapters/WatsonConversation/config" )
else
  echo "FAILED: $OPERATION"
  echo $HTTP_STATUS
  exit 1
fi

if [ "$HTTP_STATUS" == "200" ]
then
    echo "SUCCESS: $OPERATION"
else
  echo "FAILED: $OPERATION"
  echo $HTTP_STATUS
  exit 1
fi
