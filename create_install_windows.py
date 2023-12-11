print("""<powershell>

iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
choco install -y git sed 7zip.install
choco install -y cmake.install --installargs '"ADD_CMAKE_TO_PATH=System"'
choco install visualstudio2017buildtools -y --package-parameters "--allWorkloads --includeRecommended --includeOptional --passive" --execution-timeout 7200

$url = "https://raw.githubusercontent.com/ansible/ansible/stable-2.12/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)

powershell.exe -ExecutionPolicy ByPass -File $file
""")

PYV = ["3.6.8", "3.7.9", "3.8.10", "3.9.13", "3.10.10", "3.11.7", "3.12.1"]

for v in PYV:

    for bit in ["32", "64"]:
        if tuple(map(int, v.split("."))) < (3,5):
            pf = ".amd64" if bit == "64" else ""
            print(r"""
$file = "python-%(v)s%(pf)s.msi"
$path = "$env:temp\$file"
$url = "https://www.python.org/ftp/python/%(v)s/$file"
(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $path)
Start-Sleep -Seconds 15
Start-Process -Wait -FilePath msiexec -ArgumentList /qn, /i, $path, TARGETDIR=C:\Python\%(bit)s\%(v)s
Start-Sleep -Seconds 45
""" % locals())
        else:
            pf = "-amd64" if bit == "64" else ""
            print(r"""
$file = "python-%(v)s%(pf)s.exe"
$path = "$env:temp\$file"
$url = "https://www.python.org/ftp/python/%(v)s/$file"
(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $path)
Start-Sleep -Seconds 15
Start-Process -Wait -FilePath $path -ArgumentList /quiet, InstallAllUsers=0, PrependPath=0, Include_test=0, TargetDir=C:\Python\%(bit)s\%(v)s
Start-Sleep -Seconds 45
""" % locals())

print("""
</powershell>
""")
