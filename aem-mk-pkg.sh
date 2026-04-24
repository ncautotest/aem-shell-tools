#!/usr/bin/env bash

# Create content package for AEM_HOST and saved to disk
# Pass JCR path as 1st argument, e.g. /content/we-retail/us/en

[[ "$#" -eq 0 ]] && echo "USAGE: $(basename "$0") /content/mam/offers/test" && exit 1


# SOURCE AEM (override via env vars)
AEM_HOST="${AEM_HOST:-http://localhost:4502}"
AEM_USER="${AEM_USER:-admin}"
AEM_PASS="${AEM_PASS:-admin}"

GRP_NAME="${GRP_NAME:-ncpkg}"
PKG_NAME="${PKG_NAME:-ncdump}"

# STEP 0: DELETE old package if exists
curl -v -u "$AEM_USER:$AEM_PASS" -F cmd=delete "$AEM_HOST/crx/packmgr/service/.json/etc/packages/${GRP_NAME}/${PKG_NAME}.zip"

# STEP 1: Create package
curl -v -u "$AEM_USER:$AEM_PASS" \
	-X POST "$AEM_HOST/crx/packmgr/service/.json/etc/packages/${GRP_NAME}/${PKG_NAME}.zip?cmd=create" \
	-d groupName=${GRP_NAME} \
	-d packageName=${PKG_NAME}


# STEP 2: UPDATE
curl -v -u "$AEM_USER:$AEM_PASS" \
	-X POST "$AEM_HOST/crx/packmgr/update.jsp" \
	-F path="/etc/packages/${GRP_NAME}/${PKG_NAME}.zip" \
	-F groupName="${GRP_NAME}" \
	-F packageName="${PKG_NAME}" \
	-F filter='[{"root":"'$1'","rules":[]}]' \
	-F '_charset_=UTF-8'

# EXAMPLE FOR **MULTIPLE** PATHS (pass valid JSON array for 'filter')

# curl -v -u "$AEM_USER:$AEM_PASS" \
# 	-X POST "$AEM_HOST/crx/packmgr/update.jsp" \
# 	-F path="/etc/packages/${GRP_NAME}/${PKG_NAME}.zip" \
# 	-F groupName="${GRP_NAME}" \
# 	-F packageName="${PKG_NAME}" \
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
# 	-F '_charset_=UTF-8'


# STEP 3: BUILD
curl -v -u "$AEM_USER:$AEM_PASS" \
	-X POST "$AEM_HOST/crx/packmgr/service/.json/etc/packages/${GRP_NAME}/${PKG_NAME}.zip?cmd=build"

# STEP 4: DOWNLOAD
curl --output "${GRP_NAME}-$PKG_NAME.zip" -v -u "$AEM_USER:$AEM_PASS" "$AEM_HOST/etc/packages/${GRP_NAME}/${PKG_NAME}.zip"

open -R "${GRP_NAME}-${PKG_NAME}.zip"
