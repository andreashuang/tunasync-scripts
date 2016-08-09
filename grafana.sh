#!/bin/bash
# requires: createrepo reposync wget curl
set -e
set -o pipefail

_here=`dirname $(realpath $0)`
. ${_here}/helpers/apt-download

[ -z "${LOADED_APT_DOWNLOAD}" ] && (echo "failed to load apt-download"; exit 1)

BASE_PATH="${TUNASYNC_WORKING_DIR}"
BASE_URL=${TUNASYNC_UPSTREAM_URL:-"https://packagecloud.io/grafana/stable"}

YUM_PATH="${BASE_PATH}/yum"
UBUNTU_PATH="${BASE_PATH}/ubuntu"
DEBIAN_PATH="${BASE_PATH}/debian"

UBUNTU_VERSIONS=("trusty" "xenial")
DEBIAN_VERSIONS=("wheezy" "jessie")
EL_VERSIONS=("6" "7")

mkdir -p ${YUM_PATH} ${UBUNTU_PATH} ${DEBIAN_PATH}


# =================== APT repos ===============================
# export APT_DRY_RUN=0
base_url="${BASE_URL}/ubuntu"
for version in ${UBUNTU_VERSIONS[@]}; do
	for arch in "amd64" "i386"; do
		apt-download-binary ${base_url} "$version" "main" "$arch" "${UBUNTU_PATH}" || true
	done
done
echo "Ubuntu finished"

base_url="${BASE_URL}/debian"
for version in ${DEBIAN_VERSIONS[@]}; do
	for arch in "amd64" "i386"; do
		apt-download-binary ${base_url} "$version" "main" "$arch" "${DEBIAN_PATH}" || true
	done
done
echo "Debian finished"


# =================== YUM/DNF repos ==========================

cache_dir="/tmp/yum-grafana-cache/"
cfg="/tmp/yum-grafana.conf"
cat <<EOF > ${cfg}
[main]
keepcache=0

EOF

for elver in ${EL_VERSIONS[@]}; do
cat << EOF >> $cfg 
[el${elver}]
name=el${elver}
baseurl=${BASE_URL}/el/$elver/x86_64/
enabled=1
EOF
done

reposync -c $cfg -d -p ${YUM_PATH} -e $cache_dir
for elver in ${EL_VERSIONS[@]}; do
	createrepo --update -v -c $cache_dir -o ${YUM_PATH}/el${elver}/ ${YUM_PATH}/el${elver}/
done
