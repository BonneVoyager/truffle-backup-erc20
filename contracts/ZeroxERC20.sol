// SPDX-License-Identifier: Apache-2.0
// This file is a copy of (except this one uses Solidity 0.8.13 and virtual modifiers for transfer and transferFrom):
// https://github.com/0xProject/protocol/blob/development/contracts/erc20/contracts/src/ERC20Token.sol
pragma solidity 0.8.13;

import "./interfaces/IERC20Token.sol";

contract ZeroxERC20 is IERC20Token {
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    uint256 internal _totalSupply;

    /// @dev send `value` token to `to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transfer(address _to, uint256 _value) public virtual override returns (bool) {
        require(balances[msg.sender] >= _value, "ERC20_INSUFFICIENT_BALANCE");
        require(balances[_to] + _value >= balances[_to], "UINT256_OVERFLOW");

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /// @dev send `value` token to `to` from `from` on the condition it is approved by `from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool) {
        require(balances[_from] >= _value, "ERC20_INSUFFICIENT_BALANCE");
        require(allowed[_from][msg.sender] >= _value, "ERC20_INSUFFICIENT_ALLOWANCE");
        require(balances[_to] + _value >= balances[_to], "UINT256_OVERFLOW");

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    /// @dev `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Always true if the call has enough gas to complete execution
    function approve(address _spender, uint256 _value) external override returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @dev Query total supply of token
    /// @return Total supply of token
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /// @dev Query the balance of owner
    /// @param _owner The address from which the balance will be retrieved
    /// @return Balance of owner
    function balanceOf(address _owner) external view override returns (uint256) {
        return balances[_owner];
    }

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return allowed[_owner][_spender];
    }
}
