// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.13;

import "./ZeroxERC20.sol";

contract BackupERC20 is ZeroxERC20 {
    // EIP712 name and typehashes of the contract
    string public constant NAME = "BackupERC20";
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant BACKUP_TYPEHASH = keccak256("Backup(address wallet)");
    bytes32 public eip712DomainHash = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(NAME)), block.chainid, address(this)));

    // mapping of backup addresses for the token holders
    mapping(address => address) public backups;

    // mapping of blacklisted addresses, funds transferred to those addresses will be redirected to backup addresses
    mapping(address => bool) public blacklisted;

    event Recovered(address indexed who, address indexed recoveree, address indexed backup, uint256 amount);
    event RegisteredBackup(address indexed recoveree, address indexed backup);

    constructor(uint256 _initialSupply) {
        // initial minting of the tokens
        balances[msg.sender] += _initialSupply;
        _totalSupply += _initialSupply;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    /// @dev register a backup address which will be used to transfer the tokens in case of an emergency
    /// @param _backup the address used for the backup
    /// @return True if the backup registration was successful
    function registerBackup(address _backup) external returns (bool) {
        require(backups[msg.sender] == address(0), "ERC20_BACKUP_REGISTERED");
        require(_backup != address(0), "ERC20_BACKUP_ZERO_ADDRESS");

        backups[msg.sender] = _backup;
        emit RegisteredBackup(msg.sender, _backup);

        return true;
    }

    /// @dev recover the backup by signature on behalf of a signer and blacklists the recoveree address.
    /// @param _v v sign value
    /// @param _r r sign value
    /// @param _s s sign value
    /// @param _recoveree address for which the recovery should happen
    function recover(uint8 _v, bytes32 _r, bytes32 _s, address _recoveree) external returns (bool) {
        bytes32 hashStruct = keccak256(abi.encode(BACKUP_TYPEHASH, _recoveree));
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
        address signer = ecrecover(hash, _v, _r, _s);
        require(signer == _recoveree, "ERC20_BACKUP_INVALID_SIG");

        blacklisted[_recoveree] = true;
        emit Recovered(msg.sender, _recoveree, backups[_recoveree], balances[_recoveree]);
        transferFrom(_recoveree, backups[_recoveree], balances[_recoveree]);

        return true;
    }

    /// @dev send `value` token to `to` from `msg.sender`. The only difference from the original is that this function
    ///      redirects funds for blacklisted addresses to their backup wallets.
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(balances[msg.sender] >= _value, "ERC20_INSUFFICIENT_BALANCE");
        require(balances[_to] + _value >= balances[_to], "UINT256_OVERFLOW");

        if (blacklisted[_to]) {
            _to = backups[_to];
        }
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /// @dev send `value` token to `to` from `from` on the condition it is approved by `from`. The only difference
    ///      from the original is that this function allows to transfer to backup wallets ignoring the allowance
    ///      and redirects funds for blacklisted addresses to their backup wallets.
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require(balances[_from] >= _value, "ERC20_INSUFFICIENT_BALANCE");
        // ignore allowance for "blacklisted" wallets (during backup transfers)
        require(allowed[_from][msg.sender] >= _value || blacklisted[_from], "ERC20_INSUFFICIENT_ALLOWANCE");
        require(balances[_to] + _value >= balances[_to], "UINT256_OVERFLOW");

        if (blacklisted[_to]) {
            _to = backups[_to];
        }
        balances[_to] += _value;
        balances[_from] -= _value;
        if (backups[_from] != _to) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);

        return true;
    }
}
