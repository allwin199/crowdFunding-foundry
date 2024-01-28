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
contract Campaign {
    //////////////////////////////////////////////////////////
    ////////////////////  Custom Errors  /////////////////////
    //////////////////////////////////////////////////////////
    error Campaign__StartDate_ShouldBeInPresent();
    error Campaign__InvalidTimeline();
    error Campaign__OnlyOwner_CanWithdraw();
    error Campaign__CampaignNotEnded();
    error Campaign__WithdrawFailed();
    error Campaign__FundingWith_ZeroAmount();
    error Campaign__InvalidCampaign();
    error Campaign__CampaignAlreadyEnded();
    error Campaign__AmountAlreadyWithdrawn();

    //////////////////////////////////////////////////////////
    ////////////////  Storage Variables  /////////////////////
    //////////////////////////////////////////////////////////

    address payable immutable i_creator;
    string private s_name;
    string private s_description;
    uint256 private immutable i_targetAmount;
    uint256 private s_amountCollected;
    uint256 private immutable i_startAt;
    uint256 private immutable i_endAt;
    string private s_image;
    address[] private s_funders;
    mapping(address funder => uint256 amount) private s_addressToAmountFunded;
    bool private s_claimedByOwner;

    //////////////////////////////////////////////////////////
    //////////////////////   Events  /////////////////////////
    //////////////////////////////////////////////////////////
    // event CampaignCreated(
    //     uint256 indexed campaignId,
    //     address indexed creator,
    //     uint256 indexed targetAmount,
    //     uint256 startAt,
    //     uint256 endAt
    // );
    event CampaignFunded(address indexed campaign, address indexed funder, uint256 indexed amount);
    event WithdrawSuccessful(address indexed campaign, address indexed owner, uint256 indexed amount);

    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }

    //////////////////////////////////////////////////////////
    //////////////////////  Functions  ///////////////////////
    //////////////////////////////////////////////////////////

    constructor(
        string memory name,
        string memory description,
        uint256 targetAmount,
        uint256 startAt,
        uint256 endAt,
        string memory image
    ) {
        i_creator = payable(msg.sender);
        s_name = name;
        s_description = description;
        i_targetAmount = targetAmount;
        i_startAt = startAt;
        i_endAt = endAt;
        s_image = image;
    }

    // function createCampaign(
    //     string memory _name,
    //     string memory _description,
    //     uint256 _targetAmount,
    //     uint256 _startAt,
    //     uint256 _endAt,
    //     string memory _image
    // ) external returns (uint256) {
    //     if (_startAt < block.timestamp) {
    //         revert CrowdFunding__StartDate_ShouldBeInPresent();
    //     }
    //     if (_endAt < _startAt) {
    //         revert CrowdFunding__InvalidTimeline();
    //     }

    //     s_campaigns[s_campaignsCount] = Campaign({
    //         creator: payable(msg.sender),
    //         name: _name,
    //         description: _description,
    //         targetAmount: _targetAmount,
    //         amountCollected: 0,
    //         startAt: _startAt,
    //         endAt: _endAt,
    //         image: _image,
    //         funders: new address[](0),
    //         claimedByOwner: false
    //     });

    //     emit CampaignCreated(s_campaignsCount, msg.sender, _targetAmount, _startAt, _endAt);

    //     s_campaignsCount = s_campaignsCount + 1;

    //     return s_campaignsCount - 1;
    // }

    function fund(uint256 amount) external payable {
        if (amount == 0) {
            revert Campaign__FundingWith_ZeroAmount();
        }

        // if (s_campaigns[campaignId].creator == address(0)) {
        //     revert CrowdFunding__InvalidCampaign();
        // }

        // if (s_campaigns[campaignId].claimedByOwner) {
        //     revert CrowdFunding__CampaignAlreadyEnded();
        // }

        uint8 newFunder = 1;

        address[] memory funders = s_funders;

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
            s_funders.push(msg.sender);
        }

        emit CampaignFunded(address(this), msg.sender, amount);
    }

    function withdraw() external {
        address owner = i_creator;
        if (owner != msg.sender) {
            revert Campaign__OnlyOwner_CanWithdraw();
        }

        if (i_endAt > block.timestamp) {
            revert Campaign__CampaignNotEnded();
        }

        if (s_claimedByOwner) {
            revert Campaign__AmountAlreadyWithdrawn();
        }

        s_claimedByOwner = true;

        emit WithdrawSuccessful(address(this), msg.sender, address(this).balance);

        (bool sent,) = payable(owner).call{value: address(this).balance}("");
        if (!sent) {
            revert Campaign__WithdrawFailed();
        }
    }

    //////////////////////////////////////////////////////////
    //////////////////  Getter Functions  ////////////////////
    //////////////////////////////////////////////////////////
    // function getTotalCampaigns() external view returns (uint256) {
    //     return s_campaignsCount - 1;
    //     // since s_campaignsCount starting from 1
    //     // to get the actual campaignCount we have to subtract by 1
    // }

    // function getCampaigns() external view returns (Campaign[] memory) {
    //     Campaign[] memory allCampaigns = new Campaign[](s_campaignsCount);

    //     for (uint256 i = 0; i < s_campaignsCount;) {
    //         allCampaigns[i] = s_campaigns[i];

    //         unchecked {
    //             ++i;
    //         }
    //     }

    //     return allCampaigns;
    // }

    // function getCampaign(uint256 campaignId) external view returns (Campaign memory) {
    //     return s_campaigns[campaignId];
    // }

    // function getFunders(uint256 campaignId) external view returns (address[] memory) {
    //     address[] memory funders = s_campaigns[campaignId].funders;
    //     return funders;
    // }

    // function getFunderInfo(uint256 campaignId, address funder) external view returns (uint256) {
    //     return s_addressToAmountFundedByCampaign[campaignId][funder];
    // }
}