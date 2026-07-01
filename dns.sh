#!/bin/bash
 
# Function to update the script
update_script() {
  curl -fsSL -o ~/scripts/dns.sh https://raw.githubusercontent.com/Clarity4/dnschecker/main/dns.sh
  chmod +x ~/scripts/dns.sh
  echo "Script patched successfully! RIP!"
}
 
# Check for the updates
if [ "$1" == "--patch" ]; then
  update_script
  exit 0
fi
 
# Help function
show_help() {
  echo "Usage: dns [options] <hostname>"
  echo "Options:"
  echo "  --patch   Update the script to the latest version."
  echo "  --help    Show this help message and exit."
  echo "  --sub     Check records for subdomain"
  echo ""
}
 
# Check help
if [ "$1" == "--help" ]; then
  show_help
  exit 0
fi
 
# Sub flag + argument validation
if [ "$1" == "--sub" ]; then
  sub=1
  if [ $# -ne 2 ]; then
    echo "Usage: $0 --sub <hostname>"
    exit 1
  fi
  hostname="$2"
else
  if [ $# -ne 1 ]; then
    echo "Usage: $0 <hostname>"
    exit 1
  fi
  hostname="$1"
fi
 
WHOIS_TIMEOUT=5
 
whois_safe() {
  result=$(timeout "$WHOIS_TIMEOUT" whois "$1" 2>/dev/null)
  if [ $? -eq 124 ]; then
    echo -e "\e[1;33mwhois timed out for $1\e[0m" >&2
    echo ""
  else
    echo "$result"
  fi
}
 
# Start
 
echo -e "\e[1;31mA Record:\e[0m"
a_record=$(dig +short +trace A "$hostname" | grep -vEi "CNAME|UDP|ROOT|NS|^;;" | awk 'NF{print $2}')
echo "${a_record:-None}"
 
echo
 
echo -e "\e[1;31mPTR Record:\e[0m"
for ip in $a_record; do
  if [[ $ip == *CNAME* ]]; then
    continue
  fi
  ptr_record=$(dig +short -x "$ip")
  echo "${ptr_record:-None}"
done
 
echo
 
echo -e "\e[1;31mCNAME Records:\e[0m"
cname_records=$(dig +short CNAME "$hostname")
echo "${cname_records:-None}"
 
echo
 
if [[ "$hostname" == www.* ]]; then
  echo -e "\e[1;31mWWW subdomain already in input - Ignored\e[0m"
else
  echo -e "\e[1;31mWWW Records:\e[0m"
  www_records=$(dig +short "www.$hostname")
  echo "${www_records:-None}"
fi
 
if [[ -z $sub ]]; then
  echo -e "\n\e[1;31mNS Records:\e[0m"
  ns_records=$(dig +short NS "$hostname")
  echo "${ns_records:-None}"
fi
 
# Check NS records against their IP addresses
for ns in $ns_records; do
  ns=$(echo "$ns" | sed 's/\.$//')
 
  if [ "$ns" == "ns1.$hostname" ] || [ "$ns" == "ns2.$hostname" ]; then
    echo -e "\n\e[1;31mChecking NS $ns\e[0m"
    ns_ip=$(whois_safe "$ns" | grep IP | awk '{print $NF}')
    if [ -n "$ns_ip" ]; then
      echo -e "\e[1;31mWhois IP Address:\e[0m $ns_ip"
      echo -e "\e[1;31mA record for $ns on @$ns_ip:\e[0m"
      a_record_check=$(dig +short "$ns" "@$ns_ip")
      echo "${a_record_check:-None}"
    else
      echo -e "\e[1;31mNo IP Address found for $ns\e[0m"
    fi
  fi
done
 
echo -e "\n\e[1;31mMX Records:\e[0m"
mx_records=$(dig +short +trace MX "$hostname" | grep -vEi "UDP|ROOT|NS|^;;" | awk 'NF{print $3}')
echo "${mx_records:-None}"
 
echo
 
echo -e "\e[1;31mMail A Record:\e[0m"
mail_record=$(dig +short +trace A "mail.$hostname" | grep -vEi "UDP|ROOT|NS|^;;" | awk 'NF{print $2}')
echo "${mail_record:-None}"
 
echo -e "\n\e[1;31mTXT Records:\e[0m"
txt_records=$(dig +short TXT "$hostname")
echo "${txt_records:-None}"
 
echo -e "\n\e[1;31mDKIM Record:\e[0m"
dkim_record=$(dig +short TXT "default._domainkey.$hostname")
echo "${dkim_record:-None}"
 
echo -e "\n\e[1;31mSOA Records:\e[0m"
soa_records=$(dig +short SOA "$hostname")
echo "${soa_records:-None}"
 
echo -e "\n\e[1;31mDomain Status:\e[0m"
status=$(whois_safe "$hostname" | grep -i "Domain Status" | sed 's/^[ \t]*//')
echo "${status:-None}"
 
echo -e "\n\e[1;31mRegistrar:\e[0m"
reg=$(whois_safe "$hostname" | grep -iE "Registrar:|Registrar url")
echo "${reg:-None}"
