pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockDaoToken is ERC20 {
    constructor() public ERC20("Dao Token", "DAO"){
        _mint(msg.sender, 50000000000000000000000);
    }
    // 1000000000000000000000000 1 million tokens
    // 50000000000000000000000 50 000 tokens
    // 10000000000000000000 1 token
}