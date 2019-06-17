DIR=$(cd "$(dirname "$0")"; pwd -P)

"$DIR"/../qserv-deploy.sh -d -C "$QSERV_CFG_DIR" /opt/bin/qserv-stop
