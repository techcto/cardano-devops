#!/bin/bash

source vars.sh
source transact.sh

#Get Rewards
export GETREWARDS=true
export PAYMENT=0
transact
unset POOLREFUND