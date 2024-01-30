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
    error Campaign__OnlyOwner_CanWithdraw();
    error Campaign__CampaignNotEnded();
    error Campaign__WithdrawFailed();
    error Campaign__FundingWith_ZeroAmount();
    error Campaign__CampaignAlreadyEnded();
    error Campaign__AmountAlreadyWithdrawn();

    //////////////////////////////////////////////////////////
    ////////////////  Storage Variables  /////////////////////
    //////////////////////////////////////////////////////////
    address payable immutable i_creator;
    string private s_name;
    string private s_description;
    uint256 private immutable i_targetAmount;
    uint256 private immutable i_startAt;
    uint256 private immutable i_endAt;
    string private s_image;
    address[] private s_funders;
    mapping(address funder => uint256 amount) private s_addressToAmountFunded;
    bool private s_claimedByOwner;

    //////////////////////////////////////////////////////////
    //////////////////////   Events  /////////////////////////
    //////////////////////////////////////////////////////////
    event CampaignFunded(address indexed campaign, address indexed funder, uint256 indexed amount);
    event WithdrawSuccessful(address indexed campaign, address indexed owner, uint256 indexed amount);

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

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        if (msg.value == 0) {
            revert Campaign__FundingWith_ZeroAmount();
        }

        if (s_claimedByOwner) {
            revert Campaign__CampaignAlreadyEnded();
        }

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

        s_addressToAmountFunded[msg.sender] = msg.value;

        emit CampaignFunded(address(this), msg.sender, msg.value);
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
    function getFunders() external view returns (address[] memory) {
        return s_funders;
    }

    function getFunderInfo(address funder) external view returns (uint256 amount) {
        return s_addressToAmountFunded[funder];
    }
}
