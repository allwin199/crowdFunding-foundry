// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployCampaignFactory} from "../../script/DeployCampaignFactory.s.sol";
import {CampaignFactory} from "../../src/CampaignFactory.sol";

contract CrowdFundingTest is Test {
    //////////////////////////////////////////////////////////
    ////////////////  Storage Variables  /////////////////////
    //////////////////////////////////////////////////////////

    DeployCampaignFactory private deployer;
    CampaignFactory private campaignFactory;

    address private user = makeAddr("user");
    address private funder = makeAddr("funder");
    uint256 private constant STARTING_BALANCE = 100e18;

    //campaign details
    string private constant CAMPAIGN_NAME = "campaign1";
    string private constant CAMPAIGN_DESCRIPTION = "campaign1 description";
    uint256 private constant TARGET_AMOUNT = 10e18;
    uint256 private constant FUNDING_AMOUNT = 1e18;
    uint256 private startAt = block.timestamp;
    uint256 private endAt = block.timestamp + 10000;
    string private constant IMAGE = "";

    //////////////////////////////////////////////////////////
    //////////////////////   Events  /////////////////////////
    //////////////////////////////////////////////////////////
    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creator,
        uint256 indexed targetAmount,
        uint256 startAt,
        uint256 endAt
    );
    event CampaignFunded(uint256 indexed campaignId, address indexed funder, uint256 indexed amount);
    event WithdrawSuccessful(uint256 indexed campaignId, address indexed owner, uint256 indexed amount);

    function setUp() external {
        deployer = new DeployCampaignFactory();
        campaignFactory = deployer.run();

        // let's give funds to the user
        vm.deal(user, STARTING_BALANCE);
        vm.deal(funder, STARTING_BALANCE);
    }

    function test_RevertsIf_CampaignStartDate_NotInPresent() public {
        vm.startPrank(user);
        vm.expectRevert(CampaignFactory.CampaignFactory__StartDate_ShouldBeInPresent.selector);
        campaignFactory.createCampaign(
            CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, block.timestamp - 1, endAt, IMAGE
        );
        vm.stopPrank();
    }

    function test_RevertsIf_InvalidTimeline() public {
        vm.warp(block.timestamp + 100);
        vm.roll(block.number + 1);

        vm.startPrank(user);
        vm.expectRevert(CampaignFactory.CampaignFactory__InvalidTimeline.selector);
        campaignFactory.createCampaign(
            CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, block.timestamp, block.timestamp - 50, IMAGE
        );
        vm.stopPrank();
    }

    function test_UserCan_CreateCampaign() external {
        vm.startPrank(user);
        address campaign =
            campaignFactory.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, startAt, endAt, IMAGE);
        vm.stopPrank();

        assert(campaign != address(0));
    }

    function test_UserCan_CreateCampaign_UpdatesCampaignsArray() external {
        vm.startPrank(user);
        address campaign =
            campaignFactory.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, startAt, endAt, IMAGE);
        vm.stopPrank();

        address[] memory campaigns = campaignFactory.getAllCampaigns();

        assertEq(campaign, campaigns[0]);
    }

    function test_UserCan_CreateCampaign_UpdatesMapping() external {
        vm.startPrank(user);
        address campaign =
            campaignFactory.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, startAt, endAt, IMAGE);
        vm.stopPrank();

        address[] memory campaignsCreatedByUser = campaignFactory.getCampaignsCreatedByOwner(user);

        assertEq(campaign, campaignsCreatedByUser[0]);
    }

    function test_FunderCan_FundCampaign_UsingCampaignFactory() external {
        vm.startPrank(user);
        address campaign =
            campaignFactory.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, startAt, endAt, IMAGE);
        vm.stopPrank();

        vm.startPrank(funder);
        campaignFactory.fund{value: FUNDING_AMOUNT}(campaign);
        vm.stopPrank();

        uint256 campaignBalance = address(campaign).balance;

        assertEq(campaignBalance, FUNDING_AMOUNT);
    }

    function test_WithdrawCampaign_UsingFactory() external {
        console.log("Owner", user);
        vm.startPrank(user);
        address campaign =
            campaignFactory.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, startAt, endAt, IMAGE);
        vm.stopPrank();

        vm.startPrank(funder);
        campaignFactory.fund{value: FUNDING_AMOUNT}(campaign);
        vm.stopPrank();

        vm.warp(block.timestamp + 100000);
        vm.roll(block.number + 1);

        vm.startPrank(user);
        campaignFactory.withdraw(campaign);
        vm.stopPrank();

        uint256 campaignBalance = address(campaign).balance;

        assertEq(campaignBalance, 0);
    }
}
