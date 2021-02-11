import sys

SHA = sys.argv[1]
PYV = ["2.7.16", "3.2.5", "3.3.5", "3.4.4", "3.5.4", "3.6.8", "3.7.9", "3.8.6", "3.9.1"]
BIT = ["32", "64"]
ARCH = ["x86", "x64"]
ARCH2 = ["x86", "amd64"]

for b, a, p in zip(BIT, ARCH, ARCH2):
    
    print(fr"cd %USERPROFILE%")
    print(fr"git clone https://github.com/IfcOpenShell/IfcOpenShell IfcOpenShell_{b}")
    print(fr"cd IfcOpenShell_{b}\win")
    print(fr"git checkout {SHA}")
    print(fr'call "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvars32.bat" {p}')
    print(fr'set IFCOS_INSTALL_PYTHON=FALSE')
    print(fr'echo y | call build-deps.cmd vs2017-{a} Release')
    
    for py in PYV:
    
        py2 = py.replace(".", "")[0:2]
    
        print(fr"set PYTHONHOME=C:\Python\{b}\{py}")
        print(fr"set PY_VER_MAJOR_MINOR={py2}")
        print(fr"call run-cmake.bat vs2017-{a} -DENABLE_BUILD_OPTIMIZATIONS=On -DGLTF_SUPPORT=ON")
        print(fr"call install-ifcopenshell.bat vs2017-{a} Release")

