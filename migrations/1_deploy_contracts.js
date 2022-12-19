module.exports = async (deployer, network) => {
  const BackupERC20 = artifacts.require('BackupERC20')

  await deployer.deploy(BackupERC20, 10_000)

  const backupERC20 = await BackupERC20.deployed()
  console.log(`BackupERC20 deployed at ${backupERC20.address} in network: ${network}.`)
}
