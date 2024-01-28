// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {DeployCrowdFunding} from "../script/DeployCrowdFunding.s.sol";
import {CrowdFunding} from "../src/CrowdFunding.sol";

contract CrowdFundingTest is Test {
    DeployCrowdFunding private deployer;
    CrowdFunding private crowdFunding;

    function setUp() external {
        deployer = new DeployCrowdFunding();
        crowdFunding = deployer.run();
    }

    function test_TotalCampaigns_IsZero() public {
        uint256 totalCampaigns = crowdFunding.getTotalCampaigns();
        assertEq(totalCampaigns, 0);
    }
}
