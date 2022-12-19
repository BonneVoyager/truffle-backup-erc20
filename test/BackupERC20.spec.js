const { expectEqual } = require('./utils')

const BackupERC20 = artifacts.require('BackupERC20')

const INITIAL_SUPPLY = 10_000

contract('BackupERC20', (accounts) => {
  const [owner] = accounts

  let token

  beforeEach(async () => {
    token = await BackupERC20.new(INITIAL_SUPPLY, { from: owner })
  })

  describe('constructor', () => {
    it('should mint the initial supply', async () => {
      const ownerBalance = await token.balanceOf(owner)
      expectEqual(ownerBalance, INITIAL_SUPPLY)
    })
  })
})
