// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Campaign} from "./Campaign.sol";

contract CampaignFactory {
    event CampaignCreated(
        address indexed campaign, address indexed creator, uint256 indexed targetAmount, uint256 startAt, uint256 endAt
    );

    error Campaign__StartDate_ShouldBeInPresent();
    error Campaign__InvalidTimeline();

    address[] private campaigns;

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
}
