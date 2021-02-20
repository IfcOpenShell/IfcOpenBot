for v in ["2.7.16", "3.2.5", "3.3.5", "3.4.4", "3.5.4", "3.6.8", "3.7.9", "3.8.6", "3.9.1"]:

    for bit in ["32", "64"]:
        if v < "3.5":
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
