// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("MockUSDC", "MUSDC") {
        super._mint(msg.sender, 100000 * 1e6); // mint a million to owner
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
