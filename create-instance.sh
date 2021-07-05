aws ec2 run-instances \
    --subnet-id subnet- \
    --key-name $KEY \
    --security-group-ids  \
    --iam-instance-profile Name=sftp2s3 \
    --instance-type t3.medium \
    --image-id ami- \
    --network-interfaces "AssociateCarrierIpAddress=true" \
    --dry-run