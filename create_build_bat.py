import sys

SHA = sys.argv[1]
BRANCH = sys.argv[2]

PYV = ["3.9.13", "3.10.10", "3.11.8", "3.12.1"]

BIT = ["32", "64"]
ARCH = ["x86", "x64"]
ARCH2 = ["x86", "amd64"]

for b, a, p in zip(BIT, ARCH, ARCH2):

    print(fr"set VS_HOST=x64")
    print(fr"cd %USERPROFILE%")
    print(fr"if not exist IfcOpenShell_{b} (")
    print(fr"  git clone --recursive https://github.com/IfcOpenShell/IfcOpenShell IfcOpenShell_{b} --branch {BRANCH}")
    print(fr")")
    print(fr"cd IfcOpenShell_{b}\win")
    print(fr"git checkout {SHA}")
    print(fr'call "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvars32.bat" {p}')
    print(fr'set IFCOS_INSTALL_PYTHON=FALSE')
    print(fr'echo y | call build-deps.cmd vs2017-{a} Release')
    
    for py in PYV:
    
        py2 = "".join(py.split(".")[0:2])
    
        print(fr"set PYTHONHOME=C:\Python\{b}\{py}")
        print(fr"set PY_VER_MAJOR_MINOR={py2}")
        print(fr'call run-cmake.bat vs2017-{a} -DENABLE_BUILD_OPTIMIZATIONS=On -DGLTF_SUPPORT=ON -DADD_COMMIT_SHA=ON -DVERSION_OVERRIDE=ON "-DGIT_EXECUTABLE=C:/Program Files/Git/bin/git.exe"')
        print(fr"call install-ifcopenshell.bat vs2017-{a} Release")
