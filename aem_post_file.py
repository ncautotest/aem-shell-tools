#!/usr/bin/env python3

# POST a file blob to AEM

import os
import sys

import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

DEFAULT_REQUEST_TIMEOUT = 20  # request timeout in seconds
DEFAULT_HEADERS = {"User-Agent": "Adobe-Campaign/1.0"}


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="AEM file poster")
    parser.add_argument(
        "url",
        help="URL of the AEM location to import content to (TARGET)",
        action="store",
    )
    parser.add_argument(
        "--user", "-u", 
        metavar="user", 
        help="User name (TARGET)", 
        default="admin"
    )
    parser.add_argument(
        "--password", "-p",
        metavar="password (TARGET)",
        help="User password",
        default="admin",
    )
    parser.add_argument(
        "--import-from", "-i",
        metavar="import_from",
        help="Import file path",
        required=True,
    )
    parser.add_argument(
        "--debug", "-d", 
        dest="debug", 
        default=False, 
        action="store_true"
    )
    parser.add_argument(
        "--node-name", "-n",
        metavar="aem_node_name",
        help="Custom AEM node name, if none then the file name will be used",
    )

    args = parser.parse_args(sys.argv[1:])

    print(args)
    print("Posting JCR data...")
    print("Posting to '%s'" % (args.url))

    node_name = args.node_name or os.path.basename(args.import_from)

    headers = {**DEFAULT_HEADERS, "Referer": args.url}
    with open(args.import_from, "rb") as f:
        response = requests.post(
            args.url,
            files={node_name: (node_name, f)},
            headers=headers,
            auth=(args.user, args.password),
            verify=False,
            timeout=DEFAULT_REQUEST_TIMEOUT,
        )
    print("HTTP Response code: %s" % response.status_code)

    if args.debug:
        print(response.text)
    print("Done")
