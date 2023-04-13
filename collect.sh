set -ex

# Disable the aliases from git bash that alter ls output
unalias -a

[ -d ~/output ] && rm -rf ~/output
mkdir ~/output

OS=win

for BIT in 32 64; do

cd ~/IfcOpenShell_$BIT

SHA=$1
branch=$2

ARCH=amd64
PY_ARCH=$ARCH
CMAKE_ARCH=x64
INSTALL_ARCH=x64

if [ "$BIT" == "32" ]; then
ARCH=x86
PY_ARCH=win32
CMAKE_ARCH=$ARCH
INSTALL_ARCH=Win32
fi

cd _installed-vs2017-$INSTALL_ARCH/bin
ls | while read exe; do
    7z a ${exe:0: -4}-${branch}-${SHA:0:7}-${OS}${BIT}.zip $exe
done
mv *.zip ~/output

ls /c/Python/$BIT | while read py_version; do
    numbers=`echo $py_version | grep -oE '[0-9]+\.[0-9]+' | tr -d '.'`
    py_version_major=python-${numbers}
    cd /c/Python/$BIT/$py_version/Lib/site-packages 

    # might install more python versions then actually being compiled for...
    [ -d ifcopenshell ] || continue

    [ -d ifcopenshell/__pycache__ ] && rm -rf ifcopenshell/__pycache__
    find ifcopenshell -name "*.pyc" -delete
    7z a ifcopenshell-${py_version_major}-${branch}-${SHA:0:7}-${OS}${BIT}.zip ifcopenshell
    mv *.zip ~/output
done

# temporary
# ls /c/Python/$BIT | sort | while read py_version; do
# ls /c/Python/$BIT | sort | tail -n 3 | while read py_version; do
# 
#     [ -d /c/Python/$BIT/$py_version/Lib/site-packages/ifcopenshell ] || break
# 
#     [ -d ~/blender ] && rm -rf ~/blender
#     mkdir ~/blender
#     cd ~/blender
#     
#     numbers=`echo $py_version | sed s/[^0-9]//g`
#     py_version_major=python-${numbers:0:2}
#     
#     cp -R ~/IfcOpenShell_$BIT/src/ifcblender/io_import_scene_ifc .
#     cp -R /c/Python/$BIT/$py_version/Lib/site-packages/ifcopenshell io_import_scene_ifc
#     7z a ifcblender-${py_version_major}-${branch}-${SHA:0:7}-${OS}${BIT}.zip io_import_scene_ifc
#     
#     mv *.zip ~/output
# 
# done 

done # for BIT ...
