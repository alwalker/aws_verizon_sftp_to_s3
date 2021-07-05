BUCKET1="s3://shots.media.noahlytics.com"
BUCKET2="s3://noah-player-tracking-east1"

logger  -t SFTP2S3 "Uploading $1 to s3..."

if [[ $1 =~ ([a-zA-Z0-9]{8}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{12})\.(timestamp.yaml|finished.myext) ]]; then
    logger  -t SFTP2S3 "Uploading $1 to $BUCKET2"

    /usr/local/bin/aws s3 cp $1 $BUCKET2/${BASH_REMATCH[1]}/${BASH_REMATCH[2]} --region us-west-2
    if [ \$? -ne 0 ]; then
        logger  -t SFTP2S3 'Failed to upload to s3!'
        exit 1
    fi
else
    logger  -t SFTP2S3 "Uploading $1 to $BUCKET1..."

    /usr/local/bin/aws s3 cp $1 $BUCKET1 --region us-west-2
    if [ \$? -ne 0 ]; then
        logger  -t SFTP2S3 'Failed to upload to s3!'
        exit 1
    fi
fi

rm $1
if [ \$? -ne 0 ]; then 
    logger -t SFTP2S3 'Failed to delete uploaded file!'
    exit 1 
fi 
logger  -t SFTP2S3 "Done" 