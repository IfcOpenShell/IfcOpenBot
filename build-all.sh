source ./secrets.sh

if [ `aws ec2 describe-images --image-ids ${WINDOWS_AMI} | jq '.Images | length'` == "0" ]; then
echo "Windows AMI ${WINDOWS_AMI} not available"
exit 1
fi

if [ `aws ec2 describe-images --image-ids ${LINUX_AMI} | jq '.Images | length'` == "0" ]; then
echo "Linux AMI ${LINUX_AMI} not available"
exit 1
fi

mkdir -p logs output uploaded

sha=$(./sync.sh)
now=$(date +%Y-%m-%d_%H.%M.%S)

#@todo catching all exit codes is tedious have the build script write to some file at the end to verify success?

if [[ "$branch" != "v0.7.0" && "$branch" != "v0.8.0" ]]; then
./nix.sh 32 ${sha} ${branch:-v0.6.0} &> logs/${branch:-v0.6.0}_${sha:0:7}_linux_32_${now}.log &
fi

./nix.sh 64 ${sha} ${branch:-v0.6.0} &> logs/${branch:-v0.6.0}_${sha:0:7}_linux_64_${now}.log &

./nix.sh osx ${sha} ${branch:-v0.6.0} &> logs/${branch:-v0.6.0}_${sha:0:7}_osx_${now}.log &

ARCH=m1 ./nix.sh osx ${sha} ${branch:-v0.6.0} &> logs/${branch:-v0.6.0}_${sha:0:7}_osx_m1_${now}.log &

./windows.sh ${sha} ${branch:-v0.6.0} &> logs/${branch:-v0.6.0}_${sha:0:7}_windows_${now}.log &

wait

sleep 60

python3 upload.py ${sha}
