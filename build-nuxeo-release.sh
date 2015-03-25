#!/bin/bash

VERSION=""
RELEASE_TAG=""
MARKETPLACE_PKG_LST_FILE=""

build_marketplace_packages() {

    MP_CONF_URL=https://raw.github.com/nuxeo/integration-scripts/master/marketplace.ini

    # Clean-up marketplace/release.ini
    rm marketplace/release.ini 2>/dev/null

    ./scripts/release_mp.py clone -m ${MP_CONF_URL}

    while read p; do

        PKG_NAME=`echo $p | awk -F: '{print $1}'`
        PKG_VERSION=`echo $p | awk -F: '{print $2}'`
        PKG_REPO_NAME=`echo $p | awk -F: '{print $3}'`
        echo "Current package: ${PKG_NAME}:${PKG_VERSION}"

        pushd marketplace/${PKG_REPO_NAME}
        echo "Current package directory:" `pwd`
        git checkout release-${PKG_VERSION}
        mvn package -DskipTests
        mvn dependency:sources
        echo "Done build for package: ${PKG_NAME}"
        popd

    done < ${MARKETPLACE_PKG_LST_FILE}

}

if [[ "" = $1 ]]; then
    echo >&2 "usage: $0 nuxeo-build-version"
    exit 1
fi
VERSION=${1}

RELEASE_TAG=release-${VERSION}
MARKETPLACE_PKG_LST_FILE=marketplace-${VERSION}.lst

if [[ ! -e ${MARKETPLACE_PKG_LST_FILE} ]]; then
    echo "File ${MARKETPLACE_PKG_LST_FILE} must exist!"
    exit 1
fi
MARKETPLACE_PKG_LST_FILE=`echo $(cd $(dirname "$MARKETPLACE_PKG_LST_FILE") && pwd -P)/$(basename "$MARKETPLACE_PKG_LST_FILE")`

NUXEO_BUILD_DIR=./nuxeo-build
if [ -e ${NUXEO_BUILD_DIR} ]; then
    echo "ERROR: ${NUXEO_BUILD_DIR} directory must not exist."
    exit 1
fi
mkdir ${NUXEO_BUILD_DIR} || exit 1

NUXEO_URL=https://github.com/nuxeo/nuxeo.git

pushd ${NUXEO_BUILD_DIR}
git clone ${NUXEO_URL}
pushd nuxeo
./clone.py ${RELEASE_TAG} || exit 1
mvn install -DskipTests -Paddons,distrib
mvn dependency:sources -Paddons,distrib
pushd nuxeo-distribution
mvn install -DskipTests -pl :nuxeo-distribution-tomcat -Pnuxeo-cap,sdk
mvn dependency:sources -pl :nuxeo-distribution-tomcat -Pnuxeo-cap,sdk
popd
build_marketplace_packages
popd
popd
