#!/bin/bash
set -eu
export LC_ALL=C

# Everything else needs to be run as root
if [ $(id -u) -ne 0 ]; then
    printf "Script must be run as root. Try 'sudo $0'\n"
    exit 1
fi

if [ -f /sys/devices/platform/board/info ]; then
        HARDWARE=`cat /sys/devices/platform/board/info | awk '/^Hardware/{print $3}'`
        PHYMEM=$(free|awk '/^Mem:/{print $2}')
        if [ $PHYMEM -gt 600000 ]; then
                echo "Memsize: $PHYMEM"     
        else
                if [ "x${HARDWARE}" = "xNANOPI2" -o "x${HARDWARE}" = "xNANOPI3" ]; then
                        echo "This script cannot finish on this board. a minimum 1G RAM is needed for compiling Caffe. "
                        exit 1
                fi
        fi
fi
OSVER=`lsb_release -c | awk '{print $2}'`

install_packages() {
    # 清华
    APTSERVER=mirrors.tuna.tsinghua.edu.cn

    # 科大
    # APTSERVER=mirrors.ustc.edu.cn

    OSVER=`lsb_release -c | awk '{print $2}'`
    sudo cat >/etc/apt/sources.list <<EOL0
deb http://${APTSERVER}/ubuntu-ports/ ${OSVER} main multiverse restricted universe
deb http://${APTSERVER}/ubuntu-ports/ ${OSVER}-backports main multiverse restricted universe
deb http://${APTSERVER}/ubuntu-ports/ ${OSVER}-proposed main multiverse restricted universe
deb http://${APTSERVER}/ubuntu-ports/ ${OSVER}-security main multiverse restricted universe
deb http://${APTSERVER}/ubuntu-ports/ ${OSVER}-updates main multiverse restricted universe
deb-src http://${APTSERVER}/ubuntu-ports/ ${OSVER} main multiverse restricted universe
deb-src http://${APTSERVER}/ubuntu-ports/ ${OSVER}-backports main multiverse restricted universe
deb-src http://${APTSERVER}/ubuntu-ports/ ${OSVER}-proposed main multiverse restricted universe
deb-src http://${APTSERVER}/ubuntu-ports/ ${OSVER}-security main multiverse restricted universe
deb-src http://${APTSERVER}/ubuntu-ports/ ${OSVER}-updates main multiverse restricted universe
EOL0

    apt-get update
    apt-get install -y gfortran cython 
    apt-get install -y libprotobuf-dev libleveldb-dev libsnappy-dev
    apt-get install -y libhdf5-serial-dev protobuf-compiler git
    apt-get install -y --no-install-recommends libboost-all-dev
    apt-get install -y libgflags-dev libgoogle-glog-dev liblmdb-dev
    apt-get install -y libatlas-base-dev
    apt-get install -y python3-pip python3-setuptools

    # python 3.5
    apt-get install -y python3-dev
    apt-get install -y python3-numpy python3-scipy python3-skimage

    pip3 install ipython -i https://pypi.tuna.tsinghua.edu.cn/simple
    pip3 install pyzmq -i https://pypi.tuna.tsinghua.edu.cn/simple
    pip3 install jsonschema -i https://pypi.tuna.tsinghua.edu.cn/simple
    pip3 install pillow -i https://pypi.tuna.tsinghua.edu.cn/simple
    pip3 install numpy -i https://pypi.tuna.tsinghua.edu.cn/simple
    pip3 install scipy -i https://pypi.tuna.tsinghua.edu.cn/simple
    pip3 install jupyter -i https://pypi.tuna.tsinghua.edu.cn/simple
    pip3 install pyyaml -i https://pypi.tuna.tsinghua.edu.cn/simple
}
install_packages

if [ -d caffe ]; then
	rm -rf caffe
fi

if [ -d caffe-src ]; then
	cp -af caffe-src caffe
else
	git clone https://github.com/friendlyarm/caffe
fi

cd caffe
git checkout 04ab089db018a292ae48d51732dd6c66766b36b6 -B build-for-friendlycore
CAFFEPATH=$PWD
cp ../Makefile.config.04ab089db018 Makefile.config
cp ../Makefile.04ab089db018 Makefile

if [ -d /usr/lib/aarch64-linux-gnu ]; then
    export ToolChainPath=aarch64-linux-gnu
else
    export ToolChainPath=arm-linux-gnueabihf
fi

if [ x${OSVER} = x"xenial" ]; then
    # fix hdf5 issue
    if [ -d /usr/lib/aarch64-linux-gnu ]; then
        [ -e /usr/lib/aarch64-linux-gnu/libhdf5.so ] || {
            (cd /usr/lib/aarch64-linux-gnu/ && {
                ln -s libhdf5_serial.so.10.1.0 libhdf5.so
            })
        }
        [ -e /usr/lib/aarch64-linux-gnu/libhdf5_hl.so ] || {
            (cd /usr/lib/aarch64-linux-gnu/ && {
                ln -s libhdf5_serial_hl.so.10.0.2 libhdf5_hl.so
            })
        }
        [ -e /usr/lib/aarch64-linux-gnu/libboost_python3.so ] || {
            (cd /usr/lib/aarch64-linux-gnu/ && {
                ln -s libboost_python-py35.so libboost_python3.so
            })
        }
    else
        [ -e /usr/lib/arm-linux-gnueabihf/libhdf5.so ] || {
            (cd /usr/lib/arm-linux-gnueabihf/ && {
                ln -s libhdf5_serial.so.10.1.0 libhdf5.so
            })
        }
        [ -e /usr/lib/arm-linux-gnueabihf/libboost_python3.so ] || {
            (cd /usr/lib/arm-linux-gnueabihf/ && {
                ln -s libboost_python-py35.so libboost_python3.so
            })
        }
    fi
fi

export LC_ALL="en_US.UTF-8"
make -j4 all
make -j4 runtest

echo ""
echo "Built Complete"
echo "--------------------------------------------"
echo "You may run a quick timing test use the following command:"
echo "cd $CAFFEPATH"
echo "sudo ./build/tools/caffe time --model=models/bvlc_alexnet/deploy.prototxt"
echo ""

