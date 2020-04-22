#!/bin/bash
# Devices: Ricoh/HP printers, APC
# Script attempts to authenticate to the device IP using the defaul credentials
# provide list of ips (one per line) as an arg along with the vendor Example:
# ./logmein.sh -f ricoh_ips.txt -v ricoh

usage () {
    cat <<END

Connects to each IP listed in a text file (one per line) and attempts to authenticate with the default password for that vendor.

Options:
    -f: file to parse or ip/hostname of the target
    -v: vendor (hp, ricoh, apc)
    -u: username (if not using the default)
    -p: specify password (if not using the default)
    -h: display this help screen

|Example|
./logmein.sh -f ips.txt -v ricoh -u admin -p fake_pw    
END
}

error () {
    echo -e "${RED}Error: $1${NC}"
    usage
    exit $2
} >&2

#COLORS
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

password=
while getopts ":f:v:hu:p:" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        f)
            file=$OPTARG
            ;;
        v)
            vendor=`echo $OPTARG | tr [:lower:] [:upper:]`
            ;;
        u)
            user=$OPTARG
            ;;            
        p)
            password=$OPTARG
            ;;           
        :)
            error "Option -${OPTARG} is missing an argument"
            exit 1
            ;;
        \?)
            error "Unknown option -${OPTARG}"
            exit 1
            ;;
    esac
done

if [[ -z $file ]]; then
    error "Specify target(s) using -f file/host"

elif [[ -z $vendor ]]; then
    error "Specify a vendor (-v vendor)"

elif [[ ! -a $file ]]; then
    echo $file > /tmp/auth.tmp
    file="/tmp/auth.tmp"
fi

#CURRENT STATUS COUNTS
len=`wc -l < $file`
count=0

case $vendor in
    *RICOH*)
        if [[ -n $password ]]; then
            password=`echo -n $password | base64`
            password="${password%%=*}%3D"
        fi
        if [[ -n $user ]]; then
            user=`echo -n $user | base64`
            user="${user%%=*}%3D"
        fi
        while read -r ip; do
            count=$((count+1))
            echo "Sending request $count/$len to $ip"
            #output=`wget --quiet --tries=1 --timeout 3 --post-data "userid=YWRtaW4%3D&password_work=&password=$password" $ip/web/guest/en/websys/webArch/login.cgi --no-check-certificate -O-`
            output=`curl -retry 1 -m 2 --connect-timeout 3 -s -k $ip/web/guest/en/websys/webArch/login.cgi -X POST -d "&userid_work=&userid=$user&password_work=&password=$password&open="`
            if [[ $output ==  *'logout.cgi'* ]] || [[ $output ==  *'302 Moved Temporarily'* ]]; then
                echo $ip >> default-passwords-ricoh.txt
                echo -e "\t${RED}Successful login: $ip${NC}"
            else
                echo -e "\tAuth failed on $ip" >&2
            fi
            echo ""
        done<"$file";;

    *HP*)
        while read -r ip; do
            count=$((count+1))
            echo "Sending request $count/$len to $ip"
            output=`wget --tries=1 --quiet --timeout 3 --post-data "agentIdSelect=hp_EmbeddedPin_v1&PinDropDown=AdminItem&PasswordTextBox=$password&signInOk=Sign+In" https://$ip/hp/device/SignIn/Index --no-check-certificate -O-`
            if [[ $output == *'User: admin'* ]]; then
                echo -e "\t${RED}Successful login: $ip${NC}"
                echo $ip >> default-passwords-hp.txt
            else
                echo -e "\tFailed: $ip" >&2
            fi
            echo ""
        done<$file;;

    *APC*)
        if [[ -z $password ]]; then
            password=apc
        fi
        if [[ -z $user ]]; then
            user=apc
        fi     
        while read -r ip; do
            count=$((count+1))
            echo "Sending request $count/$len to $ip"
            #Old APC devices. Untested on new GUI
            output=`wget --tries=1 --quiet --timeout 3 --post-data "login_username=$user&login_password=$password&submit=Log+On" $ip/Forms/login1 --no-check-certificate -O-`
            if [[ $output == *'logout.htm'* ]]; then
                echo -e "\t${RED}Successful login: $ip${NC}"
                echo $ip >> default-passwords-apc.txt
            else
                echo -e "\tFailed: $ip" >&2
            fi
        echo ""
        done<$file;;
esac
exit 0
