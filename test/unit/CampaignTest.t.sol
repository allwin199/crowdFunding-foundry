// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
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

    //////////////////////////////////////////////////////////
    //////////////////////   Events  /////////////////////////
    //////////////////////////////////////////////////////////
    event CampaignFunded(address indexed campaign, address indexed funder, uint256 indexed amount);
    event WithdrawSuccessful(address indexed campaign, address indexed owner, uint256 indexed amount);

    function setUp() external {
        vm.startPrank(user);
        campaign = new Campaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, startAt, endAt, IMAGE);
        vm.stopPrank();

        // let's give funds to the user
        vm.deal(user, STARTING_BALANCE);
        vm.deal(funder, STARTING_BALANCE);
    }

    //////////////////////////////////////////////////////////
    ///////////////////////  Fund Tests  /////////////////////
    //////////////////////////////////////////////////////////

    function test_RevertsIf_FundingAmount_IsZero() external {
        vm.startPrank(funder);

        vm.expectRevert(Campaign.Campaign__FundingWith_ZeroAmount.selector);
        campaign.fund();

        vm.stopPrank();
    }

    function test_FunderCanFund() external {
        vm.startPrank(funder);
        campaign.fund{value: FUNDING_AMOUNT}();
        vm.stopPrank();
    }

    modifier CampaignFundedByFunder() {
        vm.startPrank(funder);
        campaign.fund{value: FUNDING_AMOUNT}();
        vm.stopPrank();
        _;
    }

    function test_FunderCanFund_UpdatesCampaignBalance() external CampaignFundedByFunder {
        uint256 campaignBalance = address(campaign).balance;
        assertEq(campaignBalance, FUNDING_AMOUNT);
    }

    function test_FunderCanFund_UpdatesFunderBalance() external CampaignFundedByFunder {
        uint256 funderBalance = campaign.getFunderInfo(funder);
        assertEq(funderBalance, FUNDING_AMOUNT);
    }

    function test_FunderCanFund_UpdatesFunders() external CampaignFundedByFunder {
        address[] memory funders = campaign.getFunders();
        assertEq(funders[0], funder);
    }

    function test_FunderCanFund_EmitsEvent() external {
        vm.startPrank(funder);

        vm.expectEmit(true, true, true, false, address(campaign));
        emit CampaignFunded(address(campaign), funder, FUNDING_AMOUNT);
        campaign.fund{value: FUNDING_AMOUNT}();

        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////
    ////////////////////  Withdraw Tests  ////////////////////
    //////////////////////////////////////////////////////////

    function test_RevertsIf_WithdrawNotCalled_ByOwner() public CampaignFundedByFunder {
        vm.startPrank(funder);
        vm.expectRevert(Campaign.Campaign__OnlyOwner_CanWithdraw.selector);
        campaign.withdraw();
        vm.stopPrank();
    }

    function test_RevertsIf_WithdrawCalled_BeforeEndDate() public CampaignFundedByFunder {
        vm.startPrank(user);
        vm.expectRevert(Campaign.Campaign__CampaignNotEnded.selector);
        campaign.withdraw();
        vm.stopPrank();
    }

    function test_OwnerCan_Withdraw() public CampaignFundedByFunder {
        vm.warp(block.timestamp + 100000);
        vm.roll(block.number + 1);

        vm.startPrank(user);
        campaign.withdraw();
        vm.stopPrank();
    }

    function test_OwnerCan_Withdraw_UpdatesOwnerBalance() public CampaignFundedByFunder {
        vm.warp(block.timestamp + 100000);
        vm.roll(block.number + 1);

        uint256 startingOwnerBalance = address(user).balance;
        uint256 campaignBalance = address(campaign).balance;

        vm.startPrank(user);
        campaign.withdraw();
        vm.stopPrank();

        uint256 endingOwnerBalance = address(user).balance;

        assertEq(endingOwnerBalance, startingOwnerBalance + campaignBalance);
    }

    function test_RevertsIf_OwnerAlready_Withdrawn() public CampaignFundedByFunder {
        vm.warp(block.timestamp + 100000);
        vm.roll(block.number + 1);

        vm.startPrank(user);
        campaign.withdraw();
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(Campaign.Campaign__AmountAlreadyWithdrawn.selector);
        campaign.withdraw();
        vm.stopPrank();
    }

    function test_OwnerCanWithdraw_EmitsEvent() external CampaignFundedByFunder {
        vm.warp(block.timestamp + 100000);
        vm.roll(block.number + 1);

        vm.startPrank(user);

        vm.expectEmit(true, true, true, false, address(campaign));
        emit WithdrawSuccessful(address(campaign), user, address(campaign).balance);
        campaign.withdraw();

        vm.stopPrank();
    }

    modifier multipleFunding() {
        for (uint160 i = 2; i < 6; i++) {
            hoax(address(i), STARTING_BALANCE);
            campaign.fund{value: FUNDING_AMOUNT}();
        }
        vm.warp(block.timestamp + 100000);
        vm.roll(block.number + 1);
        _;
    }

    function test_OwnerCanWithdraw_AfterMultipleFunding_UpdatesOwnerBalance()
        external
        CampaignFundedByFunder
        multipleFunding
    {
        uint256 startingOwnerBalance = address(user).balance;
        uint256 campaignBalance = address(campaign).balance;

        vm.startPrank(user);
        campaign.withdraw();
        vm.stopPrank();

        uint256 endingOwnerBalance = address(user).balance;

        assertEq(endingOwnerBalance, startingOwnerBalance + campaignBalance);
    }

    function test_OwnerCanWithdraw_AfterMultipleFunding_UpdatesCampaignBalance()
        external
        CampaignFundedByFunder
        multipleFunding
    {
        vm.startPrank(user);
        campaign.withdraw();
        vm.stopPrank();

        uint256 endingCampaignBalance = address(campaign).balance;

        assertEq(endingCampaignBalance, 0);
    }

    function test_RevertsIf_CampaignAlreadyEnded() public CampaignFundedByFunder {
        vm.warp(block.timestamp + 100000);
        vm.roll(block.number + 1);

        vm.startPrank(user);
        campaign.withdraw();
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(Campaign.Campaign__CampaignAlreadyEnded.selector);
        campaign.fund{value: FUNDING_AMOUNT}();
        vm.stopPrank();
    }

    function test_FunderCanFund_UsingFallback() public {
        vm.startPrank(user);

        (bool success,) = address(campaign).call{value: FUNDING_AMOUNT}("");
        // funding using fallback method
        // since we haven't mentioned any specific function name to call
        // fallback will be called because callData is empty

        vm.stopPrank();

        assertTrue(success);

        uint256 campaignBalance = address(campaign).balance;
        assertEq(campaignBalance, FUNDING_AMOUNT);
    }
}
