#!/usr/bin/env python3

# List workflow instances on an AEM instance and optionally kill running/stale instances
# Use python wf.py -h for all options

# Examples:
# show full info (wide format)
# wf.py http://localhost:4502 -w
#
# kill all workflows with model name containing 'smart tag'
# wf.py http://localhost:4502 -w -f 'smart tag' -kk
#
# kill all stale workflows (up to 1 mln)
# wf.py http://localhost:4502 -w -k -l 1000000


import json
import logging
import sys

import argparse
import datetime
import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

BASE_URL = "http://localhost:4502"
REST_ENDPOINT = (
    "/libs/cq/workflow/content/console/instances.pretty.json?start=0&limit=%s"
)
DEFAULT_MAX_RECORDS = 1000


def kill_instance(conf, workflow_instance_path):
    """
    Kill workflow instance
    :param conf: args
    :param workflow_instance_path: instance JCR path
    """
    payload = {"state": "ABORTED", "_charset_": "utf-8", "terminateComment": "wf-kill"}
    wf_post_url = conf.host + workflow_instance_path
    print(wf_post_url)
    answer = requests.post(
        wf_post_url, data=payload, verify=False, auth=(conf.user, conf.password)
    )

    print("status={}".format(answer.status_code))


def enable_debug():
    import http.client as http_client
    http_client.HTTPConnection.debuglevel = 1

    # initialize logging
    logging.basicConfig()
    logging.getLogger().setLevel(logging.DEBUG)
    requests_log = logging.getLogger("requests.packages.urllib3")
    requests_log.setLevel(logging.DEBUG)
    requests_log.propagate = True


def is_valid_url(url):
    """
    :param url: URL
    :rtype: bool
    """
    if url and (url.startswith("http://") or url.startswith("https://")):
        return url

    raise argparse.ArgumentTypeError(
        '\n*** ERROR ***\n Invalid host URL: "{}"'.format(url)
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="AEM workflows management tool")

    parser.add_argument(
        "host",
        help="URL of the AEM instance, by default %(default)s",
        nargs="?",
        action="store",
        type=is_valid_url,
        default=BASE_URL,
    )
    parser.add_argument(
        "--verbose",
        "-v",
        default=False,
        action="store_true",
        help="Show raw JSON (%(default)s)",
    )
    parser.add_argument(
        "--wide",
        "-w",
        default=False,
        action="store_true",
        help="Include description (%(default)s)",
    )
    parser.add_argument(
        "--kill",
        "-k",
        default=False,
        action="store_true",
        help="Kill all STALE workflows (use -kk to also kill RUNNING) (%(default)s)",
    )
    parser.add_argument(
        "--filter", "-f", help="only include models containing filter string"
    )
    parser.add_argument(
        "--limit", "-l", type=int, default=DEFAULT_MAX_RECORDS, help="Limit to N records"
    )
    parser.add_argument(
        "--user", "-u", metavar="user", help="User name", default="admin"
    )
    parser.add_argument(
        "--password", "-p", metavar="password", help="User password", default="admin"
    )
    parser.add_argument(
        "--kill9",
        "-kk",
        default=False,
        action="store_true",
        help="Kill all workflows including RUNNING (nuclear option)",
    )
    parser.add_argument(
        "--debug", "-d", default=False, action="store_true", help="Debug HTTP"
    )

    args = parser.parse_args(sys.argv[1:])

    if args.debug:
        enable_debug()

    url = args.host + REST_ENDPOINT % args.limit
    response = requests.get(url, verify=False, auth=(args.user, args.password))
    if not response.ok:
        sys.exit(f"HTTP {response.status_code}: {response.text[:200]}")
    json_data = response.json()
    wf_data = json_data.get("workflows")

    for idx, workflow in enumerate(wf_data):
        model = workflow.get("model")

        if args.filter and args.filter.lower() not in model.lower():
            continue

        if args.kill or args.kill9:
            state = workflow.get("state")
            if state == "STALE" or args.kill9:
                workflow_instance_path = workflow.get("item")
                print("Killing model {}\n\tWF: {}".format(model, workflow_instance_path))
                kill_instance(args, workflow_instance_path)

        # parse milliseconds to human-readable time
        started = datetime.datetime.fromtimestamp(int(workflow.get("startTime") / 1000))
        started_pretty = started.strftime("%H:%M:%S")

        if args.wide:
            model = "{}\n\t".format(model)
        else:
            model = ""

        print(
            "{index:<4}{model}{starttime:>5} {state} {payloadpath}".format(
                index=idx + 1,
                model=model,
                starttime=started_pretty,
                state=workflow.get("state"),
                payloadpath=workflow.get("payloadPath"),
            )
        )

    print(f"Total workflows returned: {len(wf_data)}")

    if args.verbose:
        print(json.dumps(json_data, indent=2))
