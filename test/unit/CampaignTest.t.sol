// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {Campaign} from "../../src/Campaign.sol";

contract CampaignTest is Test {
    Campaign campaign;

    //campaign details
    string private constant CAMPAIGN_NAME = "campaign1";
    string private constant CAMPAIGN_DESCRIPTION = "campaign1 description";
    uint256 private constant TARGET_AMOUNT = 10e18;
    uint256 private constant FUNDING_AMOUNT = 1e18;
    uint256 private startAt = block.timestamp;
    uint256 private endAt = block.timestamp + 10000;
    string private constant IMAGE = "";

    address private user = makeAddr("user");
    address private funder = makeAddr("funder");
    uint256 private constant STARTING_BALANCE = 100e18;

    function setUp() external {
        campaign = new Campaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, startAt, endAt, IMAGE);

        // let's give funds to the user
        vm.deal(user, STARTING_BALANCE);
        vm.deal(funder, STARTING_BALANCE);
    }

    function test_RevertsIf_FundingAmount_IsZero() external {
        vm.startPrank(funder);

        vm.expectRevert(Campaign.Campaign__FundingWith_ZeroAmount.selector);
        campaign.fund(0);

        vm.stopPrank();
    }

    function test_FunderCanFund() external {
        vm.startPrank(funder);
        campaign.fund(FUNDING_AMOUNT);
        vm.stopPrank();
    }
}
