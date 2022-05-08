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

#for ((i=1;i<=$maxSignUp;i++))
#do
#    node ./build/index.js signup -p $macipk
#done
#
#for ((ii=1;ii<=$maxSignUp;ii++))
#do
#    for ((n=$votePerUser;n>=1;n--)) 
#    do
#        weight=$((1 + $RANDOM % $creditPerVote))
#        voteID=$(($RANDOM % $maxVoteOption))
#        echo "** user-"$ii" v="$voteID" w="$weight" n="$n
#        node build/index.js publish -p $macipk -sk $macisk \
#        -i $ii -v $voteID -w $weight -n $n -o 0
#    done
#done
#
#
#sleep $duration

start=`date +%s`
node build/index.js mergeMessages -o 0 
end=`date +%s`
runtime=$((end-start))
echo "----------mergeMessages costs: "$runtime" seconds"

start=`date +%s`
node build/index.js mergeSignups -o 0 
end=`date +%s`
runtime=$((end-start))
echo "----------mergeSignups costs: "$runtime" seconds"

echo "gen proofs..."
start=`date +%s`
rm -rf proofs subsidy.json tally.json && \
node build/index.js genProofs \
    -sk macisk.49953af3585856f539d194b46c82f4ed54ec508fb9b882940cbe68bbc57e59e \
    -o 0 \
    -r ~/rapidsnark/build/prover \
    -wp /data/ProcessMessages_"$stateTreeDepth"-"$msgTreeDepth"-"$msgBatchDepth"-"$voteOptionTreeDepth"_test \
    -wt /data/TallyVotes_"$stateTreeDepth"-"$intStateTreeDepth"-"$voteOptionTreeDepth"_test \
    -ws /data/SubsidyPerBatch_"$stateTreeDepth"-"$intStateTreeDepth"-"$voteOptionTreeDepth"_test \
    -zp /data/ProcessMessages_"$stateTreeDepth"-"$msgTreeDepth"-"$msgBatchDepth"-"$voteOptionTreeDepth"_test.0.zkey \
    -zt /data/TallyVotes_"$stateTreeDepth"-"$intStateTreeDepth"-"$voteOptionTreeDepth"_test.0.zkey  \
    -zs /data/SubsidyPerBatch_"$stateTreeDepth"-"$intStateTreeDepth"-"$voteOptionTreeDepth"_test.0.zkey \
    -t tally.json \
    -sf subsidy.json \
    -f proofs/
end=`date +%s`
runtime=$((end-start))
echo "---------gen proof costs: "$runtime" seconds"

echo "prove on chain ..."
start=`date +%s`
node build/index.js proveOnChain \
    -o 0 \
    -f proofs/
end=`date +%s`
runtime=$((end-start))
echo "----------prove on chain costs: "$runtime" seconds"

echo "verify on chain ..."
start=`date +%s`
node build/index.js verify \
    -o 0 \
    -t tally.json \
    -sf subsidy.json
end=`date +%s`
runtime=$((end-start))
echo "----------verify on chain costs: "$runtime" seconds"

