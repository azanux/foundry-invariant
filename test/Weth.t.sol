// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {WETH} from "../src/WETH.sol";
import {WethHandler} from "./WethHandler.t.sol";
import {ActorManager} from "./ActorManager.t.sol";

contract WethTest is Test {
    WETH weth;

    function setUp() external {
        weth = new WETH();
    }

    function invariant_WethFuzz() external {
        assertEq(weth.totalSupply(), 0);
    }
}

contract WethHandlerTest is Test {
    WETH weth;
    WethHandler handler;

    function setUp() external {
        weth = new WETH();
        handler = new WethHandler(weth);

        deal(address(handler), 100 ether);
        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = handler.deposit.selector;
        selectors[1] = handler.withdraw.selector;
        selectors[2] = handler.sendToFallback.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    function invariant_eth_balance() external {
        assertGe(address(weth).balance, handler.wethBalance());
    }
}

contract WethActorManagerTest is Test {
    WETH private weth;
    WethHandler[] private handlers;
    ActorManager private manager;

    function setUp() external {
        weth = new WETH();

        for (uint256 i = 0; i < 3; i++) {
            WethHandler _handler = new WethHandler(weth);
            deal(address(_handler), 100 ether);
            handlers.push(_handler);
        }

        manager = new ActorManager(handlers);
        targetContract(address(manager));
    }

    function invariant_eth_balance() external {
        uint256 total = 0;
        for (uint256 i = 0; i < handlers.length; i++) {
            total = handlers[i].wethBalance();
        }
        assertGe(address(weth).balance, total);

        console.log("########## total: ", total / 1e18);
    }
}
