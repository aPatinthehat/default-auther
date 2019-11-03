#!/bin/bash
# Devices: Ricoh/HP printers, APC
# Script attempts to authenticate to the device IP using the defaul device credentials
# provide list of ips (one per line) as an arg. Example:
# ./logmein.sh ricoh_ips.txt

file=$1
len=`wc -l $1`
count=0

if [[ $1 == *"ricoh"* ]]; then
    while read ip; do
        count=$((count+1))
        echo "Sending request to $ip: $count/$len"
        OUTPUT=`wget --quiet --tries=1 --timeout 3 --post-data "userid=YWRtaW4%3D&password_work=&password=" http://$ip/web/guest/en/websys/webArch/login.cgi --no-check-certificate -O-`
        if [[ $OUTPUT !=  *'Authentication has failed.'* ]]; then
            echo $ip >> default-passwords-ricoh.txt
        else
            echo "Auth failed on $ip"
        fi
    done<$1
elif [[ $1 == *"hp"* ]]; then
    while read ip; do
        count=$((count+1))
        echo "Sending request to $ip: $count/$len"
        OUTPUT=`wget --quiet --timeout 3 --tries=1 --post-data "agentIdSelect=hp_EmbeddedPin_v1&PinDropDown=AdminItem&PasswordTextBox=&signInOk=Sign+In" https://$ip/hp/device/SignIn/Index --no-check-certificate -O-`
        if [[ $OUTPUT == *'User: admin'* ]]; then
            echo "Success: $ip"
            echo $ip >> default-passwords-hp.txt
        else
            echo "Failed: $ip"
        fi
    done<$1
elif [[ $1 == *"apc"* ]]; then
    while read ip; do
        count=$((count+1))
        echo "Sending request to $ip: $count/$len"
        #Old APC devices. Untested on new GUI
        OUTPUT=`wget --quiet --tries=1 --timeout 3 --post-data "login_username=apc&login_password=apc&submit=Log+On" http://$ip/Forms/login1  --no-check-certificate -O-`
        if [[ $OUTPUT == *'logout.htm'* ]]; then
            echo "Success: $ip"
            echo $ip >> default-passwords-apc.txt
        else
            echo "Failed: $ip"
        fi
    done<$1
fi