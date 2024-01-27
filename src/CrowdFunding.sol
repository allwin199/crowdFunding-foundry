// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title Crowfunding Contract
/// @author Prince Allwin
/// @notice User can create a campaign and funders can fund the campaign
contract CrowdFunding {
    //////////////////////////////////////////////////////////
    ////////////////////  Custom Errors  /////////////////////
    //////////////////////////////////////////////////////////
    error CrowdFunding__StartDate_ShouldBeInPresent();
    error CrowdFunding__InvalidTimeline();

    //////////////////////////////////////////////////////////
    ////////////////  Type Declarations  /////////////////////
    //////////////////////////////////////////////////////////
    struct Campaign {
        address payable creator;
        string name;
        string description;
        uint256 targetAmount;
        uint32 startAt;
        uint32 endAt;
        string image;
        address[] funders;
        bool claimedByOwner;
    }

    //////////////////////////////////////////////////////////
    ////////////////  Storage Variables  /////////////////////
    //////////////////////////////////////////////////////////
    uint256 private s_campaignCount = 1;
    mapping(uint256 campaignId => Campaign) private s_campaigns;
    mapping(uint256 campaignId => mapping(address funders => uint256 amount)) s_addressToAmountFundedByCampaign;

    //////////////////////////////////////////////////////////
    //////////////////////   Events  /////////////////////////
    //////////////////////////////////////////////////////////
    event CampaignPublished(
        uint256 indexed campaignId, address indexed creator, uint256 indexed targetAmount, uint32 startAt, uint32 endAt
    );
    event CamapignFunded(uint256 indexed campaignId, address indexed funder, uint256 indexed amount);

    //////////////////////////////////////////////////////////
    //////////////////////  Functions  ///////////////////////
    //////////////////////////////////////////////////////////
    function createCampaign(
        string memory _name,
        string memory _description,
        uint256 _targetAmount,
        uint32 _startAt,
        uint32 _endAt,
        string memory _image
    ) external returns (uint256) {
        if (_startAt < block.timestamp) {
            revert CrowdFunding__StartDate_ShouldBeInPresent();
        }
        if (_startAt < _endAt) {
            revert CrowdFunding__InvalidTimeline();
        }

        s_campaigns[s_campaignCount] = Campaign({
            creator: payable(msg.sender),
            name: _name,
            description: _description,
            targetAmount: _targetAmount,
            startAt: _startAt,
            endAt: _endAt,
            image: _image,
            funders: new address[](0),
            claimedByOwner: false
        });

        emit CampaignPublished(s_campaignCount, msg.sender, _targetAmount, _startAt, _endAt);

        return s_campaignCount;
    }

    function fundCampaign(uint256 campaignId, uint256 amount) external payable {
        uint8 newFunder = 1;

        address[] memory funders = s_campaigns[campaignId].funders;

        for (uint256 i = 0; i < funders.length;) {
            if (funders[i] == msg.sender) {
                newFunder = 2;
                break;
            }

            unchecked {
                ++i;
            }
        }

        if (newFunder == 1) {
            s_campaigns[campaignId].funders.push(msg.sender);
        }

        s_addressToAmountFundedByCampaign[campaignId][msg.sender] =
            s_addressToAmountFundedByCampaign[campaignId][msg.sender] + amount;

        emit CamapignFunded(campaignId, msg.sender, amount);
    }

    // owner can withdraw
}
