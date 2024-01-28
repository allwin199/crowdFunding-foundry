// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {CampaignFactory} from "../src/CampaignFactory.sol";

contract DeployCampaignFactory is Script {
    address deployerKey;

    constructor() {
        if (block.chainid == 31337) {
            deployerKey = vm.envAddress("ANVIL_KEYCHAIN");
        } else {
            deployerKey = vm.envAddress("SEPOLIA_KEYCHAIN");
        }
    }

    function run() external returns (CampaignFactory) {
        vm.startBroadcast(deployerKey);

        CampaignFactory campaignFactory = new CampaignFactory();

        vm.stopBroadcast();

        return campaignFactory;
    }
}
