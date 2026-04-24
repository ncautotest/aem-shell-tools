#!/usr/bin/env bash

# Create content package on source AEM instance and import on TARGET AEM

# uncomment for debug
# set -Exeuo pipefail
# export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

[[ "$#" -eq 0 ]] && echo "USAGE: $(basename "$0") /content/we-retail/us/en" && exit 1


# SOURCE AEM (override via env vars)
AEM_HOST="${AEM_HOST:-http://demo.netcentric.biz:4502}"
AEM_USER="${AEM_USER:-admin}"
AEM_PASS="${AEM_PASS:-secret42}"

# TARGET AEM
AEM_HOST2="${AEM_HOST2:-http://localhost:4502}"
AEM_USER2="${AEM_USER2:-admin}"
AEM_PASS2="${AEM_PASS2:-admin}"

GRP_NAME="${GRP_NAME:-ncpkg}"
PKG_NAME="${PKG_NAME:-ncdump}"

# STEP 0: DELETE package if exists
curl -v -u "$AEM_USER:$AEM_PASS" -F cmd=delete $AEM_HOST/crx/packmgr/service/.json/etc/packages/${GRP_NAME}/${PKG_NAME}.zip || true

# STEP 1: Create package
curl -v -u "$AEM_USER:$AEM_PASS" \
	"$AEM_HOST/crx/packmgr/service/.json/etc/packages/${GRP_NAME}/${PKG_NAME}.zip?cmd=create" \
	-d groupName=${GRP_NAME} \
	-d packageName=${PKG_NAME}

# STEP 2: UPDATE
curl -v -u "$AEM_USER:$AEM_PASS" \
	"$AEM_HOST/crx/packmgr/update.jsp" \
	-F path=/etc/packages/${GRP_NAME}/${PKG_NAME}.zip \
	-F groupName=${GRP_NAME} \
	-F packageName=${PKG_NAME} \
	-F '_charset_=UTF-8' \
	-F filter='[{"root":"'$1'","rules":[]}]' \
	|| true

# EXAMPLE filter for **multiple paths** (pass valid JSON):
# 	-F filter='[
#   {
#     "root": "/content/dam/mmg/approval-pool/1x1.jpg",
#     "rules": []
#   },
#   {
#     "root": "/content/dam/mmg/approval-pool/1x1.mp4",
#     "rules": []
#   },
#   {
#     "root": "/content/mam/web/de/en/account",
#     "rules": []
#   }
# 	]' \


# STEP 3: BUILD
curl -v -u "$AEM_USER:$AEM_PASS" \
	-X POST "$AEM_HOST/crx/packmgr/service/.json/etc/packages/${GRP_NAME}/${PKG_NAME}.zip?cmd=build"

# STEP 4: DOWNLOAD
curl -v -u "$AEM_USER:$AEM_PASS" \
	"$AEM_HOST/etc/packages/${GRP_NAME}/${PKG_NAME}.zip" \
	--output "${GRP_NAME}-${PKG_NAME}.zip"


# =========== TARGET AEM INSTANCE ================

# STEP B1: upload package (optional, can be skipped)
# curl -v -u "$AEM_USER2:$AEM_PASS2" -F cmd=upload -F force=true -F package=@"${GRP_NAME}-${PKG_NAME}.zip" "$AEM_HOST2/crx/packmgr/service/.json"

# STEP B2: install package
curl -v -u "$AEM_USER2:$AEM_PASS2" \
	-F file=@"${GRP_NAME}-${PKG_NAME}.zip" \
	-F name="${GRP_NAME}-${PKG_NAME}.zip" \
	-F force=true \
	-F install=true \
	"$AEM_HOST2/crx/packmgr/service.jsp"

read -n1 -p "open in Finder? (y/n) " yn && [[ $yn == y ]] && open -R "${GRP_NAME}-${PKG_NAME}.zip"
echo
read -n1 -p "open in CRXDELite? (y/n) " yn && [[ $yn == y ]] && open "${AEM_HOST2}/crx/de/index.jsp#$1"
