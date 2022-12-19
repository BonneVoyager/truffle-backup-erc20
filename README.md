# truffle-backup-erc20

`BackupERC20` is an ERC20 interface with additions allowing the holders to register a backup address using the contract method `registerBackup(address _backup)` that will be used in emergencies. The token holders can recover all their tokens to previously registered emergency addresses via an EIP712 signature. The signature can be used by any address interacting with the contract method `recover(uint8 _v, bytes32 _r, bytes32 _s, address _recoveree)`. In case of an emergency, the wallet is "blacklisted," and the tokens sent to the "blacklisted" wallet will be transferred to the backup wallet instead.

`BackupERC20` extends from 0x ERC20 implementation with an update to the Solidity version compiler and `virtual` visibility for `transfer()` and `transferFrom()` methods. The rest of the 0x implementation remains unchanged.

## Development

### Install dependencies

```
npm install
```

### Run tests

```
npm run test
```

### Run Slither via Docker

```
docker run -it -v `pwd`:/src trailofbits/eth-security-toolbox
solc-select install 0.8.13 && solc-select use 0.8.13 && cd /src
slither .
```

## Deployment

```
npm run migrate
```
