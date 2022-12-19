const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers')
const { expect } = require('chai')

const { expectEqual, signEIP712, ZERO_ADDRESS } = require('./utils')

const BackupERC20 = artifacts.require('BackupERC20')

const INITIAL_SUPPLY = 10_000

contract('BackupERC20', (accounts) => {
  const [owner, user1, user1Backup, user1BackupAlt, user2] = accounts

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

  describe('registerBackup', () => {
    it('should be able to register a backup wallet address and emit "RegisteredBackup" event', async () => {
      const receipt = await token.registerBackup(user1Backup, { from: user1 })
      expectEvent(receipt, 'RegisteredBackup', {
        recoveree: user1,
        backup: user1Backup,
      })
      expect(await token.backups(user1)).to.eq(user1Backup)
    })

    it('reverts when a wallet tries to set the backup wallet again', async () => {
      await token.registerBackup(user1Backup, { from: user1 })
      await expectRevert(
        token.registerBackup(user1BackupAlt, { from: user1 }),
        'ERC20_BACKUP_REGISTERED',
      )
    })

    it('reverts when trying to set zero backup address', async () => {
      await expectRevert(
        token.registerBackup(ZERO_ADDRESS, { from: user1 }),
        'ERC20_BACKUP_ZERO_ADDRESS',
      )
    })
  })

  describe('recover', () => {
    it('should be able to recover the funds to backup wallet via the backup wallet and emit "Recovered"', async () => {
      // send some tokens to user1
      await token.transfer(user1, INITIAL_SUPPLY, { from: owner })
      expectEqual(await token.balanceOf(user1), INITIAL_SUPPLY)
      expectEqual(await token.balanceOf(user1Backup), 0)

      // user1 first registers the backup
      await token.registerBackup(user1Backup, { from: user1 })
      expect(await token.backups(user1)).to.eq(user1Backup)

      // then signs the recovery message
      const { r, s, v } = await signEIP712(user1, token.address)

      // to then recover the funds by user2
      const receipt = await token.recover(v, r, s, user1, { from: user2 })
      expectEvent(receipt, 'Recovered', {
        who: user2,
        recoveree: user1,
        backup: user1Backup,
        amount: new BN(INITIAL_SUPPLY),
      })
      expectEqual(await token.balanceOf(user1), 0)
      expectEqual(await token.balanceOf(user1Backup), INITIAL_SUPPLY)

      // user1 should be now "blacklisted"
      expect(await token.blacklisted(user1)).to.eq(true)
    })

    it('reverts when trying to temper with the signature', async () => {
      // send some tokens to user1
      await token.transfer(user1, INITIAL_SUPPLY, { from: owner })

      // user1 first registers the backup
      await token.registerBackup(user1Backup, { from: user1 })
      expect(await token.backups(user1)).to.eq(user1Backup)

      // some other user signs the recovery message
      const { r, s, v } = await signEIP712(user2, token.address)

      // to then tries to recover user1 funds
      await expectRevert(
        token.recover(v, r, s, user1, { from: user2 }),
        'ERC20_BACKUP_INVALID_SIG',
      )
    })
  })

  describe('transfer', () => {
    it('redirect sent tokens to backup wallet when the initial one was already "blacklisted"', async () => {
      // send some tokens to user1 when it's not blacklisted
      await token.transfer(user1, 100, { from: owner })
      expectEqual(await token.balanceOf(user1), 100)
      expectEqual(await token.balanceOf(user1Backup), 0)

      // recover the tokens to the backup wallet and blacklist the user
      await token.registerBackup(user1Backup, { from: user1 })
      const { r, s, v } = await signEIP712(user1, token.address)
      await token.recover(v, r, s, user1, { from: user1 })
      expectEqual(await token.balanceOf(user1), 0)
      expectEqual(await token.balanceOf(user1Backup), 100)

      // now send some more tokens to user1, but this time it's blacklisted
      await token.transfer(user1, 150, { from: owner })
      expectEqual(await token.balanceOf(user1), 0)
      // so the tokens should go to the backup wallet
      expectEqual(await token.balanceOf(user1Backup), 250)
    })
  })

  describe('transferFrom', () => {
    it('redirect sent tokens to backup wallet when the initial one was already "blacklisted"', async () => {
      // send some tokens to user1 when it's not blacklisted
      await token.approve(owner, 500, { from: owner })
      await token.transferFrom(owner,user1, 75, { from: owner })
      expectEqual(await token.balanceOf(user1), 75)
      expectEqual(await token.balanceOf(user1Backup), 0)

      // recover the tokens to the backup wallet and blacklist the user
      await token.registerBackup(user1Backup, { from: user1 })
      const { r, s, v } = await signEIP712(user1, token.address)
      await token.recover(v, r, s, user1, { from: user1 })
      expectEqual(await token.balanceOf(user1), 0)
      expectEqual(await token.balanceOf(user1Backup), 75)

      // now send some more tokens to user1, but this time it's blacklisted
      await token.transferFrom(owner, user1, 125, { from: owner })
      expectEqual(await token.balanceOf(user1), 0)
      // so the tokens should go to the backup wallet
      expectEqual(await token.balanceOf(user1Backup), 200)
    })
  })
})
