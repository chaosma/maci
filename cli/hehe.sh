#!/bin/bash
# benchmark test different params

stateTreeDepth=10
intStateTreeDepth=3
msgTreeDepth=15
voteOptionTreeDepth=4
msgBatchDepth=5


cordpk=macipk.c974f4f168b79727ac98bfd53a65ea0b4e45dc2552fe73df9f8b51ebb0930330 
cordsk=macisk.49953af3585856f539d194b46c82f4ed54ec508fb9b882940cbe68bbc57e59e 
macipk=macipk.3e7bb2d7f0a1b7e980f1b6f363d1e3b7a12b9ae354c2cd60a9cfa9fd12917391 
macisk=macisk.fd7aa614ec4a82716ffc219c24fd7e7b52a2b63b5afb17e81c22fe21515539c 

duration=324000 # estimate 90 hours for 20k*8 msgs
maxVoteOption=$((5 ** $voteOptionTreeDepth))
maxMsg=160000

maxSignUp=20000
votePerUser=8

maxCredit=300 
creditPerVote=$(($maxCredit / $votePerUser))

start=`date +%s`
npx zkey-manager compile -c hehe.config.yml
end=`date +%s`
runtime=$((end-start))
echo "---------compile circuit costs: "$runtime" seconds"
#start=`date +%s`
#npx zkey-manager downloadPtau -c hehe.config.yml -nc
#end=`date +%s`
#runtime=$((end-start))
#echo "---------download ptau costs: "$runtime" seconds"
#start=`date +%s`
#npx zkey-manager genZkeys -c hehe.config.yml
#end=`date +%s`
#runtime=$((end-start))
#echo "---------gen zkey costs: "$runtime" seconds"
