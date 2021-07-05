set -e

#generate 500 files between 4 and 30 MB
for i in {1..500}
do
    SIZE=$(((4 + $RANDOM % 27) * 1000000))
    head -c $SIZE < /dev/urandom > files/$i
done

#generate 100 random intervals between 0 and 2 seconds
INTERVALS=()
for i in {1..500}
do
    INTERVAL=$(($RANDOM % 3))
    INTERVALS+=( $INTERVAL )
done

#for loop over files 
echo "" > sftp_results.txt
for i in {1..500}
do
    # sftp file
    echo "uploading $(ls -lh files/$i)" >> sftp_results.txt
    { time sftp -o PreferredAuthentications=publickey -i /home/noah/Desktop/sftp2s3-user noah-sftp@155.146.113.199:/noah/ <<< $"put files/$i" ; } 2>> sftp_results.txt
    echo "sleeping: ${INTERVALS[$(($i -1))]}" >> sftp_results.txt
    echo && echo >> sftp_results.txt
    sleep ${INTERVALS[$(($i -1))]}
done

#for loop over files 
echo "" > s3_results.txt
for i in {1..500}
do
    # aws s3 cp file
    { time aws s3 cp files/$i s3://shots.media.noahlytics.com ; } 2>> s3_results.txt
    sleep ${INTERVALS[$(($i -1))]}
done