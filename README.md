## Installing Caffe on FriendlyCore (base on Ubuntu 16.04)
The easiest way to install it is to run FriendlyELEC's script.

## Currently supported boards
* S5P6818
NanoPC T3/T3 Plus  
NanoPi Fire3  
Smart6818  
NanoPi M3  
* S5P4418
NanoPC T2 Plus  
NanoPi Fire2a  
Smart4418  
NanoPi S2  
NanoPi M2/M2a  

## Installation
***Note: Requires latest version of FriendlyCore firmware (Version after 20191126),   
Please download the latest FriendlyCore Image file from the following URL: http://download.friendlyarm.com***

```
git clone https://github.com/friendlyarm/install-caffe-on-friendlycore
cd install-caffe-on-friendlycore
sudo ./install-caffe.sh
```
  
After successful installation, you will see the following text:
```
[  PASSED  ] 1058 tests.

Built Complete
--------------------------------------------
You may run a quick timing test use the following command:
cd /home/pi/install-caffe-on-friendlycore/caffe
sudo ./build/tools/caffe time --model=models/bvlc_alexnet/deploy.prototxt
```