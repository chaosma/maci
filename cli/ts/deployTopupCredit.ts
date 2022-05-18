import * as fs from 'fs'
import {writeJSONFile} from 'maci-common'
import {contractFilepath, contractFilepathOld} from './config'

import {
    deployTopupCredit as deployTopupCreditContract,
} from 'maci-contracts'

const configureSubparser = (subparsers: any) => {
    subparsers.addParser(
        'deployTopupCredit',
        { addHelp: true },
    )
}

// we assume deployVkRegister is the start of a new set of MACI contracts
const deployTopupCredit = async () => {
    const TopupCreditContract = await deployTopupCreditContract()
    console.log('TopupCredit:', TopupCreditContract.address)
    if (fs.existsSync(contractFilepath)) {
      fs.renameSync(contractFilepath, contractFilepathOld)
    }
    writeJSONFile(contractFilepath, {'TopupCredit':TopupCreditContract.address})
    return 0
}

export {
    deployTopupCredit,
    configureSubparser,
}
