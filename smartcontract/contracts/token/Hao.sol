// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Hao is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("Hao", "hao")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 5 * 10 ** 8 * 10 ** 10);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}