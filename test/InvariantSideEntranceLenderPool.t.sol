// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console2.sol";

import "../src/SideEntranceLenderPool.sol";
import {PoolHandler} from "./PoolHandler.sol";

contract InvariantSideEntranceLenderPool is Test {
    SideEntranceLenderPool pool;
    PoolHandler handler;

    function setUp() external {
        // deploy the pool contract with 25 ether
        pool = new SideEntranceLenderPool{value: 25 ether}();
        // deploy the handler contract
        handler = new PoolHandler(pool);
        // set the handler contract as the target for our test
        targetContract(address(handler));
    }
    
    // invariant test function
    function invariant_poolBalanceAlwaysGtThanInitialBalance() external {
        // assert that the pool balance will never go below the initial balance (the 10 ether deposited during deployment)
        assert(address(pool).balance >= pool.initialPoolBalance());
    }
}
