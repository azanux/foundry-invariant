// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {AddressSet, LibAddressSet} from "./helper/AddressSet.sol";
import {Test, console} from "forge-std/Test.sol";

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

contract WETH9Handler is CommonBase, StdCheats, StdUtils {
    WETH9 public weth;

    uint256 public ghost_depositSum;
    uint256 public ghost_zeroWithdrawals;

    uint256 public constant ETH_SUPPLY = 120_500_000 ether;

    mapping(bytes32 => uint256) public calls;

    modifier countCall(bytes32 key) {
        calls[key]++;
        _;
    }

    constructor(address _weth) {
        weth = WETH9(_weth);
        deal(address(this), ETH_SUPPLY);
    }

    using LibAddressSet for AddressSet;

    AddressSet internal _actors;

    address internal currentActor;

    // Other handler stuff omitted here

    function actors() external returns (address[] memory) {
        return _actors.addrs;
    }

    modifier createActor() {
        currentActor = msg.sender;
        _actors.add(msg.sender);
        _;
    }

    modifier useActor(uint256 actorIndexSeed) {
        currentActor = _actors.rand(actorIndexSeed);
        _;
    }

    function deposit(uint256 amount) public createActor countCall("deposit") {
        amount = bound(amount, 0, address(this).balance);
        _pay(currentActor, amount);

        vm.prank(currentActor);
        weth.deposit{value: amount}();
        ghost_depositSum += amount;
    }

    function withdraw(uint256 actorSeed, uint256 amount) public useActor(actorSeed) countCall("withdraw") {
        address caller = _actors.rand(actorSeed);

        amount = bound(amount, 0, weth.balanceOf(caller));

        if (amount == 0) ghost_zeroWithdrawals++;

        vm.prank(caller);
        weth.withdraw(amount);
        _pay(address(this), amount);

        ghost_depositSum -= amount;
    }

    function sendFallback(uint256 amount) public createActor countCall("sendFallback") {
        
        amount = bound(amount, 0, address(this).balance);

        _pay(currentActor, amount);
        vm.prank(currentActor);
        (bool success,) = address(weth).call{value: amount}("");
        require(success, "sendFallback failed");
        ghost_depositSum += amount;
    }

    receive() external payable {}

    function _pay(address to, uint256 amount) internal {
        (bool s,) = to.call{value: amount}("");
        require(s, "pay() failed");
    }

    function forEachActor(function(address) external func) public {
        return _actors.forEach(func);
    }

    function reduceActors(uint256 acc, function(uint256,address) external returns (uint256) func)
        public
        returns (uint256)
    {
        return _actors.reduce(acc, func);
    }

    function approve(uint256 actorSeed, uint256 spenderSeed, uint256 amount)
        public
        useActor(actorSeed)
        countCall("approve")
    {
        address spender = _actors.rand(spenderSeed);

        vm.prank(currentActor);
        weth.approve(spender, amount);
    }

    function transfer(uint256 actorSeed, uint256 toSeed, uint256 amount)
        public
        useActor(actorSeed)
        countCall("transfer")
    {
        address to = _actors.rand(toSeed);

        amount = bound(amount, 0, weth.balanceOf(currentActor));

        vm.prank(currentActor);
        weth.transfer(to, amount);
    }

    function transferFrom(uint256 actorSeed, uint256 fromSeed, uint256 toSeed, bool _approve, uint256 amount)
        public
        useActor(actorSeed)
        countCall("transferFrom")
    {
        address from = _actors.rand(fromSeed);
        address to = _actors.rand(toSeed);

        amount = bound(amount, 0, weth.balanceOf(from));

        if (_approve) {
            vm.prank(from);
            weth.approve(currentActor, amount);
        } else {
            amount = bound(amount, 0, weth.allowance(currentActor, from));
        }

        vm.prank(currentActor);
        weth.transferFrom(from, to, amount);
    }

    function callSummary() external view {
        console.log("Call summary:");
        console.log("-------------------");
        console.log("deposit", calls["deposit"]);
        console.log("withdraw", calls["withdraw"]);
        console.log("sendFallback", calls["sendFallback"]);
    }
}
