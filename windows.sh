set -ex

if [ -z "$3" ]; then

INSTANCE_ID=$(aws ec2 run-instances \
	--region us-east-2 \
	--image-id ${WINDOWS_AMI} \
	--instance-type t2.medium \
	--security-group-ids ${WINDOWS_SGROUP} \
	--key-name ${KEY_FILE} \
	--user-data file://windows_init.txt \
	--block-device-mapping DeviceName=/dev/sda1,Ebs={VolumeSize=200} \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=IfcOpenBot-windows}]' \
	\
	| jq --raw-output .Instances[].InstanceId)

echo INSTANCE_ID ${INSTANCE_ID}

sleep $((3600 * 3 / 2)) # 1.5h to stay within 2h of EC time, should be enough time for the installation to complete

aws ec2 stop-instances --instance-ids "$INSTANCE_ID"
aws ec2 wait instance-stopped --instance-ids "$INSTANCE_ID"
aws ec2 modify-instance-attribute \
	--instance-id "$INSTANCE_ID" \
        --instance-type "{\"Value\":\"t2.2xlarge\"}"
aws ec2 start-instances --instance-ids "$INSTANCE_ID"

else

INSTANCE_ID=$3

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

echo "Password"
PASS=$(aws ec2 get-password-data --instance-id ${INSTANCE_ID} --priv-launch-key ${KEY_FILE}.pem | jq --raw-output .PasswordData)
echo ${PASS}

echo "IP"
IP=$(aws ec2 describe-instances --filters Name=instance-id,Values=${INSTANCE_ID} | jq --raw-output .Reservations[].Instances[].PublicIpAddress)
echo ${IP}

echo "Username"
echo "Administrator"

while :
do
ansible all \
	--inventory=${IP}, \
	--extra-vars "ansible_user=Administrator ansible_password=${PASS} ansible_connection=winrm ansible_winrm_server_cert_validation=ignore" \
	-m win_ping

rc=$?
echo rc $rc
if [ $rc -eq 0 ]; then
    break
fi
done

python3 create_build_bat.py $1 > build.bat

# @todo is this still necessary? the winrm timeout has been increased
sleep 60

ansible-playbook win.yaml --extra-vars "ip=${IP} pass=${PASS} sha=$1 branch=$2" -vvv

unzip output/bundle.zip -d output
rm output/bundle.zip

sleep 60

aws ec2 terminate-instances --instance-ids ${INSTANCE_ID}
