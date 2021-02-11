source ./secrets.sh

mkdir -p logs output uploaded

sha=$(./sync.sh)
now=$(date +%Y-%m-%d_%H.%M.%S)

#@todo catching all exit codes is tedious have the build script write to some file at the end to verify success?
./nix.sh 32 ${sha} v0.6.0 &> logs/linux_32_${now}.log &
./nix.sh 64 ${sha} v0.6.0 &> logs/linux_64_${now}.log &
./nix.sh osx ${sha} v0.6.0 &> logs/osx_${now}.log &
./windows.sh ${sha} v0.6.0 &> logs/windows_${now}.log &

wait

sleep 60

python3 upload.py ${sha}
