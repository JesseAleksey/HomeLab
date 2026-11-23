#!/usr/bin/env bash
# health-check.sh — read-only health check for the homelab.
# Never starts, stops, or restarts anything (AdGuard is the house DNS).
# Exit code: 0 if every check passes, 1 if any fail.

set -u

DNS_SERVER="${DNS_SERVER:-192.168.4.46}"
MEDIA_MOUNT="${MEDIA_MOUNT:-/mnt/media}"
JELLYFIN_URL="${JELLYFIN_URL:-http://localhost:8096}"
DISK_PATH="${DISK_PATH:-/}"
DISK_LIMIT="${DISK_LIMIT:-80}"

if [ -t 1 ]; then
  GREEN=$'\e[32m'; RED=$'\e[31m'; RESET=$'\e[0m'
else
  GREEN=""; RED=""; RESET=""
fi

failures=0
pass() { printf '%s[PASS]%s %s\n' "$GREEN" "$RESET" "$1"; }
fail() { printf '%s[FAIL]%s %s\n' "$RED" "$RESET" "$1"; failures=$((failures + 1)); }

# 1. Containers running
for c in adguard jellyfin; do
  state=$(docker inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
  if [ "$state" = "running" ]; then
    pass "Container '$c' is running"
  else
    fail "Container '$c' is not running (state: ${state:-not found})"
  fi
done

# 2. NAS share mounted
if mountpoint -q "$MEDIA_MOUNT"; then
  pass "$MEDIA_MOUNT is mounted ($(findmnt -no SOURCE "$MEDIA_MOUNT"))"
else
  fail "$MEDIA_MOUNT is not mounted"
fi

# 3. AdGuard blocks doubleclick.net
# Default blocking returns 0.0.0.0 / ::; other modes return NXDOMAIN or REFUSED.
blocked_out=$(dig @"$DNS_SERVER" doubleclick.net A +time=3 +tries=1 2>&1)
blocked_status=$(grep -oP 'status: \K[A-Z]+' <<<"$blocked_out")
blocked_ips=$(dig @"$DNS_SERVER" doubleclick.net A +short +time=3 +tries=1 2>/dev/null | grep -E '^[0-9.]+$')
if [ -z "$blocked_status" ]; then
  fail "doubleclick.net: no reply from DNS server $DNS_SERVER"
elif [ "$blocked_ips" = "0.0.0.0" ] || [ "$blocked_status" = "NXDOMAIN" ] || [ "$blocked_status" = "REFUSED" ] \
     || { [ "$blocked_status" = "NOERROR" ] && [ -z "$blocked_ips" ]; }; then
  pass "doubleclick.net is blocked (${blocked_ips:-$blocked_status})"
else
  fail "doubleclick.net is NOT blocked (resolved to: $(tr '\n' ' ' <<<"$blocked_ips"))"
fi

# 4. AdGuard resolves google.com
google_ips=$(dig @"$DNS_SERVER" google.com A +short +time=3 +tries=1 2>/dev/null | grep -E '^[0-9.]+$' | grep -v '^0\.0\.0\.0$')
if [ -n "$google_ips" ]; then
  pass "google.com resolves ($(head -n1 <<<"$google_ips"))"
else
  fail "google.com does not resolve via $DNS_SERVER"
fi

# 5. Jellyfin responds
jf_body=$(curl -fsS --max-time 5 "$JELLYFIN_URL/health" 2>/dev/null)
if [ "$jf_body" = "Healthy" ]; then
  pass "Jellyfin responds on $JELLYFIN_URL (Healthy)"
else
  fail "Jellyfin did not respond healthy on $JELLYFIN_URL (got: ${jf_body:-no response})"
fi

# 6. Disk usage
usage=$(df --output=pcent "$DISK_PATH" | tail -n1 | tr -dc '0-9')
if [ -n "$usage" ] && [ "$usage" -lt "$DISK_LIMIT" ]; then
  pass "Disk usage on $DISK_PATH is ${usage}% (limit ${DISK_LIMIT}%)"
else
  fail "Disk usage on $DISK_PATH is ${usage:-unknown}% (limit ${DISK_LIMIT}%)"
fi

echo
if [ "$failures" -eq 0 ]; then
  printf '%sAll checks passed.%s\n' "$GREEN" "$RESET"
  exit 0
else
  printf '%s%d check(s) failed.%s\n' "$RED" "$failures" "$RESET"
  exit 1
fi
