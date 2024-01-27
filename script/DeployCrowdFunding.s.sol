// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {CrowdFunding} from "../src/CrowdFunding.sol";

contract DeployCrowdFunding is Script {
    address deployerKey;

    constructor() {
        if (block.chainid == 31337) {
            deployerKey = vm.envAddress("ANVIL_KEYCHAIN");
        } else {
            deployerKey = vm.envAddress("SEPOLIA_KEYCHAIN");
        }
    }

    function run() external returns (CrowdFunding) {
        vm.startBroadcast(deployerKey);

        CrowdFunding crowdFunding = new CrowdFunding();

        vm.stopBroadcast();

        return crowdFunding;
    }
}
