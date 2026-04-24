#!/usr/bin/env bash

# Create nt:folder in aem

# uncomment for debug
# set -Exeuo pipefail
# export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'


USER=admin
PASS=admin
AEM_CSRF_TOKEN_TOKEN=/libs/granite/csrf/token.json

if [ "$#" -ne 1 ]; then
    printf "Usage:\n\t$(basename $0) <AEM_URL>/path/to/new/folder\nNOTE: Intermediary folders will be created if missing.\n\n"
    printf "Example:\n\t$(basename $0) http://localhost:4502/apps/weretail/components/content/articleslist/newnode"
    exit 1
fi

host=`echo $1 | cut -d/ -f1-3`
path=/`echo $1 | cut -d/ -f4-`

echo host=$host
echo path=$path

token="$(curl -H User-Agent:Adobe-Campaign -H Referer:${host} -u "${USER}:${PASS}" "${host}${AEM_CSRF_TOKEN_TOKEN}"  | sed -e 's/[{"token":}]/''/g')"

echo token=${token}

curl  ${1} -vv -H User-Agent:Adobe-Campaign \
  -H "Referer:${host}" \
  -u "${USER}:${PASS}" \
  -H "CSRF-Token:${token}" \
  -F "jcr:primaryType=nt:folder"
