#!/bin/bash

echo "Upload Blockchain to S3"
cd ${database_path}
tar -czvf ${cardano_path}/db.tar.gz *
cd ${cardano_path}
aws s3 cp db.tar.gz s3://cardano-node/${network}/db.tar.gz
rm -Rf db.tar.gz