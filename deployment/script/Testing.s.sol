// SPDX-License-Identifier: MIT
pragma solidity ^0.8.37;

import {Script} from "forge-std/Script.sol";
import {SimpleCoin42} from "../src/SimpleCoin42.sol";
import {console} from "forge-std/console.sol";

contract Testing is Script {
    function setUp() public {}

    function run() public {
        address contractOwner = 0x09A14705E010A03965BD56c063aEE754e53864fE;
        SimpleCoin42 c = SimpleCoin42(
            0x8512BBCC2a33be75322617E2e24fd7A010c77272
        );

        address other = makeAddr("foo");
        console.log("other addr: ", other);

        vm.startBroadcast();

        c.mintTokens(contractOwner, 500);
        c.transfer(other, 250);

        console.log("contract owner balance: ", c.balanceOf(contractOwner));
        console.log("other balance: ", c.balanceOf(other));

        vm.stopBroadcast();
    }
}
