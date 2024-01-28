// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {DeployCrowdFunding} from "../script/DeployCrowdFunding.s.sol";
import {CrowdFunding} from "../src/CrowdFunding.sol";

contract CrowdFundingTest is Test {
    //////////////////////////////////////////////////////////
    ////////////////  Storage Variables  /////////////////////
    //////////////////////////////////////////////////////////

    DeployCrowdFunding private deployer;
    CrowdFunding private crowdFunding;

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
    event CamapignFunded(uint256 indexed campaignId, address indexed funder, uint256 indexed amount);
    event WithdrawSuccessful(uint256 indexed campaignId, address indexed owner, uint256 indexed amount);

    function setUp() external {
        deployer = new DeployCrowdFunding();
        crowdFunding = deployer.run();

        // let's give funds to the user
        vm.deal(user, STARTING_BALANCE);
        vm.deal(funder, STARTING_BALANCE);
    }

    //////////////////////////////////////////////////////////
    ///////////////  Create Campaign Tests  //////////////////
    //////////////////////////////////////////////////////////

    function test_TotalCampaigns_IsZero() public {
        uint256 totalCampaigns = crowdFunding.getTotalCampaigns();
        assertEq(totalCampaigns, 0);
    }

    function test_RevertsIf_CreateCampaign_StartDateIs_NotInPresent() public {
        vm.startPrank(user);
        vm.warp(block.timestamp + 100);
        vm.roll(block.number + 1);
        vm.expectRevert(CrowdFunding.CrowdFunding__StartDate_ShouldBeInPresent.selector);
        crowdFunding.createCampaign(
            CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, (block.timestamp) - 50, endAt, IMAGE
        );
        vm.stopPrank();
    }

    function test_RevertsIf_CreateCampaign_EndDateLessThan_StartDate() public {
        vm.startPrank(user);
        vm.warp(block.timestamp + 100);
        vm.roll(block.number + 1);
        vm.expectRevert(CrowdFunding.CrowdFunding__InvalidTimeline.selector);
        crowdFunding.createCampaign(
            CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, (block.timestamp), (block.timestamp) - 50, IMAGE
        );
        vm.stopPrank();
    }

    function test_UserCan_CreateCampaign_ReturnsCamapignId() public {
        vm.startPrank(user);
        crowdFunding.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, startAt, endAt, IMAGE);
        vm.stopPrank();

        uint256 totalCampaigns = crowdFunding.getTotalCampaigns();

        assertEq(totalCampaigns, 1);
    }

    function test_UserCan_CreateCampaign_EmitsEvent() public {
        uint256 totalCampaigns = crowdFunding.getTotalCampaigns();
        vm.startPrank(user);
        vm.expectEmit(true, true, true, false, address(crowdFunding)); // crowFunding contract will emit this event
        emit CampaignCreated(totalCampaigns + 1, user, TARGET_AMOUNT, startAt, endAt);
        crowdFunding.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, startAt, endAt, IMAGE);
        vm.stopPrank();
    }

    modifier CampaignCreatedByUser() {
        vm.startPrank(user);
        crowdFunding.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, startAt, endAt, IMAGE);
        vm.stopPrank();
        _;
    }

    function test_CampaignCount_IncreasesAfter_CamapignCreation() public CampaignCreatedByUser {
        uint256 totalCampaigns = crowdFunding.getTotalCampaigns();
        assertEq(totalCampaigns, 1);
    }

    //////////////////////////////////////////////////////////
    ///////////////  Funding Campaign Tests  /////////////////
    //////////////////////////////////////////////////////////

    function test_RevertsIf_FundingAmount_IsZero() public CampaignCreatedByUser {
        vm.startPrank(funder);
        vm.expectRevert(CrowdFunding.CrowdFunding__FundingWith_ZeroAmount.selector);
        crowdFunding.fundCampaign(1, 0);
        vm.stopPrank();
    }

    function test_RevertsIf_FundingAn_InvalidCampaign() public {
        vm.startPrank(funder);
        vm.expectRevert();
        crowdFunding.fundCampaign(10, FUNDING_AMOUNT);
        vm.stopPrank();
    }

    function test_FunderCan_FundCampaign() public CampaignCreatedByUser {
        vm.startPrank(funder);
        crowdFunding.fundCampaign(1, FUNDING_AMOUNT);
        vm.stopPrank();

        address[] memory fundersList = crowdFunding.getFunders(1);
        assertEq(fundersList[0], funder);
    }

    function test_FunderCan_FundCampaignAnd_UpdatesBalance() public CampaignCreatedByUser {
        vm.startPrank(funder);
        crowdFunding.fundCampaign(1, FUNDING_AMOUNT);
        vm.stopPrank();

        uint256 totalAmountInCampaign = crowdFunding.getCampaign(1).amountCollected;
        assertEq(totalAmountInCampaign, FUNDING_AMOUNT);
    }

    function test_FunderCan_FundCampaignAnd_UpdatesFundersMapping() public CampaignCreatedByUser {
        vm.startPrank(funder);
        crowdFunding.fundCampaign(1, FUNDING_AMOUNT);
        vm.stopPrank();

        uint256 funderFunded = crowdFunding.getFunderInfo(1, funder);
        assertEq(funderFunded, FUNDING_AMOUNT);
    }

    function test_FunderCan_FundCampaign_EmitsEvent() public CampaignCreatedByUser {
        vm.startPrank(funder);

        vm.expectEmit(true, true, true, false, address(crowdFunding));
        emit CamapignFunded(1, funder, FUNDING_AMOUNT);
        crowdFunding.fundCampaign(1, FUNDING_AMOUNT);

        vm.stopPrank();
    }
}
