#!/bin/bash
# benchmark test different params

stateTreeDepth=6
intStateTreeDepth=2
msgTreeDepth=8
voteOptionTreeDepth=3
msgBatchDepth=2


cordpk=macipk.c974f4f168b79727ac98bfd53a65ea0b4e45dc2552fe73df9f8b51ebb0930330 
cordsk=macisk.49953af3585856f539d194b46c82f4ed54ec508fb9b882940cbe68bbc57e59e 
macipk=macipk.3e7bb2d7f0a1b7e980f1b6f363d1e3b7a12b9ae354c2cd60a9cfa9fd12917391 
macisk=macisk.fd7aa614ec4a82716ffc219c24fd7e7b52a2b63b5afb17e81c22fe21515539c 

duration=120
#maxVoteOption=$((5 ** $voteOptionTreeDepth))
maxVoteOption=25
#maxMsg=$((5 ** $msgTreeDepth))
maxMsg=50

maxSignUp=6
votePerUser=2

maxCredit=9 
creditPerVote=$(($maxCredit / $votePerUser))

#start=`date +%s`
#npx zkey-manager compile -c zkeys.config.yml
#end=`date +%s`
#runtime=$((end-start))
#echo "---------compile circuit costs: "$runtime" seconds"
#start=`date +%s`
#npx zkey-manager downloadPtau -c zkeys.config.yml -nc
#end=`date +%s`
#runtime=$((end-start))
#echo "---------download ptau costs: "$runtime" seconds"
#start=`date +%s`
#npx zkey-manager genZkeys -c zkeys.config.yml
#end=`date +%s`
#runtime=$((end-start))
#echo "---------gen zkey costs: "$runtime" seconds"

node build/index.js deployVkRegistry && \
node build/index.js setVerifyingKeys -s $stateTreeDepth -i $intStateTreeDepth -m $msgTreeDepth -v $voteOptionTreeDepth -b $msgBatchDepth \
    -p ./zkeys/ProcessMessages_v2_"$stateTreeDepth"-"$msgTreeDepth"-"$msgBatchDepth"-"$voteOptionTreeDepth"_test.0.zkey 


node build/index.js create 
node ./build/index.js deployPoll \
    -pk $cordpk \
    -t $duration -g $maxMsg -mv $maxVoteOption -i $intStateTreeDepth -m $msgTreeDepth -v $voteOptionTreeDepth -b $msgBatchDepth 


for ((i=1;i<=$maxSignUp;i++))
do
    node ./build/index.js signup -p $macipk
done

for ((ii=1;ii<=$maxSignUp;ii++))
do
    for ((n=$votePerUser;n>=1;n--)) 
    do
        weight=$((1 + $RANDOM % $creditPerVote))
        voteID=$(($RANDOM % $maxVoteOption))
        echo "** user-"$ii" v="$voteID" w="$weight" n="$n
        node build/index.js publish -p $macipk -sk $macisk \
        -i $ii -v $voteID -w $weight -n $n -o 0
    done
done


node build/index.js timeTravel -s $duration

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


echo "gen circuitInputs..."
start=`date +%s`
rm -rf circuit_inputs && \
node build/index.js genCircuitInputs \
    -sk $cordsk \
    -o 0 \
    -f circuit_inputs/
end=`date +%s`
runtime=$((end-start))
echo "---------gen circuitInputs: "$runtime" seconds"

echo "gen proofs..."
start=`date +%s`
rm -rf proofs subsidy.json tally.json && \
node build/index.js genProofs \
    -sk $cordsk \
    -o 0 \
    -r ~/rapidsnark/build/prover \
    -wp ./zkeys/ProcessMessages_v2_"$stateTreeDepth"-"$msgTreeDepth"-"$msgBatchDepth"-"$voteOptionTreeDepth"_test \
    -zp ./zkeys/ProcessMessages_v2_"$stateTreeDepth"-"$msgTreeDepth"-"$msgBatchDepth"-"$voteOptionTreeDepth"_test.0.zkey \
    -f proofs/
end=`date +%s`
runtime=$((end-start))
echo "---------gen proof costs: "$runtime" seconds"

echo "prove on chain ..."
start=`date +%s`
node build/index.js proveOnChain \
    -o 0   \
    -f proofs/
end=`date +%s`
runtime=$((end-start))
echo "----------prove on chain costs: "$runtime" seconds"

