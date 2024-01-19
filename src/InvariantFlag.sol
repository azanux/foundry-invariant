// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract InvariantFlag {
    bool public flag;

    function func1() external {}

    function func2() external {}

    function func3() external {}

    function func4() external {}

    function func5() external {
        flag = true;
    }
}
