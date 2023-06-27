#!/bin/sh

# Download and run the latest release of kind-helper.

set -e

RELEASES_URL="https://github.com/k8s-school/kind-helper/releases"
FILE_BASENAME="kind-helper"
LATEST="$(curl -s https://api.github.com/repos/k8s-school/kind-helper/releases/latest | jq --raw-output '.tag_name')"

test -z "$VERSION" && VERSION="$LATEST"

test -z "$VERSION" && {
	echo "Unable to get kind-helper version." >&2
	exit 1
}

TMP_DIR="$(mktemp -d)"
# shellcheck disable=SC2064 # intentionally expands here
trap "rm -rf \"$TMP_DIR\"" EXIT INT TERM
OS="$(uname -s)"
ARCH="$(uname -m)"
test "$ARCH" = "aarch64" && ARCH="arm64"
TAR_FILE="${FILE_BASENAME}_${OS}_${ARCH}.tar.gz"

(
	cd "$TMP_DIR"
	echo "Downloading kind-helper $VERSION..."
	curl -sfLO "$RELEASES_URL/download/$VERSION/$TAR_FILE"
	curl -sfLO "$RELEASES_URL/download/$VERSION/checksums.txt"
	echo "Verifying checksums..."
	sha256sum --ignore-missing --quiet --check checksums.txt
	# TODO: verify signatures
	# if command -v cosign >/dev/null 2>&1; then
	# 	echo "Verifying signatures..."
	# 	cosign verify-blob \
	# 		--certificate-identity-regexp "https://github.com/goreleaser/goreleaser.*/.github/workflows/.*.yml@refs/tags/$VERSION" \
	# 		--certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
	# 		--cert "$RELEASES_URL/download/$VERSION/checksums.txt.pem" \
	# 		--signature "$RELEASES_URL/download/$VERSION/checksums.txt.sig" \
	# 		checksums.txt
	# else
	# 	echo "Could not verify signatures, cosign is not installed."
	# fi
)

tar -xf "$TMP_DIR/$TAR_FILE" -C "$TMP_DIR"
echo "$TMP_DIR/kind-helper"
