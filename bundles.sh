#!/usr/bin/env bash

# list bundle active/inactive stats (one line)
curl -s http://admin:admin@localhost:4502/system/console/status-Bundlelist.txt | awk 'NR==2'

# JSON alternative, requires jq:
# curl -s -u admin:admin  http://admin:admin@localhost:4502/system/console/bundles.json | jq -r '.status'