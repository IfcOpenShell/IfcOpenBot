source ./secrets.sh

mkdir -p logs output uploaded

sha=$(./sync.sh)
now=$(date +%Y-%m-%d_%H.%M.%S)

#@todo catching all exit codes is tedious have the build script write to some file at the end to verify success?
./nix.sh 32 ${sha} ${branch:-v0.6.0} &> logs/linux_32_${now}.log &
./nix.sh 64 ${sha} ${branch:-v0.6.0} &> logs/linux_64_${now}.log &
if [ "$branch" == "v0.6.0" ]; then
./nix.sh osx ${sha} ${branch:-v0.6.0} &> logs/osx_${now}.log &
fi
./windows.sh ${sha} ${branch:-v0.6.0} &> logs/windows_${now}.log &

wait

sleep 60

python3 upload.py ${sha}
