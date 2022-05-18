// SPDX-License-Identifier: MIT
pragma solidity ^0.7.2;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TopupCredit is ERC20, Ownable {
    uint256 MAXIMUM_AIRDROP_AMOUNT = 100 * 10**18;

    constructor() ERC20("TopupCredit", "TopupCredit") {}

    function airdropTo(address account, uint256 amount) public {
        require(amount < MAXIMUM_AIRDROP_AMOUNT);
        _mint(account, amount);
    }

    function airdrop(uint256 amount) public {
        require(amount < MAXIMUM_AIRDROP_AMOUNT);
        _mint(msg.sender, amount);
    }
}
