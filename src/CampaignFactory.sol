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

//////////////////////////////////////////////////////////
//////////////////////  Imports  /////////////////////////
//////////////////////////////////////////////////////////
import {Campaign} from "./Campaign.sol";

contract CampaignFactory {
    //////////////////////////////////////////////////////////
    ////////////////////  Custom Errors  /////////////////////
    //////////////////////////////////////////////////////////
    error Campaign__StartDate_ShouldBeInPresent();
    error Campaign__InvalidTimeline();

    //////////////////////////////////////////////////////////
    ////////////////  Storage Variables  /////////////////////
    //////////////////////////////////////////////////////////
    address[] private s_campaigns;

    //////////////////////////////////////////////////////////
    //////////////////////   Events  /////////////////////////
    //////////////////////////////////////////////////////////
    event CampaignCreated(
        address indexed campaign, address indexed creator, uint256 indexed targetAmount, uint256 startAt, uint256 endAt
    );

    //////////////////////////////////////////////////////////
    //////////////////////  Functions  ///////////////////////
    //////////////////////////////////////////////////////////
    function createCampaign(
        string memory _name,
        string memory _description,
        uint256 _targetAmount,
        uint256 _startAt,
        uint256 _endAt,
        string memory _image
    ) external returns (address) {
        if (_startAt < block.timestamp) {
            revert Campaign__StartDate_ShouldBeInPresent();
        }
        if (_endAt < _startAt) {
            revert Campaign__InvalidTimeline();
        }

        Campaign campaign = new Campaign(_name, _description, _targetAmount, _startAt, _endAt, _image);
        campaigns.push(address(campaign));

        emit CampaignCreated(address(campaign), msg.sender, _targetAmount, _startAt, _endAt);

        return address(campaign);
    }

    function fund(address campaign, uint256 amount) external {
        Campaign(payable(campaign)).fund(amount);
    }

    function withDraw(address campaign) external {
        Campaign(payable(campaign)).withdraw();
    }

    //////////////////////////////////////////////////////////
    //////////////////  Getter Functions  ////////////////////
    //////////////////////////////////////////////////////////
    function getAllCampaigns() external view returns (address[] memory) {
        return s_campaigns;
    }
}
