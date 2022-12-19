// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.13;

import "./ZeroxERC20.sol";

contract BackupERC20 is ZeroxERC20 {
    constructor(uint256 _initialSupply) {
        balances[msg.sender] += _initialSupply;
        _totalSupply += _initialSupply;
    }
}
