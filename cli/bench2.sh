#!/bin/bash
# benchmark test different params

stateTreeDepth=10
intStateTreeDepth=2
msgTreeDepth=10
voteOptionTreeDepth=4
msgBatchDepth=3


cordpk=macipk.c974f4f168b79727ac98bfd53a65ea0b4e45dc2552fe73df9f8b51ebb0930330 
cordsk=macisk.49953af3585856f539d194b46c82f4ed54ec508fb9b882940cbe68bbc57e59e 
macipk=macipk.3e7bb2d7f0a1b7e980f1b6f363d1e3b7a12b9ae354c2cd60a9cfa9fd12917391 
macisk=macisk.fd7aa614ec4a82716ffc219c24fd7e7b52a2b63b5afb17e81c22fe21515539c 

maxVoteOption=$((5 ** $voteOptionTreeDepth))
#maxMsg=$((5 ** $msgTreeDepth))
maxMsg=$((17 * 5 ** $msgBatchDepth)) # must divide msgBatchSize and larger than maxSignUp * votePerUser 

maxSignUp=1000
votePerUser=2

duration=$((7 * $maxSignUp * $votePerUser)) 

maxCredit=300 
maxCredit=9
creditPerVote=$(($maxCredit / $votePerUser))

#node build/index.js deployVkRegistry 
#sleep 10
#node build/index.js setVerifyingKeys -s $stateTreeDepth -i $intStateTreeDepth -m $msgTreeDepth -v $voteOptionTreeDepth -b $msgBatchDepth \
#    -p /data/ProcessMessages_"$stateTreeDepth"-"$msgTreeDepth"-"$msgBatchDepth"-"$voteOptionTreeDepth"_test.0.zkey \
#    -t /data/TallyVotes_"$stateTreeDepth"-"$intStateTreeDepth"-"$voteOptionTreeDepth"_test.0.zkey  \
#    -ss /data/SubsidyPerBatch_"$stateTreeDepth"-"$intStateTreeDepth"-"$voteOptionTreeDepth"_test.0.zkey 
#
#
#sleep 10
node build/index.js create 
sleep 10
node ./build/index.js deployPoll \
    -pk $cordpk \
    -t $duration -g $maxMsg -mv $maxVoteOption -i $intStateTreeDepth -m $msgTreeDepth -v $voteOptionTreeDepth -b $msgBatchDepth 


