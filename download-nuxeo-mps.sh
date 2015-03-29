#!/bin/bash

if [[ "" = $1 ]]; then
    echo >&2 "usage: $0 nuxeo-build-version"
    exit 1
fi
VERSION=${1}

MARKETPLACE_PKG_LST_FILE=marketplace-${VERSION}.lst

if [[ ! -e ${MARKETPLACE_PKG_LST_FILE} ]]; then
    echo "File ${MARKETPLACE_PKG_LST_FILE} must exist!"
    exit 1
fi
MARKETPLACE_PKG_LST_FILE=`echo $(cd $(dirname "$MARKETPLACE_PKG_LST_FILE") && pwd -P)/$(basename "$MARKETPLACE_PKG_LST_FILE")`

DOWNLOAD_DIR=./nxr-downloads-${VERSION}
if [ -e ${DOWNLOAD_DIR} ]; then
    echo "ERROR: ${DOWNLOAD_DIR} directory must not exist."
    exit 1
fi

read -e -p "Enter Connect Username: " -i rg1 USERNM
read -e -s -p "Enter Connect Password: " PASSWD
CONNECT_BASE_URL="https://connect.nuxeo.com/nuxeo/site/marketplace/package"

GITHUB_NUXEO_BASE_URL="https://github.com/nuxeo"

PWD_FILE=$(mktemp)
printf "password=%s" ${PASSWD} >> ${PWD_FILE}
COOKIE_JAR=$(mktemp)
mkdir ${DOWNLOAD_DIR} || exit 1
pushd ${DOWNLOAD_DIR}

while read p; do

    PKG_NAME=`echo $p | awk -F: '{print $1}'`
    PKG_VERSION=`echo $p | awk -F: '{print $2}'`
    PKG_REPO_NAME=`echo $p | awk -F: '{print $3}'`
    echo "Current package: ${PKG_NAME}:${PKG_VERSION}"

    curl -s --cookie $COOKIE_JAR --cookie-jar $COOKIE_JAR \
            --data username=${USERNM} --data @${PWD_FILE} \
            ${CONNECT_BASE_URL}/${PKG_NAME}-${PKG_VERSION}/download/\@\@login
    curl -s --cookie $COOKIE_JAR --cookie-jar $COOKIE_JAR -J -O \
            ${CONNECT_BASE_URL}/${PKG_NAME}-${PKG_VERSION}/download?version=${PKG_VERSION}
    curl -s -L -o ${PKG_REPO_NAME}-${PKG_VERSION}-sources.zip \
            ${GITHUB_NUXEO_BASE_URL}/${PKG_REPO_NAME}/archive/release-${PKG_VERSION}.zip

done < ${MARKETPLACE_PKG_LST_FILE}

popd

rm ${PWD_FILE}
rm ${COOKIE_JAR}
