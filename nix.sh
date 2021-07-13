set -ex

if ! [[ "$1" =~ ^(32|64|osx)$ ]]; then exit 1 ; fi
if [ ${#2} -ne 40 ]; then exit 1; fi
# if ! [[ "$3" =~ ^v0.6.0$ ]]; then exit 1 ; fi

if [ $1 == osx ]; then

SSH_HOST=${OSX_SSH_HOST}
SSH="ssh -o StrictHostKeyChecking=no -i ${KEY_FILE}.pem ${SSH_HOST} /bin/bash --login"

else

if [ -z "$4" ]; then

INSTANCE_ID=$(aws ec2 run-instances \
	--region us-east-2 \
	--image-id ${LINUX_AMI} \
	--instance-type t3.2xlarge \
	--security-group-ids ${LINUX_SGROUP} \
	--key-name ${KEY_FILE} \
	--block-device-mapping DeviceName=/dev/sda1,Ebs={VolumeSize=100} \
	--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=IfcOpenBot-linux$1}]" \
	\
	| jq --raw-output .Instances[].InstanceId)

echo INSTANCE_ID ${INSTANCE_ID}

else

INSTANCE_ID=$4

fi

while :
do
echo "Waiting for OK"
aws ec2 wait instance-status-ok --instance-ids ${INSTANCE_ID}
rc=$?
echo rc $rc
if [ $rc -eq 0 ]; then
    break
fi
done

echo "IP"
IP=$(aws ec2 describe-instances --filters Name=instance-id,Values=${INSTANCE_ID} | jq --raw-output .Reservations[].Instances[].PublicIpAddress)
echo ${IP}

SSH_HOST=ubuntu@${IP}
SSH="ssh -o StrictHostKeyChecking=no -i ${KEY_FILE}.pem ${SSH_HOST} /bin/bash --login"

printf "
set -ex

if [ \"$1\" == \"32\" ]; then
arch=:i386
sudo dpkg --add-architecture i386
sudo apt-get update && sudo apt-get install -y gcc-multilib g++-multilib
else
sudo apt-get update && sudo apt-get install -y gcc g++
fi

# binaries
sudo apt-get install -y git autoconf bison make zip cmake \`apt-cache search --names-only 'python2?-minimal' | awk '{print \$1}'\`

# ifcopenshell dependencies
sudo apt-get install -y libc6-dev\${arch} libfreetype6-dev\${arch} mesa-common-dev\${arch} libffi-dev\${arch} libfontconfig1-dev\${arch}

# python dependencies
sudo apt-get install -y libsqlite3-dev\${arch} libbz2-dev\${arch} zlib1g-dev\${arch} libssl-dev\${arch} liblzma-dev\${arch}
sudo apt-get install -y libreadline-dev\${arch} libncursesw5-dev\${arch} libffi-dev\${arch} uuid-dev\${arch}

" | $SSH

fi

if [ ! -z "$5" ]; then

scp -i ${KEY_FILE}.pem "$5" $SSH_HOST:~/patch.patch

fi

[ "$1" == "32" ] && TARGET_ARCH=TARGET_ARCH=i686

printf '
set -ex

COMMIT_SHA=%s
branch=%s

export CXXFLAGS="-O3"
export CFLAGS="-O3"
cd ~
[ -d IfcOpenShell ] || git clone https://github.com/IfcOpenShell/IfcOpenShell --recursive
cd IfcOpenShell/nix

git reset --hard
[ -f ~/patch.patch ] && git apply ~/patch.patch
git fetch
git checkout $COMMIT_SHA

BUILD_CFG=Release CFLAGS="-O3" CXXFLAGS="-O3" '${TARGET_ARCH}' python2 build-all.py

' $2 $3 | $SSH

printf '
set -ex

SHA=%s
branch=%s

[ -d ~/output ] && rm -rf ~/output
mkdir ~/output

OS=linux
BIT='$1'
OSX_PLATFORM=
test "`uname`" = "Darwin" && OS=macos
test "`uname`" = "Darwin" && BIT=64
test "`uname`" = "Darwin" && OSX_PLATFORM=10.9/

cd ~/IfcOpenShell/build/`uname`/*/${OSX_PLATFORM}install/ifcopenshell

ls -d python-* | while read py_version; do
    postfix=`echo ${py_version: -1} | sed s/[0-9]//`
    numbers=`echo $py_version | sed s/[^0-9]//g`
    py_version_major=python-${numbers:0:2}$postfix
    pushd . > /dev/null
    cd $py_version
    if [ ! -d ifcopenshell ]; then
        mkdir ../ifcopenshell_
        mv * ../ifcopenshell_
        mv ../ifcopenshell_ ifcopenshell
    fi
    [ -d ifcopenshell/__pycache__ ] && rm -rf ifcopenshell/__pycache__
    find ifcopenshell -name "*.pyc" -delete
    zip -r -qq ifcopenshell-${py_version_major}-${branch}-${SHA:0:7}-${OS}${BIT}.zip ifcopenshell/*
    mv *.zip ~/output
    popd > /dev/null
done

cd bin
rm *.zip || true
ls | while read exe; do
    zip -qq -r ${exe}-${branch}-${SHA:0:7}-${OS}${BIT}.zip $exe
done
mv *.zip ~/output
cd ..

# Assume latest python version is used in Blender

ls -d python-* | sort | tail -n 3 | while read py_version; do

postfix=`echo ${py_version: -1} | sed s/[0-9]//`
numbers=`echo $py_version | sed s/[^0-9]//g`
py_version_major=python-${numbers:0:2}$postfix
[ -d blender ] && rm -rf blender
mkdir blender
cd blender
cp -R ~/IfcOpenShell/src/ifcblender/io_import_scene_ifc .
cp -R ../$py_version/ifcopenshell io_import_scene_ifc
rm *.zip || true
zip -r -qq ifcblender-${py_version_major}-${branch}-${SHA:0:7}-${OS}${BIT}.zip io_import_scene_ifc
mv *.zip ~/output
cd ..
rm -rf blender

done

' $2 $3 | $SSH

outputdir=output$(basename -- "$5")
mkdir -p "$outputdir"
scp -i ${KEY_FILE}.pem $SSH_HOST:~/output/*.zip "$outputdir"/

sleep 60

if [ $1 != osx ]; then
aws ec2 terminate-instances --instance-ids ${INSTANCE_ID}
fi
