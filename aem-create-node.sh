#!/usr/bin/env bash

# Create node in AEM with given properties
# NOTE: Missing intermediary nodes will be created of type sling:OrderedFolder

# uncomment for debug
# set -Exeuo pipefail
# export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'


USER=admin
PASS=admin
AEM_CSRF_TOKEN_TOKEN=/libs/granite/csrf/token.json

if [ "$#" -lt 2 ]; then
    printf "Usage:\n\t$(basename $0) <AEM_URL> <JCR_PROPERTIES>\n\n"
    printf "NOTE: Missing intermediary nodes will be created of type sling:OrderedFolder\n\n"
    printf "Example:\n\t$(basename $0) http://localhost:4502/content/newpage -F jcr:primaryType=cq:Page -F jcr:content/jcr:primaryType=cq:PageContent -F jcr:content/sling:resourceType=mam/ma/pages/structure -F jcr:content/jcr:title=mynewpage"
    exit 1
fi

host=`echo $1 | cut -d/ -f1-3`

echo HOST=$host

token="$(curl -H User-Agent:Adobe-Campaign -u ${USER}:${PASS} ${host}${AEM_CSRF_TOKEN_TOKEN}  | sed -e 's/[{"token":}]/''/g')"

echo TOKEN=${token}
url=${1}
shift

props="$@"
echo props=${props}
curl  ${url} -vv -H User-Agent:Adobe-Campaign \
  -H Referer:${host} \
  -u ${USER}:${PASS} \
  -H CSRF-Token:${token} \
  ${props}
