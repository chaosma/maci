const fs = require('fs')
import * as ethers from 'ethers'
import * as prompt from 'prompt-sync'

prompt.colors = false
prompt.message = ''

import { SNARK_FIELD_SIZE } from 'maci-crypto'

import {
    MaciState,
} from 'maci-core'

import {
    PubKey,
    Keypair,
    Message,
    StateLeaf,
} from 'maci-domainobjs'

import {
    genJsonRpcDeployer,
    maciContractAbi,
} from 'maci-contracts'

/*
 * Retrieves and parses on-chain MACI contract data to create an off-chain
 * representation as a MaciState object.
 * @param provider An Ethereum provider
 * @param address The address of the MACI contract
 * @coordinatorKeypair The coordinator's keypair
 */
const genMaciStateFromContract = async (
    provider: ethers.providers.Provider,
    address: string,
    coordinatorKeypair: Keypair,
    zerothLeaf: StateLeaf,
    logData: any = {},
    processMessages = true,
) => {

    const maciContract = new ethers.Contract(
        address,
        maciContractAbi,
        provider,
    )

    const treeDepths = await maciContract.treeDepths()
    const stateTreeDepth = BigInt(treeDepths[0].toString())
    const messageTreeDepth = BigInt(treeDepths[1].toString())
    const voteOptionTreeDepth = BigInt(treeDepths[2].toString())
    const maxVoteOptionIndex = BigInt((
            await maciContract.voteOptionsMaxLeafIndex()
        ).toString())

    const maciState = new MaciState(
        coordinatorKeypair,
        stateTreeDepth,
        messageTreeDepth,
        voteOptionTreeDepth,
        maxVoteOptionIndex,
    )

    if (Object.keys(logData).length > 0) {
        const signUpLogs = logData.signUpLogs
        const publishMessageLogs = logData.publishMessageLogs

        let i = 0
        for (const log of signUpLogs) {
            if (i % 2000 === 0) {
                console.log(`${i} / ${signUpLogs.length}`)
            }
            const voiceCreditBalance = BigInt(log.voiceCreditBalance)
            const pubKey = new PubKey([
                BigInt(log.pubKey[0]),
                BigInt(log.pubKey[1]),
            ])

            maciState.signUp(
                pubKey,
                voiceCreditBalance,
            )
            i ++
        }

        i = 0

        for (const log of publishMessageLogs) {
            if (i % 500 === 0) {
                console.log(`${i} / ${publishMessageLogs.length}`)
            }
            const msgIv = BigInt(log.msgIv)
            const msgData = log.msgData.map((x) => BigInt(x))
            const message = new Message(msgIv, msgData)
            const encPubKey = new PubKey([
                BigInt(log.encPubKey[0]),
                BigInt(log.encPubKey[1]),
            ])

            maciState.publishMessage(message, encPubKey)
            i ++
        }
    } else {

        console.log('Fetching signup logs')
        const signUpLogs = await provider.getLogs({
            ...maciContract.filters.SignUp(),
            fromBlock: 0,
        })
        
        console.log('Fetching publish message logs')
        const publishMessageLogs = await provider.getLogs({
            ...maciContract.filters.PublishMessage(),
            fromBlock: 0,
        })

        let i = 0
        const iface = new ethers.utils.Interface(maciContractAbi)
        for (const log of signUpLogs) {
            if (i % 100 === 0) {
                console.log(`${i} / ${signUpLogs.length}`)
            }
            const event = iface.parseLog(log)
            const voiceCreditBalance = BigInt(event.values._voiceCreditBalance.toString())
            const pubKey = new PubKey([
                BigInt(event.values._userPubKey[0]),
                BigInt(event.values._userPubKey[1]),
            ])

            maciState.signUp(
                pubKey,
                voiceCreditBalance,
            )
            i ++
        }

        i = 0
        for (const log of publishMessageLogs) {
            if (i % 100 === 0) {
                console.log(`${i} / ${publishMessageLogs.length}`)
            }
            const event = iface.parseLog(log)
            const msgIv = BigInt(event.values._message[0].toString())
            const msgData = event.values._message[1].map((x) => BigInt(x.toString()))
            const message = new Message(msgIv, msgData)
            const encPubKey = new PubKey([
                BigInt(event.values._encPubKey[0]),
                BigInt(event.values._encPubKey[1]),
            ])

            maciState.publishMessage(message, encPubKey)
            i ++
        }
    }

    if (!processMessages) {
        return maciState
    }
    
    // Check whether the above steps were done correctly before processing
    // messages
    const onChainStateRoot = await maciContract.getStateTreeRoot()

    if (maciState.genStateRoot().toString(16) !== BigInt(onChainStateRoot).toString(16)) {
        throw new Error('Error: could not correctly recreate the state tree from on-chain data. The state root differs.')
    }

    const onChainMessageRoot = await maciContract.getMessageTreeRoot()
    if (maciState.messageTree.root.toString(16) !== BigInt(onChainMessageRoot).toString(16)) {
        throw new Error('Error: could not correctly recreate the message tree from on-chain data. The message root differs.')
    }

    // Process the messages so that the users array is up to date with the
    // contract's state tree
    const currentMessageBatchIndex = Number((await maciContract.currentMessageBatchIndex()).toString())
    const messageBatchSize = Number((await maciContract.messageBatchSize()).toString())
    const numMessages = maciState.messages.length
    const maxMessageBatchIndex = numMessages % messageBatchSize === 0 ?
        numMessages
        :
        (1 + Math.floor(numMessages / messageBatchSize)) * messageBatchSize

    const hasUnprocessedMessages = await maciContract.hasUnprocessedMessages()

    // Process messages up to the latest batch (in reverse order)
    if (hasUnprocessedMessages) {
        for (let i = currentMessageBatchIndex; i > currentMessageBatchIndex; i -= messageBatchSize) {
            maciState.batchProcessMessage(
                i,
                messageBatchSize,
                zerothLeaf,
            )
        }
    } else {
        // Process all messages (in reverse order)
        for (let i = maxMessageBatchIndex; i > 0; i -= messageBatchSize) {
            maciState.batchProcessMessage(
                i - messageBatchSize,
                messageBatchSize,
                zerothLeaf,
            )
        }
    }

    return maciState
}

const calcBinaryTreeDepthFromMaxLeaves = (maxLeaves: number) => {
    let result = 0
    while (2 ** result < maxLeaves) {
        result ++
    }
    return result
}

const calcQuinTreeDepthFromMaxLeaves = (maxLeaves: number) => {
    let result = 0
    while (5 ** result < maxLeaves) {
        result ++
    }
    return result
}

const validateEthAddress = (address: string) => {
    return address.match(/^0x[a-fA-F0-9]{40}$/) != null
}

const promptPwd = async (name: string) => {
    return prompt()(name + ': ', null, { echo: ''})
}

const checkDeployerProviderConnection = async (
    sk: string,
    ethProvider: string,
) => {

    const deployer = genJsonRpcDeployer(sk, ethProvider)
    try {
        await deployer.provider.getBlockNumber()
    } catch {
        return false
    }

    return true
}

const validateSaltFormat = (salt: string): boolean => {
    return salt.match(/^0x[a-fA-F0-9]+$/) != null
}

const validateSaltSize = (salt: string): boolean => {
    return BigInt(salt) < SNARK_FIELD_SIZE
}

const validateEthSk = (sk: string): boolean => {
    try {
        new ethers.Wallet(sk)
    } catch {
        return false
    }
    return true
}

const contractExists = async (
    provider: ethers.providers.Provider,
    address: string,
) => {
    const code = await provider.getCode(address)
    return code.length > 2
}

const delay = (ms: number): Promise<void> => {
    return new Promise((resolve: Function) => setTimeout(resolve, ms))
}

const readJSONFile = (filename) => {
   if (!fs.existsSync(filename)) {
      return ""
   }
   let data = fs.readFileSync(filename).toString()
   let jdata = JSON.parse(data)
   return jdata
}

const writeJSONFile = (filename, data) => {
    fs.writeFileSync(filename, JSON.stringify(data))
}


export {
    promptPwd,
    calcBinaryTreeDepthFromMaxLeaves,
    calcQuinTreeDepthFromMaxLeaves,
    validateEthSk,
    checkDeployerProviderConnection,
    validateSaltSize,
    validateSaltFormat,
    validateEthAddress,
    contractExists,
    genMaciStateFromContract,
    delay,
    readJSONFile,
    writeJSONFile,
}
