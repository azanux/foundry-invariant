// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {MostSignificantBitFunction} from "../src/MostSignificantBitFunction.sol";

contract FuzzTest is Test {
    MostSignificantBitFunction bit;

    function setUp() external {
        bit = new MostSignificantBitFunction();
    }

    function testMostSignificantBitFunctionManual() external {
        uint256 x = 0;
        assertEq(bit.mostSignificantBit(x), 0);
        assertEq(bit.mostSignificantBit(1), 0);
        assertEq(bit.mostSignificantBit(2), 1);
        assertEq(bit.mostSignificantBit(3), 1);
        assertEq(bit.mostSignificantBit(4), 2);
        assertEq(bit.mostSignificantBit(8), 3);
        assertEq(bit.mostSignificantBit(type(uint256).max), 255);
    }

    function testMostSignificantBitFunctionManualFunc() external {
        for (uint256 i = 0; i < 255; i++) {
            assertEq(bit.mostSignificantBit(i), mostSignificantBit(i));
        }
    }

    function testMostSignificantBitFunctionFuzz(uint256 i) external {
        assertEq(bit.mostSignificantBit(i), mostSignificantBit(i));
    }

    function testMostSignificantBitFunctionFuzzWithSkip(uint256 i) external {
        //we want to skip an imout value of 0
        vm.assume(i > 0);
        assertEq(bit.mostSignificantBit(i), mostSignificantBit(i));
    }

    function testMostSignificantBitFunctionFuzzWithBound(uint256 i) external {
        //we want to bound the input value to bebetween 2 value
        i = bound(i, 0, 10);
        console.log("########## i: ", i);
        assertEq(bit.mostSignificantBit(i), mostSignificantBit(i));
    }

    // Get position of most significant bit
    // x = 1100 = 10, most significant bit = 1000, so this function will return 3
    function mostSignificantBit(uint256 x) private pure returns (uint256) {
        uint256 i = 0;
        while ((x >>= 1) > 0) {
            ++i;
        }
        return i;
    }
}
