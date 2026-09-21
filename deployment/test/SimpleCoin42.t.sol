// SPDX-License-Identifier: MIT
pragma solidity ^0.8.37;

import {Test} from "forge-std/Test.sol";
import {SimpleCoin42} from "../src/SimpleCoin42.sol";

contract SimpleCoin42Test is Test {
    address creator;

    SimpleCoin42 public simpleCoin42;

    function setUp() public {
        creator = makeAddr("owner");
        hoax(creator);
        simpleCoin42 = new SimpleCoin42();
    }

    function test_Name() public view {
        assertEq(simpleCoin42.name(), "SimpleCoin42");
    }

    function test_Symbol() public view {
        assertEq(simpleCoin42.symbol(), "SC42");
    }

    function test_Decimals() public view {
        assertEq(simpleCoin42.decimals(), 18);
    }

    function testFuzz_TotalSupply(
        address user,
        uint256 mintAmount,
        uint256 burnAmount
    ) public {
        vm.assume(user != address(0));
        burnAmount = bound(burnAmount, 0, mintAmount);

        uint256 supplyBeforeMinting = simpleCoin42.totalSupply();

        hoax(creator);
        simpleCoin42.mintTokens(user, mintAmount);

        uint256 supplyAfterMinting = simpleCoin42.totalSupply();

        assertEq(supplyAfterMinting, supplyBeforeMinting + mintAmount);

        hoax(user);
        simpleCoin42.burnTokens(burnAmount);

        assertEq(simpleCoin42.totalSupply(), supplyAfterMinting - burnAmount);
    }
}
