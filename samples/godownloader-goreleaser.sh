#!/bin/sh
set -e

BINARY=goreleaser
FORMAT=tar.gz
OWNER=goreleaser
REPO=goreleaser
BINDIR=${BINDIR:-./bin}
TMPDIR=${TMPDIR:-/tmp}

VERSION=$1
if [ -z "${VERSION}" ]; then
echo "specify version number or 'latest'"
exit 1
fi

# download dest source
# if dest is "-", then output to stdout
# if source is api.github.com add auth token
download() {
  DEST=$1
  SOURCE=$2

  HEADER=""
  case $SOURCE in 
  https://api.github.com*)
     test -z "$GITHUB_TOKEN" || HEADER="Authorization: token $GITHUB_TOKEN"
     ;;
  esac

  if which curl > /dev/null; then
    WGET="curl -sSL"
    test -z "$GITHUB_TOKEN" || WGET="${WGET} -H \"${HEADER}\""
    if [ "${DEST}" != "-" ]; then
      WGET="$WGET -o $DEST"
    fi
  elif which wget > /dev/null; then
    WGET="wget -q -O $DEST"
    test -z "$GITHUB_TOKEN" || WGET="${WGET} --header \"${HEADER}\""
  else
    echo "Unable to find wget or curl.  Exit"
    exit 1
  fi

  ${WGET} ${SOURCE}
}

if [ "${VERSION}" = "latest" ]; then
  echo "Checking GitHub for latest version of ${OWNER}/${REPO}"
  VERSION=$(download - https://api.github.com/repos/${OWNER}/${REPO}/releases/latest | grep -m 1 "\"name\":" | cut -d ":" -f 2 | tr -d ' ",')
  if [ -z "${VERSION}" ]; then
    echo "Unable to determine latest release for ${OWNER}/${REPO}"
    exit 1
   fi
fi

VERSION=${VERSION#v}

OS=$(uname -s)
ARCH=$(uname -m)



if [ ! -z "${ARM}" ]; then ARM="v$ARM"; fi
NAME=${BINARY}_${OS}_${ARCH}${ARM}
TARBALL=${NAME}.${FORMAT}
URL=https://github.com/${OWNER}/${REPO}/releases/download/v${VERSION}/${TARBALL}

download ${TMPDIR}/${TARBALL} ${URL}
tar -C ${TMPDIR} -xzf ${TMPDIR}/${TARBALL}
install -d ${BINDIR}
install ${TMPDIR}/${BINARY} ${BINDIR}/

