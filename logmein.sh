#!/bin/bash
# Devices: Ricoh/HP printers, APC
# Script attempts to authenticate to the device IP using the defaul credentials
# provide list of ips (one per line) as an arg along with the vendor Example:
# ./logmein.sh -f ricoh_ips.txt -v ricoh

usage () {
    cat <<END

Connects to each IP listed in a text file (one per line) and attempts to authenticate with the default password for that vendor.
logmein.sh -f [file] -v [vendor]

Options:
    -f: file to parse
    -v: vendor (hp, ricoh, apc)
    -h: display this help screen

|Example|
./logmein.sh -f ricohs.txt -v ricoh    
END
}

error () {
    echo "Error: $1"
    usage
    exit $2
} >&2

while getopts ":f:v:h" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        f)
            file=$OPTARG
            len=`wc -l $file`
            count=0
            ;;
        v)
            vendor=$OPTARG
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

case $vendor in
    *ricoh*)
        while read ip; do
            count=$((count+1))
            echo "Sending request to $ip: $count/$len"
            OUTPUT=`wget --quiet --tries=1 --timeout 3 --post-data "userid=YWRtaW4%3D&password_work=&password=" http://$ip/web/guest/en/websys/webArch/login.cgi --no-check-certificate -O-`
            if [[ $OUTPUT !=  *'Authentication has failed.'* ]]; then
                echo $ip >> default-passwords-ricoh.txt
            else
                        echo "Auth failed on $ip" >&2
                    fi
        done<$file;;

    *hp*)
        while read ip; do
            count=$((count+1))
            echo "Sending request to $ip: $count/$len"
            OUTPUT=`wget --quiet --timeout 3 --tries=1 --post-data "agentIdSelect=hp_EmbeddedPin_v1&PinDropDown=AdminItem&PasswordTextBox=&signInOk=Sign+In" https://$ip/hp/device/SignIn/Index --no-check-certificate -O-`
            if [[ $OUTPUT == *'User: admin'* ]]; then
                echo "Success: $ip"
                echo $ip >> default-passwords-hp.txt
            else
                echo "Failed: $ip" >&2
            fi
        done<$file;;

    *apc*) 
        while read ip; do
            count=$((count+1))
            echo "Sending request to $ip: $count/$len"
            #Old APC devices. Untested on new GUI
            OUTPUT=`wget --quiet --tries=1 --timeout 3 --post-data "login_username=apc&login_password=apc&submit=Log+On" http://$ip/Forms/login1  --no-check-certificate -O-`
            if [[ $OUTPUT == *'logout.htm'* ]]; then
                echo "Success: $ip"
                echo $ip >> default-passwords-apc.txt
            else
                echo "Failed: $ip" >&2
            fi
        done<$file;;
esac
exit 0
