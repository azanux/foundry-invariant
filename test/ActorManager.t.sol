// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {WETH} from "../src/WETH.sol";
import {WethHandler} from "./WethHandler.t.sol";

contract ActorManager is CommonBase, StdCheats, StdUtils {
    //Array of handler
    WethHandler[] public handlers;

    constructor(WethHandler[] memory _handlers) {
        handlers = _handlers;
    }

    function sendToFallback(uint256 handlerIndex, uint256 amount) external payable {
        uint256 index = bound(handlerIndex, 0, handlers.length - 1);
        handlers[index].sendToFallback(amount);
    }

    function deposit(uint256 amount) external payable {
        uint256 index = bound(amount, 0, handlers.length - 1);
        handlers[index].deposit(amount);
    }

    function withdraw(uint256 amount) external {
        uint256 index = bound(amount, 0, handlers.length - 1);
        handlers[index].withdraw(amount);
    }
}
