// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {WETH9Handler} from "./WETH9Handler.sol";

interface WETH9 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract WETH9Invariants is Test {
    WETH9 public weth;
    WETH9Handler public handler;

    function setUp() public {
        address wethAddress = deployCode("WETH9.sol");
        weth = WETH9(wethAddress);

        handler = new WETH9Handler(wethAddress);

        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = WETH9Handler.deposit.selector;
        selectors[1] = WETH9Handler.withdraw.selector;
        selectors[2] = WETH9Handler.sendFallback.selector;
        selectors[3] = WETH9Handler.approve.selector;
        selectors[4] = WETH9Handler.transfer.selector;
        selectors[5] = WETH9Handler.transferFrom.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));

        targetContract(address(handler));
    }

    function invariant_badInvariantThisShouldFail() public {
        assertEq(0, weth.totalSupply());
    }

    function test_zeroDeposit() public {
        weth.deposit{value: 0}();
        assertEq(0, weth.balanceOf(address(this)));
        assertEq(0, weth.totalSupply());
    }

    function invariant_wethSupplyIsAlwaysZero() public {
        assertEq(0, weth.totalSupply());
    }

    // ETH can only be wrapped into WETH, WETH can only
    // be unwrapped back into ETH. The sum of the Handler's
    // ETH balance plus the WETH totalSupply() should always
    // equal the total ETH_SUPPLY.
    function invariant_conservationOfETH() public {
        assertEq(handler.ETH_SUPPLY(), address(handler).balance + weth.totalSupply());
    }

    function invariant_solvencyDeposits() public {
        assertEq(address(weth).balance, handler.ghost_depositSum());
    }

    // The WETH contract's Ether balance should always be
    // at least as much as the sum of individual balances
    function invariant_solvencyBalances() public {
        uint256 sumOfBalances = 0;
        assertEq(address(weth).balance, sumOfBalances);
    }

    // The WETH contract's Ether balance should always be
    // at least as much as the sum of individual balances
    function invariant_solvencyBalancesActor() public {
        uint256 sumOfBalances;
        address[] memory actors = handler.actors();
        for (uint256 i; i < actors.length; ++i) {
            sumOfBalances += weth.balanceOf(actors[i]);
        }
        assertEq(address(weth).balance, sumOfBalances);
    }

    // The WETH contract's Ether balance should always be
    // at least as much as the sum of individual balances
    function invariant_solvencyBalanceActor() public {
        uint256 sumOfBalances = handler.reduceActors(0, this.accumulateBalance);
        assertEq(address(weth).balance, sumOfBalances);
    }

    function accumulateBalance(uint256 balance, address caller) external view returns (uint256) {
        return balance + weth.balanceOf(caller);
    }

    // No individual account balance can exceed the
    // WETH totalSupply().
    function invariant_depositorBalances() public {
        handler.forEachActor(this.assertAccountBalanceLteTotalSupply);
    }

    function assertAccountBalanceLteTotalSupply(address account) external {
        assertLe(weth.balanceOf(account), weth.totalSupply());
    }

    function invariant_callSummary() public view {
        handler.callSummary();
    }
}
