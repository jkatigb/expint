#!/usr/bin/env python3
"""
Nagios plugin: cluster health
Exit 0 OK, 1 WARNING (one down), 2 CRITICAL (all down), else UNKNOWN
"""
import json, sys, urllib.request, contextlib

TIMEOUT = 5
with open("/etc/nagios4/web_cluster.json", "r") as f:
    hosts = json.load(f)

def is_up(host):
    url = f"http://{host}/"
    try:
        with contextlib.closing(urllib.request.urlopen(url, timeout=TIMEOUT)) as r:
            return 200 <= r.status < 400
    except Exception:
        return False

down = [h for h in hosts["servers"] if not is_up(h)]

if len(down) == 0:
    print(f"OK - all {len(hosts['servers'])} web servers up")
    sys.exit(0)
elif len(down) == 1:
    print(f"WARNING - {down[0]} down")
    sys.exit(1)
elif len(down) == len(hosts["servers"]):
    print("CRITICAL - all web servers down")
    sys.exit(2)
else:
    print("UNKNOWN - partial outage")
    sys.exit(3)