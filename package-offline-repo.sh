#!/bin/bash

# Define a timestamp function
timestamp() {
  printf "%s-%s" `date "+%Y%m%d.%H%M%S"` `expr $RANDOM % 1000`
}

MAVEN_REPO_DIR=~/.m2/repository
if [ ! -e ${MAVEN_REPO_DIR} ]; then
    echo "ERROR: ${MAVEN_REPO_DIR} directory must exist."
    exit 1
fi

ZIP_FILE=${PWD}/maven-offline-repo-$(timestamp).zip
if [ -e ${ZIP_FILE} ]; then
    echo "ERROR: ${ZIP_FILE} file must not exist."
    exit 1
fi

pushd ${MAVEN_REPO_DIR}
zip -r ${ZIP_FILE} .
popd
