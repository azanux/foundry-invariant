// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {InvariantFlag} from "../src/InvariantFlag.sol";

contract InvariantFlagTest is Test {
    InvariantFlag target;

    function setUp() external {
        target = new InvariantFlag();
    }

    function invariant_flag_should_be_false() external {
        assertEq(target.flag(), false);
    }
}
