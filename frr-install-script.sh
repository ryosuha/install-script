#!/bin/bash
set -e

install_ubuntu2204() {
    apt-get update
    apt-get install -y git autoconf automake libtool make libreadline-dev texinfo pkg-config libpam0g-dev libjson-c-dev bison flex libc-ares-dev python3-dev python3-sphinx install-info build-essential libsnmp-dev perl libcap-dev python2 libelf-dev libunwind-dev

    apt-get install -y protobuf-c-compiler libprotobuf-c-dev
    apt-get install -y libzmq5 libzmq3-dev
    apt-get install -y python-is-python3

    curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
    python2 ./get-pip.py

    sudo apt-get install -y libyang2-dev

    groupadd -r -g 92 frr
    groupadd -r -g 85 frrvty
    adduser --system --ingroup frr --home /var/run/frr/ --gecos "FRR suite" --shell /sbin/nologin frr
    usermod -a -G frrvty frr

    git clone https://github.com/frrouting/frr.git frr
    cd frr
    ./bootstrap.sh
    ./configure \
        --prefix=/usr \
        --includedir=\${prefix}/include \
        --bindir=\${prefix}/bin \
        --sbindir=\${prefix}/lib/frr \
        --libdir=\${prefix}/lib/frr \
        --libexecdir=\${prefix}/lib/frr \
        --localstatedir=/var/run/frr \
        --sysconfdir=/etc/frr \
        --with-moduledir=\${prefix}/lib/frr/modules \
        --with-libyang-pluginsdir=\${prefix}/lib/frr/libyang_plugins \
        --enable-configfile-mask=0640 \
        --enable-logfile-mask=0640 \
        --enable-snmp=agentx \
        --enable-multipath=64 \
        --enable-user=frr \
        --enable-group=frr \
        --enable-vty-group=frrvty \
        --with-pkg-git-version \
        --with-pkg-extra-version=-MyOwnFRRVersion
    make
    make install

    install -m 775 -o frr -g frr -d /var/log/frr
    install -m 775 -o frr -g frrvty -d /etc/frr
    install -m 640 -o frr -g frrvty tools/etc/frr/vtysh.conf /etc/frr/vtysh.conf
    install -m 640 -o frr -g frr tools/etc/frr/frr.conf /etc/frr/frr.conf
    install -m 640 -o frr -g frr tools/etc/frr/daemons.conf /etc/frr/daemons.conf
    install -m 640 -o frr -g frr tools/etc/frr/daemons /etc/frr/daemons

    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
    sysctl -p

    echo 'mpls_router' >> /etc/modules-load.d/modules.conf
    echo 'mmpls_iptunnels' >> /etc/modules-load.d/modules.conf
    modprobe mpls-router mpls-iptunnel

    #enabling mpls on interface
    list=`ip link | awk -F'[:]' '{print $2}' | grep ens`
    ens=`echo $list | tr -s " "`
    for arg in $ens
    do
        echo 'net.mpls.conf.'$arg'.input=1' >> /etc/sysctl.conf
    done

    echo 'net.mpls.platform_labels=100000' >> /etc/sysctl.conf

    pwd=`pwd`
    install -m 644 $pwd/tools/frr.service /etc/systemd/system/frr.service
    systemctl enable frr

    sed -i 's/=no/=yes/' /etc/frr/daemons

    systemctl start frr
}

install_ubuntu2004() {
    apt-get update
    apt-get install -y git autoconf automake libtool make libreadline-dev texinfo pkg-config libpam0g-dev libjson-c-dev bison flex libc-ares-dev python3-dev python3-sphinx install-info build-essential libsnmp-dev perl libcap-dev python2 libelf-dev libunwind-dev

    apt-get install -y protobuf-c-compiler libprotobuf-c-dev
    apt-get install -y libzmq5 libzmq3-dev
    apt-get install -y python-is-python3

    curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
    python2 ./get-pip.py

    curl https://ci1.netdef.org/artifact/LIBYANG-LIBYANGV2/shared/build-5/Ubuntu-20.04-x86_64-Packages/libyang2_2.0.7-1~ubuntu20.04u1_amd64.deb --output libyang2_2.0.7-1~ubuntu20.04u1_amd64.deb
    apt install -y ./libyang2_2.0.7-1~ubuntu20.04u1_amd64.deb
    
    curl https://ci1.netdef.org/artifact/LIBYANG-LIBYANGV2/shared/build-5/Ubuntu-20.04-x86_64-Packages/libyang2-dev_2.0.7-1~ubuntu20.04u1_amd64.deb  --output libyang2-dev_2.0.7-1~ubuntu20.04u1_amd64.deb
    apt install -y ./libyang2-dev_2.0.7-1~ubuntu20.04u1_amd64.deb

    groupadd -r -g 92 frr
    groupadd -r -g 85 frrvty
    adduser --system --ingroup frr --home /var/run/frr/ --gecos "FRR suite" --shell /sbin/nologin frr
    usermod -a -G frrvty frr

    git clone https://github.com/frrouting/frr.git frr
    cd frr
    ./bootstrap.sh
    ./configure \
        --prefix=/usr \
        --includedir=\${prefix}/include \
        --bindir=\${prefix}/bin \
        --sbindir=\${prefix}/lib/frr \
        --libdir=\${prefix}/lib/frr \
        --libexecdir=\${prefix}/lib/frr \
        --localstatedir=/var/run/frr \
        --sysconfdir=/etc/frr \
        --with-moduledir=\${prefix}/lib/frr/modules \
        --with-libyang-pluginsdir=\${prefix}/lib/frr/libyang_plugins \
        --enable-configfile-mask=0640 \
        --enable-logfile-mask=0640 \
        --enable-snmp=agentx \
        --enable-multipath=64 \
        --enable-user=frr \
        --enable-group=frr \
        --enable-vty-group=frrvty \
        --with-pkg-git-version \
        --with-pkg-extra-version=-MyOwnFRRVersion
    make
    make install

    install -m 775 -o frr -g frr -d /var/log/frr
    install -m 775 -o frr -g frrvty -d /etc/frr
    install -m 640 -o frr -g frrvty tools/etc/frr/vtysh.conf /etc/frr/vtysh.conf
    install -m 640 -o frr -g frr tools/etc/frr/frr.conf /etc/frr/frr.conf
    install -m 640 -o frr -g frr tools/etc/frr/daemons.conf /etc/frr/daemons.conf
    install -m 640 -o frr -g frr tools/etc/frr/daemons /etc/frr/daemons

    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
    sysctl -p

    echo 'mpls_router' >> /etc/modules-load.d/modules.conf
    echo 'mmpls_iptunnels' >> /etc/modules-load.d/modules.conf
    modprobe mpls-router mpls-iptunnel

    #enabling mpls on interface
    list=`ip link | awk -F'[:]' '{print $2}' | grep ens`
    ens=`echo $list | tr -s " "`
    for arg in $ens
    do
        echo 'net.mpls.conf.'$arg'.input=1' >> /etc/sysctl.conf
    done

    echo 'net.mpls.platform_labels=100000' >> /etc/sysctl.conf

    pwd=`pwd`
    install -m 644 $pwd/tools/frr.service /etc/systemd/system/frr.service
    systemctl enable frr

    sed -i 's/=no/=yes/' /etc/frr/daemons

    systemctl start frr
}

if ! [ $(id -u) = 0 ]; then
   echo "The script need to be run as root." >&2
   echo "Sample sudo ./frr-install-script.sh" >&2
   exit 1
fi

if [ ${SUDO_USER} ]; then
  echo ${SUDO_USER}
else
  echo "Run from Root User? Prefer to run from normal user with sudo command" >&2
  echo "Sample sudo ./frr-install-script.sh" >&2
  exit 1
fi

OS=`lsb_release -i | awk -F':' '{print $2}' | sed -e "s/\s//g"`
VERSION=`lsb_release -r | awk -F':' '{print $2}' | sed -e "s/\s//g"`

echo $OS
echo $VERSION

case ${OS} in
  "Ubuntu")
    case ${VERSION} in
      "22.04")
        install_ubuntu2204
        ;;
      "20.04")
        install_ubuntu2004
        ;;
      "18.04")
        #install_ubuntu1804
        echo "1804 Not Supported Yet"
        ;;
      *)
        echo "NO VERSION MATCH"
        ;;
    esac
    ;;
  *)
    echo "NO OS MATCH"
    ;;
esac
