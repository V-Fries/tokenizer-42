// SPDX-License-Identifier: MIT
pragma solidity ^0.8.37;

import {Script} from "forge-std/Script.sol";
import {SimpleCoin42} from "../src/SimpleCoin42.sol";

contract DeployContract is Script {
    SimpleCoin42 public simpleCoin42;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        simpleCoin42 = new SimpleCoin42("SimpleCoin42", "SC42", 2);

        vm.stopBroadcast();
    }
}
