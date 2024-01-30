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
import {console} from "forge-std/console.sol";

contract CampaignFactory {
    //////////////////////////////////////////////////////////
    ////////////////////  Custom Errors  /////////////////////
    //////////////////////////////////////////////////////////
    error CampaignFactory__StartDate_ShouldBeInPresent();
    error CampaignFactory__InvalidTimeline();

    //////////////////////////////////////////////////////////
    ////////////////  Storage Variables  /////////////////////
    //////////////////////////////////////////////////////////
    mapping(address owner => address[] campaigns) private s_addressToCampaigns;
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
            revert CampaignFactory__StartDate_ShouldBeInPresent();
        }
        if (_endAt < _startAt) {
            revert CampaignFactory__InvalidTimeline();
        }

        Campaign campaign = new Campaign(msg.sender, _name, _description, _targetAmount, _startAt, _endAt, _image);

        s_campaigns.push(address(campaign));

        s_addressToCampaigns[msg.sender].push(address(campaign));

        emit CampaignCreated(address(campaign), msg.sender, _targetAmount, _startAt, _endAt);

        return address(campaign);
    }

    function fund(address campaign) external payable {
        Campaign(payable(campaign)).fund{value: msg.value}(msg.sender);
    }

    function withdraw(address campaign) external {
        Campaign(payable(campaign)).withdraw(msg.sender);
    }

    //////////////////////////////////////////////////////////
    //////////////////  Getter Functions  ////////////////////
    //////////////////////////////////////////////////////////
    function getAllCampaigns() external view returns (address[] memory) {
        return s_campaigns;
    }

    function getCampaignsCreatedByOwner(address owner) external view returns (address[] memory) {
        console.log(s_addressToCampaigns[owner].length);
        return s_addressToCampaigns[owner];
    }
}
