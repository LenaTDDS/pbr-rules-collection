#!/bin/sh
# shellcheck disable=SC2015,SC3003,SC3060

TARGET_URL_1="https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS13414"
TARGET_URL_2="https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS35995"
TARGET_DL_FILE="/var/pbr_tmp_x.json"
TARGET_TABLE="inet fw4"
TARGET_INTERFACE="wg0"

mkdir -p "${TARGET_DL_FILE%/*}"

uclient-fetch -qO- "$TARGET_URL_1" | jq -r '.data.prefixes[].prefix' > "$TARGET_DL_FILE.tmp" || exit 1
uclient-fetch -qO- "$TARGET_URL_2" | jq -r '.data.prefixes[].prefix' >> "$TARGET_DL_FILE.tmp" || exit 1
jq -Rs 'split("\n") | map(select(. != "")) | {list: .}' "$TARGET_DL_FILE.tmp" > "$TARGET_DL_FILE" || exit 1

all_params=$(jq -r '.list[]' "$TARGET_DL_FILE")
params4=$(echo "$all_params" | awk '!/:/')
params6=$(echo "$all_params" | awk '/:/')

[ "$(uci get pbr.config.ipv6_enabled)" = "1" ] && vers="4 6" || vers="4"

for ver in $vers; do
    case "$ver" in
        4) params="$params4" ;;
        6) params="$params6" ;;
    esac

    [ -n "$params" ] && _ret=0 || continue

    nftset="pbr_${TARGET_INTERFACE}_${ver}_dst_ip_user"
    nft list set "$TARGET_TABLE" "$nftset" >/dev/null 2>&1 || {
        echo "nft set $nftset does not exist; ensure pbr is started"
        continue
    }

    nft add element "$TARGET_TABLE" "$nftset" { ${params//$'\n'/, } } || _ret=1
done
