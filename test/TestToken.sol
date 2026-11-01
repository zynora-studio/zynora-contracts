// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// A bare ERC-20 for the holder-tier tests only: on a local anvil node, and
/// once on Robinhood Chain Testnet as "the test token" (scripts/deploy-test-token.ts),
/// whose address is kept in var/, never in production's env. the token itself
/// does not exist yet.
contract TestToken {
    string public constant name = "Test Token";
    string public constant symbol = "tTEST";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address to, uint256 amount) {
        totalSupply = amount;
        balanceOf[to] = amount;
        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
}
