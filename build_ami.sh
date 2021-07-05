#Update to CentOS Stream until they publish an AMI
dnf install -y centos-release-stream
dnf -y distro-sync

dnf install -y unzip #iperf3
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install

useradd user-sftp
mkdir /home/user-sftp/.ssh
cat << __FILE_CONTENTS__ > /home/user-sftp/.ssh/authorized_keys
ssh-rsa 
__FILE_CONTENTS__
chown -R user-sftp: /home/user-sftp/.ssh
chmod 700 /home/user-sftp/.ssh
chmod 600 /home/user-sftp/.ssh/authorized_keys

mkdir -p /var/sftp/noah
chown user-sftp: /var/sftp/noah
cat << __FILE_CONTENTS__ >> /etc/ssh/sshd_config

Match user user-sftp
        ChrootDirectory /var/sftp
        X11Forwarding no
        AllowTcpForwarding no
        ForceCommand internal-sftp
__FILE_CONTENTS__
systemctl restart sshd

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf install -y incron
systemctl start incrond
systemctl enable incrond
cat << __FILE_CONTENTS__ >> /etc/incron.conf
editor = vi
__FILE_CONTENTS__
cat > /usr/local/src/sftp2s3.sh <<__FILE_CONTENTS__ 
logger -t SFTP2S3 "Uploading \$1 to s3..."
/usr/local/bin/aws s3 cp \$1 s3://$YOUR_BUCKET --region us-west-2
if [ \$? -ne 0 ]; then
  logger  -t SFTP2S3 'Failed to upload to s3!'
  exit 1
fi
rm \$1
if [ \$? -ne 0 ]; then
  send_message -t SFTP2S3 'Failed to delete uploaded file!'
  exit 1
fi
logger -t SFTP2S3 "Done"
__FILE_CONTENTS__
echo '/var/sftp/noah IN_CREATE bash /usr/local/src/sftp2s3.sh $@/$#' | incrontab -u user-sftp -