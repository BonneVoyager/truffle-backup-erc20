const { BN } = require('@openzeppelin/test-helpers')

const expectEqual = (result, expected) => expect(new BN(result).eq(new BN(expected))).to.be.true

// Creates signer's Sig based on contract's typed data with passed backup address
const signEIP712 = async (signerAddress, verifyingContract) => {
  const chainId = await web3.eth.getChainId()
  const typedData = {
    types: {
      EIP712Domain: [
        { name: 'name', type: 'string' },
        { name: 'chainId', type: 'uint256' },
        { name: 'verifyingContract', type: 'address' },
      ],
      Backup: [
        { name: 'wallet', type: 'address' }
      ]
    },
    primaryType: 'Backup',
    domain: {
      name: 'BackupERC20',
      chainId,
      verifyingContract,
    },
    message: {
      wallet: signerAddress,
    },
  }

  return new Promise(async (resolve, reject) =>
    await web3.currentProvider.send({
      method: 'eth_signTypedData_v4',
      params: [signerAddress, typedData],
      from: signerAddress,
    }, (err, res) => {
      if (err) {
        reject(err)
      }

      const signature = res.result.substring(2)
      const r = `0x${signature.substring(0, 64)}`
      const s = `0x${signature.substring(64, 128)}`
      const v = `0x${signature.substring(128, 130)}`

      resolve({ signature, r, s, v })
    })
  )
}

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

module.exports = {
  expectEqual,
  signEIP712,
  ZERO_ADDRESS,
}
