#!/bin/bash
export AWS_PROFILE=default
berks package cookbooks.tar.gz
aws s3 cp cookbooks.tar.gz s3://cardano-node/chef/ --acl public-read
rm -Rf cookbooks.tar.gz