# Run this script as an admin user (having 'sudo' privileges)
#  = 'admin' on debian, 'ubuntu' on ubuntu

# Depending on how the target host is set up, a password might be
# required in order to perform some of these functions. We try to
# ensure that even if a password is needed the first time around, it
# won't be needed the second and following times.

set -e
# Current directory = home dir for admin user

OPENTREE_HOST=$1
OPENTREE_USER=$2
CERTIFICATE_FILE=$3
CERTIFICATE_KEY_FILE=$4

if [ x$OPENTREE_USER = x ]; then
    OPENTREE_USER=opentree
fi

if ! sudo test -r "$CERTIFICATE_FILE"; then
    echo "** Missing "$CERTIFICATE_FILE" - must be copied manually"
elif ! sudo test -r "$CERTIFICATE_KEY_FILE"; then
    echo "** Missing "$CERTIFICATE_KEY_FILE" - must be copied manually"
fi

APTGET="sudo apt-get -q --assume-yes --no-install-recommends"

function apt_get_install {
    if [ ! -r .updated ]; then
	$APTGET update
	touch .updated
    fi
    $APTGET install $*
}

function apt_get_install_one
{
    PKG=$1
    if ! dpkg -s "$PKG" >/dev/null 2>&1 ; then
	apt_get_install $PKG
    fi
}

# ---------- UPDATE ----------

if [ `which dialog`x = x ]; then
    # I was hoping this would help with apache2's configure step, but it doesn't
    apt_get_install dialog
fi

# ---------- RSYNC ----------
if [ `which rsync`x = x ]; then
    apt_get_install rsync
fi

# ---------- GCC (for some python packages) ----------
if [ `which gcc`x = x ]; then
    apt_get_install gcc
fi


# ---------- G++ (for NCL, the nexus, newick converter used by the curation tool's import) ----------
if [ `which g++`x = x ]; then
    apt_get_install g++
fi

# ---------- make (for NCL, the nexus, newick converter used by the curation tool's import) ----------
if [ `which make`x = x ]; then
    apt_get_install make
fi

# ---------- autoconf and automake for NCL (curation dependency) ----------
if [ `which autoconf`x = x ]; then
    apt_get_install autotools-dev
fi
# ---------- autoconf and automake for NCL (curation dependency) ----------
if [ `which automake`x = x ]; then
    apt_get_install automake
fi

# ---------- for taxonomy browser -------------
apt_get_install_one python-requests

# ---------- for otcetera  ----------------
apt_get_install_one libboost-dev
apt_get_install_one libboost-filesystem-dev
apt_get_install_one libboost-program-options-dev
apt_get_install_one libboost-system-dev
apt_get_install_one libtool
apt_get_install_one pkg-config
apt_get_install_one meson
apt_get_install_one psmisc # for killall

# ---------- for restbed (otcetera web services dependency) ----------
apt_get_install_one cmake
apt_get_install_one libssl-dev
apt_get_install_one libcurl4-openssl-dev

# ---------- for running otc-tol-ws ------------------
apt_get_install_one daemonize

# ---------- PYTHON-DEV (for some python packages) ----------
if [ ! -r /usr/include/*/Python.h ]; then
    apt_get_install python-dev
fi
# -----G++ (for NCL, the nexus, newick converter used by the curation tool's import) -----
if [ `which g++`x = x ]; then
    apt_get_install g++
fi
# ---------- autoconf and automake for NCL (curation dependency) ----------
if [ `which autoconf`x = x ]; then
    apt_get_install autotools-dev
fi
# ---------- autoconf and automake for NCL (curation dependency) ----------
if [ `which automake`x = x ]; then
    apt_get_install automake
fi


# ---------- APACHE ----------
if [ ! -r /etc/init.d/apache2 ]; then
    echo Installing apache httpd
    # Prompts "do you want to continue?"
    apt_get_install apache2
    echo Done
fi

# Enable the apache proxy module
if [ ! -r /etc/apache2/mods-enabled/proxy.load ]; then
    sudo a2enmod proxy
fi
if [ ! -r /etc/apache2/mods-enabled/proxy_http.load ]; then
    sudo a2enmod proxy_http
fi

# Rewrite module
if [ ! -r /etc/apache2/mods-enabled/rewrite.load ]; then
    sudo a2enmod rewrite
fi

# Enable the apache ssl module.  Doesn't get used unless a cert is present
if [ ! -r /etc/apache2/mods-enabled/ssl.load ]; then
    sudo a2enmod ssl
fi

# Enable the apache cgid. Used for the taxonomy browser
if [ ! -r /etc/apache2/mods-enabled/cgid.load ]; then
    sudo a2enmod cgid
fi


# ---------- UNZIP ----------
# unzip is needed for unpacking web2py.  Somebody broke the 'which' program -
# you can't just check the status code any more.
if [ `which unzip`x = x ]; then
    apt_get_install unzip
fi

# ---------- PIP ----------
# Get pip
if [ `which pip`x = x ]; then
    apt_get_install python-pip
fi

# ---------- LIBCURL + PYCURL ---------- 
# oti no longer uses this.
if false; then
    # only needed on debian, may cause problems on ubunutu
    # used by oti indexing script (make sure we have SSL support)
    if [ `which curl`x = x ] || [ `curl-config --feature | grep SSL`x = x ]; then
    #    sudo apt-cache search libcurl-dev
	apt_get_install libcurl4-openssl-dev
	# NOTE that we'll pip-install pycurl inside our venv (in index-doc-store.sh)
    fi
fi

# ---------- GIT ----------
# Get git (so we can clone the opentree repo)
if [ `which git`x = x ]; then
    apt_get_install git
fi

# ---------- WSGI ----------
# Get wsgi (apache / web2py communication)
if [ ! -r /etc/apache2/mods-enabled/wsgi.load ]; then
    apt_get_install libapache2-mod-wsgi
fi

# AWS has python 2.7.3 built in, no need to install it.

# ---------- PYTHON VIRTUALENV ----------
# Get virtualenv
if [ `which virtualenv`x = x ]; then
    apt_get_install python-virtualenv virtualenv
fi

# ---------- JAVA ----------
# N.b. Java 8 isn't available for woody, and is available for jessie
# only with the addition of unstable to /etc/apt/sources.list and a
# corresponding prioritization in /etc/apt/preferences (to prevent
# unstable from taking over the whole system).

if [ `which javac`x != x ] && ( javac -version 2>&1 | egrep -q 1.8 ); then
    echo "Java 8 OK"
elif apt-cache policy openjdk-8-jre-headless | grep -q "Installed.*none"; then
    apt_get_install openjdk-8-jre-headless
    apt_get_install openjdk-8-jdk
    sudo update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
    sudo update-alternatives --set javac /usr/lib/jvm/java-8-openjdk-amd64/bin/javac
elif [ `which javac`x != x ] && ( javac -version 2>&1 | egrep -q 1.7 ); then
    echo path is $PATH
    echo "Java 7 OK"
elif [ `which javac`x != x ]; then
    echo "** Possible wrong version of java"
else
    apt_get_install openjdk-7-jre-headless
    apt_get_install openjdk-7-jdk
fi

# ---------- MAVEN 3 ----------
if [ `which mvn`x = x ]; then
    apt_get_install maven
fi

# ---------- LSOF ----------
# neo4j needs this
if [ `which lsof`x = x ]; then
    apt_get_install lsof
fi

# ---------- NTP ----------
if [ ! -r /etc/ntp.conf ]; then
    apt_get_install ntp
fi


# ---------- APACHE VHOST ----------

# Set up apache so that web2py takes over the vhost

# How the apache config (the one found in the deployment setup
# directory) was created: we copied the apache default vhost config
# (000-default) from a fresh EC2 (woody) instance, then modified it to make
# web2py work, per instructions found on the web.  See
# /etc/apache2/sites-available/default .
# 
# After adding a second VirtualHost file for HTTPS, we moved all common
# configuration to a third file '{apache|opentree}-config-shared', which is
# used in both vhosts via the Include directive.

# The purpose of clobbering the default vhost is to avoid
# having to know all of our own vhost names.  Instead we make opentree
# the default 'vhost'.  The opentree vhost config files get put into
# place later on in the setup sequence (restart-apache.sh).

sudo rm -f /etc/apache2/sites-enabled/000-default*
sudo rm -f /etc/apache2/sites-enabled/000-opentree
sudo rm -f /etc/apache2/sites-enabled/001-opentree-ssl
if [ ! -e /etc/apache2/sites-enabled/000-opentree.conf ]; then
    (cd /etc/apache2/sites-enabled; \
     sudo ln -sf ../sites-available/opentree.conf ./000-opentree.conf)
fi

# Enable the HTTPS site only if our SSL certs are found; else disable it
# TBD: Make this work with letsencrypt
if sudo test -e "${CERTIFICATE_FILE}" ; then
    if sudo test -e "${CERTIFICATE_KEY_FILE}"; then

        # Create apache symlink first time
        if [ ! -r /etc/apache2/sites-enabled/001-opentree-ssl.conf ]; then
            (cd /etc/apache2/sites-enabled; \
             sudo ln -sf ../sites-available/opentree-ssl.conf ./001-opentree-ssl.conf)
        fi

        sudo chmod o-r "${CERTIFICATE_KEY_FILE}"
        if egrep -q ssl-cert /etc/group; then
            sudo chgrp ssl-cert "${CERTIFICATE_KEY_FILE}"
        fi
    else
        echo "Note: missing certificate file ${CERTIFICATE_KEY_FILE}.  Attempting non-ssl configuration"
        sudo rm -f /etc/apache2/sites-enabled/001-opentree-ssl.conf
    fi
else
    echo "Note: missing certificate file ${CERTIFICATE_FILE}.  Attempting non-ssl configuration"
    sudo rm -f /etc/apache2/sites-enabled/001-opentree-ssl.conf
fi

# Apache 2.4 is finicky about protection of the key file


# ---------- UNPRIVILEGED USER ----------

# Credit goes to Richard Bronosky via stackoverflow for this
OTHOME=$(bash <<< "echo ~$OPENTREE_USER")

if [ ! -e $OTHOME ]; then
    sudo useradd $OPENTREE_USER
    OTHOME=$(bash <<< "echo ~$OPENTREE_USER")
    sudo cp -pr /etc/skel $OTHOME
    sudo chown -R $OPENTREE_USER:$OPENTREE_USER $OTHOME
    sudo chmod g+sw $OTHOME
    sudo chsh -s /bin/bash $OPENTREE_USER
fi

if [ ! -e $OTHOME/.ssh ]; then
    sudo mkdir $OTHOME/.ssh
    sudo cp -p .ssh/authorized_keys $OTHOME/.ssh/
    sudo chmod 700 $OTHOME/.ssh/
    sudo chown -R $OPENTREE_USER:$OPENTREE_USER $OTHOME
fi

# Ideally stowing the hostname one would be done every time, but we
# want to avoid unsatisfiable sudo prompt demands, so let's assume it
# stays the same.
# TBD: this code ought to be done by the 'opentree' user, not in this file.
if [ x$OPENTREE_HOST != x -a ! -r $OTHOME/hostname ]; then
    HOSTFILE=$OTHOME/hostname
    cat <<EOF | sudo bash
	echo "$OPENTREE_HOST" >$HOSTFILE
	chmod go+r $HOSTFILE
	chown $OPENTREE_USER $HOSTFILE
EOF
fi
