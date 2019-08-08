#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR=${DIR}/..
LIB_DIR=${ROOT_DIR}/lib

source .env
eval $(${LIB_DIR}/toml-to-env/bin/toml-to-env.js ${ROOT_DIR}/config.toml)

cd ${ROOT_DIR}/checked_out
mkdir -p ${ROOT_DIR}/results

function runScannerTool() {
  #insert switch based on the env
  case ${tool} in
  fossa-api)
    runFossaApi $1
    ;;
  fossa-json)
    runFossaJSON $1
    ;;
  lc-csv)
    runLcCSV $1
    ;;
  lc-summary)
    runLcSummary $1
    ;;
  *)
    echo "unsupported tool: ${tool}"
    echo "check your config.toml and try again."
    ;;
  esac
}

function runFossaApi() {
  REPO_PATH=$1
  echo "Running fossa-api for repo: ${REPO_PATH}"

  cd ${ROOT_DIR}/checked_out/${REPO_PATH}
  fossa analyze 
}

function runFossaJSON() {
  REPO_PATH=$1
  echo "Running fossa-json for repo: ${REPO_PATH}"

  cd ${ROOT_DIR}/checked_out/${REPO_PATH}

  fossa analyze -o > ${ROOT_DIR}/results/${REPO_PATH}.json
  fossa test
}

function runLcCSV() {
  REPO_PATH=$1

  echo "Running license-checker for repo: ${REPO_PATH}"
  cd ${ROOT_DIR}/checked_out/${REPO_PATH}
  ${LIB_DIR}/node_modules/.bin/license-checker . \
    --production \
    --csv \
    --out ${ROOT_DIR}/results/${REPO_PATH}.csv
}


function runLcSummary() {
  REPO_PATH=$1

  echo "Running license-checker for repo: ${REPO_PATH}"
  cd ${ROOT_DIR}/checked_out/${REPO_PATH}
  ${LIB_DIR}/node_modules/.bin/license-checker . \
    --production \
    --summary \
    --out ${ROOT_DIR}/results/${REPO_PATH}.txt
}

#change delimiter from `;` to ` ` to allow for simple iteration
repos=`echo ${repos} | awk '{gsub(/[;]/," ");print}'`

for OUTPUT in ${repos}
do
  REPO_PATH=`echo ${OUTPUT} | awk -F 'mojaloop/' '{print $2}'`
  runScannerTool ${REPO_PATH}
done
