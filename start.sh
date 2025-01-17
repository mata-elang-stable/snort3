#!/bin/sh

PULLEDPORK_CONF_FILE="/usr/local/etc/pulledpork/pulledpork.conf"
PULLEDPORT_TEMP_FILE="/tmp/pulledpork.conf"

# copy pulledpork.conf to temp file
cp "$PULLEDPORK_CONF_FILE" "$PULLEDPORT_TEMP_FILE"

# check if file exists in touch /usr/local/etc/rules/pulledpork.rules
if [ ! -f /usr/local/etc/snort3/rules/pulledpork.rules ]; then
    touch /usr/local/etc/snort3/rules/pulledpork.rules
fi

# check if file exists in touch /usr/local/etc/rules/local.rules
if [ ! -f /usr/local/etc/snort3/rules/local.rules ]; then
    touch /usr/local/etc/snort3/rules/local.rules
fi

# check if env variable SNORT_OINKCODE is set
if [ -z "$SNORT_OINKCODE" ]; then
    echo "SNORT_OINKCODE is not set"
    exit 1
fi

# check if env variable NETWORK_INTERFACE is set correctly
if [ -z "$NETWORK_INTERFACE" ]; then
    echo "NETWORK_INTERFACE is not set"
    exit 1
fi

# check if env variable DOWNLOAD_RULES is set
if [ -z "$DOWNLOAD_RULES" ]; then
    DOWNLOAD_RULES=false
fi

# check if env variable SNORT_COMPRESSED_RULES_FILE_PATH is set
if [ -z "$SNORT_COMPRESSED_RULES_FILE_PATH" ]; then
    SNORT_COMPRESSED_RULES_FILE_PATH=""
fi

# check if community_ruleset is set
if [ -z "$COMMUNITY_RULESET" ]; then
    COMMUNITY_RULESET=false
fi

# check if registered_ruleset is set
if [ -z "$REGISTERED_RULESET" ]; then
    REGISTERED_RULESET=false
fi

# check if LightSPD_ruleset is set
if [ -z "$LIGHTSPD_RULESET" ]; then
    LIGHTSPD_RULESET=false
fi

# check if snort_blocklist is set
if [ -z "$SNORT_BLOCKLIST" ]; then
    SNORT_BLOCKLIST=false
fi

# check if et_blocklist is set
if [ -z "$ET_BLOCKLIST" ]; then
    ET_BLOCKLIST=false
fi

# check if blocklist_urls is set
if [ -z "$BLOCKLIST_URLS" ]; then
    BLOCKLIST_URLS=""
fi

# check if env ips_policy is set
if [ -z "$IPS_POLICY" ]; then
    IPS_POLICY="balanced"
fi

# check IPS_POLICY must be one of: connectivity, balanced, security, max-detect, none
if [ "$IPS_POLICY" != "connectivity" ] && [ "$IPS_POLICY" != "balanced" ] && [ "$IPS_POLICY" != "security" ] && [ "$IPS_POLICY" != "max-detect" ] && [ "$IPS_POLICY" != "none" ]; then
    echo "IPS_POLICY must be one of: connectivity, balanced, security, max-detect, none"
    exit 1
fi

# replace ips_policy in pulledpork.conf file with the one provided
sed -i "s/ips_policy = .*/ips_policy = $IPS_POLICY/g" "$PULLEDPORT_TEMP_FILE"

# if blocklist_urls is not empty, then uncomment the blocklist_url line in pulledpork.conf file and replace it with the one provided
if [ -n "$BLOCKLIST_URLS" ]; then
    sed -i "s/#blocklist_urls = .*/blocklist_urls = $BLOCKLIST_URLS/g" "$PULLEDPORT_TEMP_FILE"
else
    sed -i "s/blocklist_urls = .*/#blocklist_urls = http://a.b.com/list.list/g" "$PULLEDPORT_TEMP_FILE"
fi

# replace community_ruleset in pulledpork.conf file with the one provided
sed -i "s/community_rules = .*/community_rules = $COMMUNITY_RULESET/g" "$PULLEDPORT_TEMP_FILE"

# replace registered_ruleset in pulledpork.conf file with the one provided
sed -i "s/registered_rules = .*/registered_rules = $REGISTERED_RULESET/g" "$PULLEDPORT_TEMP_FILE"

# replace LightSPD_ruleset in pulledpork.conf file with the one provided
sed -i "s/LightSPD_rules = .*/LightSPD_rules = $LIGHTSPD_RULESET/g" "$PULLEDPORT_TEMP_FILE"

# replace oinkcode in pulledpork.conf file with the one provided
sed -i "s/oinkcode = .*/oinkcode = $SNORT_OINKCODE/g" "$PULLEDPORT_TEMP_FILE"

# replace snort_blocklist in pulledpork.conf file with the one provided
sed -i "s/snort_blocklist = .*/snort_blocklist = $SNORT_BLOCKLIST/g" "$PULLEDPORT_TEMP_FILE"

# replace et_blocklist in pulledpork.conf file with the one provided
sed -i "s/et_blocklist = .*/et_blocklist = $ET_BLOCKLIST/g" "$PULLEDPORT_TEMP_FILE"

# run pulledpork if DOWNLOAD_RULES is set to true
if [ "$DOWNLOAD_RULES" = true ]; then
    echo "Downloading Snort Rules..."

    pulledpork.py -c "$PULLEDPORT_TEMP_FILE" || exit $?
fi

# if SNORT_BLOCKLIST or ET_BLOCKLIST are set true or BLOCKLIST_URLS is not empty, then uncomment blocklist_path
if [ "$SNORT_BLOCKLIST" = true ] || [ "$ET_BLOCKLIST" = true ] || [ -n "$BLOCKLIST_URLS" ]; then
    sed -i "s/^#\(blocklist_path = .*\)/\1/" "$PULLEDPORT_TEMP_FILE"
else
    sed -i "s/^\(blocklist_path = .*\)/#\1/" "$PULLEDPORT_TEMP_FILE"
fi

# run pulledpork if SNORT_COMPRESSED_RULES_FILENAME is not empty
if [ -n "$SNORT_COMPRESSED_RULES_FILE_PATH" ]; then
    # check if file exists in $SNORT_COMPRESSED_RULES_FILE_PATH
    if [ ! -f "$SNORT_COMPRESSED_RULES_FILE_PATH" ]; then
        echo "Compressed Snort Rule file at $SNORT_COMPRESSED_RULES_FILE_PATH does not exist"
        exit 1
    fi

    echo "Extracting Snort Rules..."

    pulledpork.py -f "$SNORT_COMPRESSED_RULES_FILE_PATH" -c "$PULLEDPORT_TEMP_FILE" || exit $?
fi

# remove temp file
rm -f "$PULLEDPORT_TEMP_FILE"

echo "Starting Snort..."

/usr/local/bin/snort -c /usr/local/etc/snort/snort.lua -s 65535 -m 0x1b -k none -l /var/log/snort -u snort -g snort --plugin-path=/usr/local/etc/snort3/so_rules/ -i "$NETWORK_INTERFACE"
