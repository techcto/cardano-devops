#!/usr/bin/env bash
DEPLOY=1
DATE=$(date +%d%H%M)

aws s3 cp cardano-node.testnet.json s3://build-secure/params/cardano-node.testnet.json
aws s3 cp deploy.yaml s3://cardano-node/cloudformation/deploy.yaml
aws s3 cp service.yaml s3://cardano-node/cloudformation/service.yaml

if [ $DEPLOY == 1 ]; then
    # echo "Create Cardano Node for Testnet"
    # aws cloudformation create-stack --disable-rollback --stack-name cardano-testnet-${DATE} --disable-rollback --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    #     --parameters file://cardano-node.testnet.json \
    #     --template-url https://s3.amazonaws.com/cardano-node/cloudformation/deploy.yaml \
    #     --notification-arns $NOTIFICATION_ARN
    
    # # TradeCartel.net
    # aws s3 cp cardano-node.mainnet.json s3://build-secure/params/cardano-node.mainnet.json
    # export AWS_PROFILE=tradecartel
    # echo "Create Cardano Node for Mainnet"
    # aws cloudformation create-stack --disable-rollback --stack-name cardano-us-east-1 --disable-rollback --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    #     --parameters file://cardano-node.mainnet.json \
    #     --template-url https://s3.amazonaws.com/cardano-node/cloudformation/deploy.yaml \
    #     --notification-arns $NOTIFICATION_ARN

    # # TradeCartel.net Ohio
    # aws s3 cp cardano-node.mainnet.us-east-2.json s3://build-secure/params/cardano-node.mainnet.us-east-2.json
    # export AWS_PROFILE=tradecartel
    # echo "Create Cardano Node for Mainnet"
    # aws cloudformation create-stack --region us-east-2 --disable-rollback --stack-name cardano-us-east-2l --disable-rollback --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    #     --parameters file://cardano-node.mainnet.us-east-2.json \
    #     --template-url https://s3.amazonaws.com/cardano-node/cloudformation/deploy.yaml \
    #     --notification-arns $NOTIFICATION_ARN

    # TradeCartel.net Paris
    aws s3 cp cardano-node.mainnet.eu-paris.json s3://build-secure/params/cardano-node.mainnet.eu-paris.json
    export AWS_PROFILE=tradecartel
    echo "Cardano Node Paris: Mainnet"
    aws cloudformation create-stack --region eu-west-3 --disable-rollback --stack-name cardano-paris-8 --disable-rollback --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
        --parameters file://cardano-node.mainnet.eu-paris.json \
        --template-url https://s3.amazonaws.com/cardano-node/cloudformation/deploy.yaml \
        --notification-arns $NOTIFICATION_ARN
fi