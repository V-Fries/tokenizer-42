// SPDX-License-Identifier: MIT
pragma solidity ^0.8.37;

import {Test} from "forge-std/Test.sol";
import {SimpleCoin42} from "../src/SimpleCoin42.sol";

contract SimpleCoin42Test is Test {
    SimpleCoin42 public simpleCoin42;

    function setUp() public {
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
}
