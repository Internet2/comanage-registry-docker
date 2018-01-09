#!/bin/bash

set -e

show_help() {
    echo "Usage: $0 [option...]" >&2
    echo
    echo "  -h, --help              show this usage message"
    echo "  -r, --registry_version  COmanage Registry version"
    echo "  --registry_base_image_version"
    echo "  --basic_auth_image_version"
    echo "  --shibboleth_sp_version"
    echo "  --shibboleth_sp_base_image_version"
    echo "  --shibboleth_sp_image_version"
    echo "  --mod_auth_openidc_image_version"
    echo "  --i2_base_image_version"
    echo "  --i2_image_version"
    echo "  --postgres_image_version"
    echo "  --slapd_base_image_version"
    echo "  --slapd_image_version"
    echo "  --slapd_proxy_image_version"
    echo "  -d, --docker_registry   Docker registry to push into"
    echo
}

# Default values.
COMANAGE_REGISTRY_VERSION="3.2.1"
COMANAGE_REGISTRY_BASE_IMAGE_VERSION="1"
COMANAGE_REGISTRY_BASIC_AUTH_IMAGE_VERSION="1"
COMANAGE_REGISTRY_SHIBBOLETH_SP_VERSION="3.0.4"
COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION="1"
COMANAGE_REGISTRY_SHIBBOLETH_SP_IMAGE_VERSION="1"
COMANAGE_REGISTRY_MOD_AUTH_OPENIDC_IMAGE_VERSION="1"
COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION="1"
COMANAGE_REGISTRY_I2_IMAGE_VERSION="1"
COMANAGE_REGISTRY_POSTGRES_IMAGE_VERSION="1"
COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION="2"
COMANAGE_REGISTRY_SLAPD_IMAGE_VERSION="2"
COMANAGE_REGISTRY_SLAPD_PROXY_IMAGE_VERSION="2"
DOCKER_REGISTRY=

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
    show_help
    exit 0
    ;;
    -r|--registry_version)
    COMANAGE_REGISTRY_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    --registry_base_image_version)
    COMANAGE_REGISTRY_BASE_IMAGE_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    --basic_auth_image_version)
    COMANAGE_REGISTRY_BASIC_AUTH_IMAGE_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    --shibboleth_sp_version)
    COMANAGE_REGISTRY_SHIBBOLETH_SP_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    --shibboleth_sp_base_image_version)
    COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    --shibboleth_sp_image_version)
    COMANAGE_REGISTRY_SHIBBOLETH_SP_IMAGE_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    --mod_auth_openidc_image_version)
    COMANAGE_REGISTRY_MOD_AUTH_OPENIDC_IMAGE_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    --i2_base_image_version)
    COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    --i2_image_version)
    COMANAGE_REGISTRY_I2_IMAGE_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    --postgres_image_version)
    COMANAGE_REGISTRY_POSTGRES_IMAGE_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    --slapd_base_image_version)
    COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    --slapd_image_version)
    COMANAGE_REGISTRY_SLAPD_IMAGE_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    --slapd_proxy_image_version)
    COMANAGE_REGISTRY_SLAPD_PROXY_IMAGE_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--docker_registry)
    DOCKER_REGISTRY="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

declare -a inputs=(
"COMANAGE_REGISTRY_VERSION"
"COMANAGE_REGISTRY_BASE_IMAGE_VERSION"
"COMANAGE_REGISTRY_BASIC_AUTH_IMAGE_VERSION"
"COMANAGE_REGISTRY_SHIBBOLETH_SP_VERSION"
"COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION"
"COMANAGE_REGISTRY_SHIBBOLETH_SP_IMAGE_VERSION"
"COMANAGE_REGISTRY_MOD_AUTH_OPENIDC_IMAGE_VERSION"
"COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION"
"COMANAGE_REGISTRY_I2_IMAGE_VERSION"
"COMANAGE_REGISTRY_POSTGRES_IMAGE_VERSION"
"COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION"
"COMANAGE_REGISTRY_SLAPD_IMAGE_VERSION"
"COMANAGE_REGISTRY_SLAPD_PROXY_IMAGE_VERSION"
"DOCKER_REGISTRY"
)

for input in "${inputs[@]}"
do
    eval value=\$"${input}";
    echo "Using $input $value"
done

pushd comanage-registry-base
TAG="${COMANAGE_REGISTRY_VERSION}-${COMANAGE_REGISTRY_BASE_IMAGE_VERSION}"
docker build \
  --build-arg COMANAGE_REGISTRY_VERSION=${COMANAGE_REGISTRY_VERSION} \
  -t comanage-registry-base:${TAG} .
if [[ -n "${DOCKER_REGISTRY}" ]];
then
    docker tag \
        comanage-registry-base:${TAG} \
        ${DOCKER_REGISTRY}/comanage-registry-base:${TAG}
    docker push \
        ${DOCKER_REGISTRY}/comanage-registry-base:${TAG}
fi
popd

pushd comanage-registry-basic-auth
TAG="${COMANAGE_REGISTRY_VERSION}-basic-auth-${COMANAGE_REGISTRY_BASIC_AUTH_IMAGE_VERSION}" 
docker build \
  --build-arg COMANAGE_REGISTRY_VERSION=${COMANAGE_REGISTRY_VERSION} \
  --build-arg COMANAGE_REGISTRY_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_BASE_IMAGE_VERSION} \
  -t comanage-registry:$TAG .
if [[ -n "${DOCKER_REGISTRY}" ]];
then
    docker tag \
        comanage-registry:$TAG \
        ${DOCKER_REGISTRY}/comanage-registry:$TAG
    docker push \
        ${DOCKER_REGISTRY}/comanage-registry:$TAG
fi
popd

pushd comanage-registry-shibboleth-sp-base
TAG="${COMANAGE_REGISTRY_SHIBBOLETH_SP_VERSION}-${COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION}"
docker build \
    -t comanage-registry-shibboleth-sp-base:$TAG . 
if [[ -n "${DOCKER_REGISTRY}" ]];
then
    docker tag \
        comanage-registry-shibboleth-sp-base:$TAG \
        ${DOCKER_REGISTRY}/comanage-registry-shibboleth-sp-base:$TAG
    docker push \
        ${DOCKER_REGISTRY}/comanage-registry-shibboleth-sp-base:$TAG
fi
popd

pushd comanage-registry-shibboleth-sp
TAG="${COMANAGE_REGISTRY_VERSION}-shibboleth-sp-${COMANAGE_REGISTRY_SHIBBOLETH_SP_IMAGE_VERSION}"
docker build \
    --build-arg COMANAGE_REGISTRY_VERSION=${COMANAGE_REGISTRY_VERSION} \
    --build-arg COMANAGE_REGISTRY_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_BASE_IMAGE_VERSION} \
    --build-arg COMANAGE_REGISTRY_SHIBBOLETH_SP_VERSION=${COMANAGE_REGISTRY_SHIBBOLETH_SP_VERSION} \
    --build-arg COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION} \
    -t comanage-registry:$TAG .
if [[ -n "${DOCKER_REGISTRY}" ]];
then
    docker tag \
        comanage-registry:$TAG \
        ${DOCKER_REGISTRY}/comanage-registry:$TAG
    docker push \
        ${DOCKER_REGISTRY}/comanage-registry:$TAG
fi
popd

pushd comanage-registry-mod-auth-openidc
TAG="${COMANAGE_REGISTRY_VERSION}-mod-auth-openidc-${COMANAGE_REGISTRY_MOD_AUTH_OPENIDC_IMAGE_VERSION}" 
docker build \
    --build-arg COMANAGE_REGISTRY_VERSION=${COMANAGE_REGISTRY_VERSION} \
    --build-arg COMANAGE_REGISTRY_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_BASE_IMAGE_VERSION} \
    -t comanage-registry:$TAG .
if [[ -n "${DOCKER_REGISTRY}" ]];
then
    docker tag \
        comanage-registry:$TAG \
        ${DOCKER_REGISTRY}/comanage-registry:$TAG
    docker push \
        ${DOCKER_REGISTRY}/comanage-registry:$TAG
fi
popd

pushd comanage-registry-internet2-tier-base
TAG="${COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION}"
docker build \
    -t comanage-registry-internet2-tier-base:$TAG .
if [[ -n "${DOCKER_REGISTRY}" ]];
then
    docker tag \
        comanage-registry-internet2-tier-base:$TAG \
        ${DOCKER_REGISTRY}/comanage-registry-internet2-tier-base:$TAG
    docker push \
        ${DOCKER_REGISTRY}/comanage-registry-internet2-tier-base:$TAG
fi
popd

pushd comanage-registry-internet2-tier
TAG="${COMANAGE_REGISTRY_VERSION}-internet2-tier-${COMANAGE_REGISTRY_I2_IMAGE_VERSION}"
docker build \
    --build-arg COMANAGE_REGISTRY_VERSION=${COMANAGE_REGISTRY_VERSION} \
    --build-arg COMANAGE_REGISTRY_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_BASE_IMAGE_VERSION} \
    --build-arg COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION} \
    -t comanage-registry:$TAG .
if [[ -n "${DOCKER_REGISTRY}" ]];
then
    docker tag \
        comanage-registry:$TAG \
        ${DOCKER_REGISTRY}/comanage-registry:$TAG
    docker push \
        ${DOCKER_REGISTRY}/comanage-registry:$TAG
fi
popd

pushd comanage-registry-postgres
TAG="${COMANAGE_REGISTRY_POSTGRES_IMAGE_VERSION}"
docker build \
    -t comanage-registry-postgres:${TAG} .
if [[ -n "${DOCKER_REGISTRY}" ]];
then
    docker tag \
        comanage-registry-postgres:${TAG} \
        ${DOCKER_REGISTRY}/comanage-registry-postgres:${TAG}
    docker push \
        ${DOCKER_REGISTRY}/comanage-registry-postgres:${TAG}
fi
popd

pushd comanage-registry-slapd-base
TAG="${COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION}"
docker build \
    -t comanage-registry-slapd-base:${TAG} .
if [[ -n "${DOCKER_REGISTRY}" ]];
then
    docker tag \
        comanage-registry-slapd-base:${TAG} \
        ${DOCKER_REGISTRY}/comanage-registry-slapd-base:${TAG}
    docker push \
        ${DOCKER_REGISTRY}/comanage-registry-slapd-base:${TAG}
fi
popd

pushd comanage-registry-slapd
TAG="${COMANAGE_REGISTRY_SLAPD_IMAGE_VERSION}"
docker build \
    --build-arg COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION} \
    -t comanage-registry-slapd:${TAG} .
if [[ -n "${DOCKER_REGISTRY}" ]];
then
    docker tag \
        comanage-registry-slapd:${TAG} \
        ${DOCKER_REGISTRY}/comanage-registry-slapd:${TAG}
    docker push \
        ${DOCKER_REGISTRY}/comanage-registry-slapd:${TAG}
fi
popd

pushd comanage-registry-slapd-proxy
TAG="${COMANAGE_REGISTRY_SLAPD_PROXY_IMAGE_VERSION}"
docker build \
    --build-arg COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION} \
    -t comanage-registry-slapd-proxy:${TAG} .
if [[ -n "${DOCKER_REGISTRY}" ]];
then
    docker tag \
        comanage-registry-slapd-proxy:${TAG} \
        ${DOCKER_REGISTRY}/comanage-registry-slapd-proxy:${TAG}
    docker push \
        ${DOCKER_REGISTRY}/comanage-registry-slapd-proxy:${TAG}
fi
popd

