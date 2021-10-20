dir=tmp_`date +%Y%m%d`_${branch:-v0.6.0}
[ -d $dir ] || git clone https://$GIT_USER:$GIT_PASS@github.com/$GIT_USER/IfcOpenShell $dir &> /dev/null
cd $dir
# git pull https://github.com/IfcOpenShell/IfcOpenShell master
# git push
git checkout ${branch:-v0.6.0} &> /dev/null
git pull https://github.com/IfcOpenShell/IfcOpenShell ${branch:-v0.6.0} &> /dev/null
git push &> /dev/null
git rev-parse HEAD
cd ..
rm -rf $dir
