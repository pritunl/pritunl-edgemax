#!/bin/bash
set -e

if [ $EUID != 0 ]; then
    sudo sh "$0" "$@"
    exit $?
fi

BUILD_NUM=`ls /var/www/htdocs/lib/ | sort -n | tail -1`
PROFILES_PATH="/config/pritunl"
LIB_DIR="/var/www/htdocs/lib/"$BUILD_NUM"/js"
PRITUNL_PATH=$LIB_DIR"/pritunl.js"
EDGE_PATH="/var/www/php/app/classes/api/edge.php"
EDGE_BAK_PATH="/var/www/php/app/classes/api/edge.php.bak"
FOOTER_PATH="/var/www/php/app/views/common/footer.php"
FOOTER_BAK_PATH="/var/www/php/app/views/common/footer.php.bak"

if [ "$1" == "remove" ]; then
    echo "Removing Pritunl EdgeMax Addon..."

    if [ -d $PROFILES_PATH ]; then
        echo "Removing profiles directory ${PROFILES_PATH}..."
        rm -rf $PROFILES_PATH
    fi

    if [ -f $PRITUNL_PATH ]; then
        echo "Removing ${PRITUNL_PATH}..."
        rm -f $PRITUNL_PATH
    fi

    if [ -f $EDGE_BAK_PATH ]; then
        echo "Restoring ${EDGE_BAK_PATH} to ${EDGE_PATH}..."
        mv -f $EDGE_BAK_PATH $EDGE_PATH
    fi

    if [ -f $FOOTER_BAK_PATH ]; then
        echo "Restoring ${FOOTER_BAK_PATH} to ${FOOTER_PATH}..."
        mv -f $FOOTER_BAK_PATH $FOOTER_PATH
    fi

    echo "Removal complete"
    exit
fi

echo "Installing Pritunl EdgeMax Addon..."
echo "To uninstall run: sh ${0} remove"

if [ ! -d $LIB_DIR ]; then
    echo "Expected directory ${LIB_DIR} does not exist, ensure you are using the latest version of EdgeMax. Please report issues to contact@pritunl.com"
    exit 1
fi

if [ ! -f $EDGE_BAK_PATH ]; then
    SUM=`md5sum ${EDGE_PATH} | awk '{ print $1 }'`
    if [ "$SUM" != "76e0d5f71d0a55a1eb302b0ae9da219f" ]; then
        echo "${EDGE_PATH} md5sum ${SUM} does not match, ensure you are using the latest version of EdgeMax. Please report issues to contact@pritunl.com"
        exit 1
    fi
fi

if [ ! -f $FOOTER_BAK_PATH ]; then
    SUM=`md5sum ${FOOTER_PATH} | awk '{ print $1 }'`
    if [ "$SUM" != "08ffb16467e8c3a8181dd61f93545d38" ]; then
        echo "${FOOTER_PATH} md5sum ${SUM} does not match, ensure you are using the latest version of EdgeMax. Please report issues to contact@pritunl.com"
        exit 1
    fi
fi

if [ ! -f $EDGE_BAK_PATH ]; then
    echo "Backing up ${EDGE_PATH} to ${EDGE_BAK_PATH}..."
    cp $EDGE_PATH $EDGE_BAK_PATH
fi

if [ ! -f $FOOTER_BAK_PATH ]; then
    echo "Backing up ${FOOTER_PATH} to ${FOOTER_BAK_PATH}..."
    cp $FOOTER_PATH $FOOTER_BAK_PATH
fi

echo "Creating profiles directory ${PROFILES_PATH}..."
mkdir -p $PROFILES_PATH
chmod 773 $PROFILES_PATH

echo "Installing ${PRITUNL_PATH}..."
cat > $PRITUNL_PATH <<- EOM
#<pritunl>
EOM

echo "Patching ${EDGE_PATH}..."
cat > $EDGE_PATH <<- EOM
#<edge>
EOM

echo "Patching ${FOOTER_PATH}..."
cat > $FOOTER_PATH <<- EOM
#<footer>
EOM

echo "Installation complete"
