#!/bin/bash
set -eu

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
sudo cat >/etc/apt/sources.list <<EOL0
deb http://mirrors.ustc.edu.cn/ubuntu-ports/ ${OSVER} main multiverse restricted universe
deb http://mirrors.ustc.edu.cn/ubuntu-ports/ ${OSVER}-backports main multiverse restricted universe
deb http://mirrors.ustc.edu.cn/ubuntu-ports/ ${OSVER}-proposed main multiverse restricted universe
deb http://mirrors.ustc.edu.cn/ubuntu-ports/ ${OSVER}-security main multiverse restricted universe
deb http://mirrors.ustc.edu.cn/ubuntu-ports/ ${OSVER}-updates main multiverse restricted universe
deb-src http://mirrors.ustc.edu.cn/ubuntu-ports/ ${OSVER} main multiverse restricted universe
deb-src http://mirrors.ustc.edu.cn/ubuntu-ports/ ${OSVER}-backports main multiverse restricted universe
deb-src http://mirrors.ustc.edu.cn/ubuntu-ports/ ${OSVER}-proposed main multiverse restricted universe
deb-src http://mirrors.ustc.edu.cn/ubuntu-ports/ ${OSVER}-security main multiverse restricted universe
deb-src http://mirrors.ustc.edu.cn/ubuntu-ports/ ${OSVER}-updates main multiverse restricted universe
EOL0

mkdir -p ~/.pip/
cat >~/.pip/pip.conf <<EOL
[global]
trusted-host =  mirrors.aliyun.com
index-url = http://mirrors.aliyun.com/pypi/simple
EOL

export LC_ALL=C
apt-get update
apt-get install -y gfortran cython 
apt-get install -y libprotobuf-dev libleveldb-dev libsnappy-dev libopencv-dev
apt-get install -y libhdf5-serial-dev protobuf-compiler git
apt-get install -y --no-install-recommends libboost-all-dev
apt-get install -y python-dev libgflags-dev libgoogle-glog-dev liblmdb-dev
apt-get install -y libatlas-base-dev python-skimage
apt-get install -y python-pip python-setuptools
easy_install pip
wget https://pypi.python.org/packages/e7/a8/7556133689add8d1a54c0b14aeff0acb03c64707ce100ecd53934da1aa13/pip-8.1.2.tar.gz
tar -xzvf pip-8.1.2.tar.gz
cd pip-8.1.2
python setup.py install
hash -r
cd ../
rm -f pip-8.1.2.tar.gz
pip install --upgrade pip
pip install ipython==5.3.0
pip install pyzmq jsonschema pillow numpy scipy jupyter pyyaml

if [ -d caffe ]; then
	rm -rf caffe
fi

if [ -d caffe-src ]; then
	cp -af caffe-src caffe
else
	git clone https://github.com/friendlyarm/caffe
fi

cd caffe
CAFFEPATH=$PWD

cp Makefile.config.example Makefile.config

sed -i -e "s/^# CPU_ONLY/CPU_ONLY/g" Makefile.config
sed -i -e "s/\(^INCLUDE_DIRS :=.*\).*/\1 \/usr\/include\/hdf5\/serial\//g" Makefile.config

if [ -d /usr/lib/aarch64-linux-gnu ]; then
    export ToolChainPath=aarch64-linux-gnu
else
    export ToolChainPath=arm-linux-gnueabihf
fi
sed -i -e "s/\(^LIBRARY_DIRS :=.*\).*/\1 \/usr\/lib\/${ToolChainPath}\/hdf5\/serial\//g" Makefile.config

export LC_ALL="en_US.UTF-8"
make -j4 all
make -j4 runtest

# make pycaffe
# if [ -z "$(grep "PYTHONPATH" ~/.bashrc)" ]; then
# 	echo "export PYTHONPATH=$CAFFEPATH/python:\$PYTHONPATH" >> ~/.bashrc
# fi
# ./scripts/download_model_binary.py models/bvlc_googlenet

echo ""
echo "Built Complete"
echo "--------------------------------------------"
echo "You may run a quick timing test use the following command:"
echo "cd $CAFFEPATH"
echo "sudo ./build/tools/caffe time --model=models/bvlc_alexnet/deploy.prototxt"
echo ""

