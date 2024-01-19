// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {WETH} from "../src/WETH.sol";

contract WethHandler is CommonBase, StdCheats, StdUtils {
    WETH private weth;
    uint256 public wethBalance;
    uint256 nbCall;

    constructor(WETH _weth) {
        weth = _weth;
    }

    receive() external payable {}

    function deposit(uint256 amount) external payable {
        amount = bound(amount, 0, address(this).balance);
        wethBalance += amount;
        nbCall++;
        weth.deposit{value: amount}();
    }

    function withdraw(uint256 amount) external {
        amount = bound(amount, 0, weth.balanceOf(address(this)));
        wethBalance -= amount;
        nbCall++;
        weth.withdraw(amount);
    }

    function sendToFallback(uint256 amount) external payable {
        amount = bound(amount, 0, address(this).balance);
        wethBalance += amount;
        nbCall++;
        (bool sucess,) = address(weth).call{value: amount}("");
        require(sucess, "WethHandler: sendToFallback failed");
    }

    function fail() external pure {
        revert("WethHandler: fail");
    }
}
