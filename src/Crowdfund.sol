// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title A Decentralized Crowdfunding Platform
 * @author EP
 * @notice This contract allows users to fund a project with a goal and deadline.
 * @dev Implements security best practices like Checks-Effects-Interactions and .call for ETH transfers.
 */
contract Crowdfund {
    struct Campaign {
        uint256 goal; // Target amount to raise (in wei)
        uint256 deadline; // Timestamp when the campaign ends
        uint256 moneyRaised; // Current total raised
        address payable owner; // Creator of the campaign
    }

    Campaign public campaign;

    // Events to allow off-chain apps to react to contract changes
    event Funded(address indexed funder, uint256 amount);
    event Withdrawn(uint256 amount);
    event Refunded(address indexed funder, uint256 amount);

    // Tracks how much each individual address has contributed
    mapping(address => uint256) public funders;

    /**
     * @notice Initializes a new crowdfunding campaign
     * @param _goal The funding target in wei
     * @param _durationSeconds How long the campaign stays active from deployment
     */
    constructor(uint256 _goal, uint256 _durationSeconds) {
        campaign.owner = payable(msg.sender);
        campaign.goal = _goal;
        campaign.deadline = block.timestamp + _durationSeconds;
    }

    /**
     * @notice Allows users to contribute ETH to the campaign
     * @dev Reverts if the deadline has passed or if no ETH is sent
     */
    function fund() external payable {
        // Check if campaign is still active and that some ETH has been sent
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(msg.value > 0, "ETH must be sent");

        // Update state
        funders[msg.sender] += msg.value;
        campaign.moneyRaised += msg.value;

        emit Funded(msg.sender, msg.value);
    }

    /**
     * @notice Allows the owner to claim  the funds contributed if the goal is met and deadline has passed
     * @dev Uses the Checks-Effects-Interactions pattern to prevent Reentrancy attacks
     */
    function withdraw() external {
        // Check conditions required to proceed with withdraw
        require(campaign.deadline <= block.timestamp, "Campaign is still active");
        require(msg.sender == campaign.owner, "Only owner can withdraw");
        require(campaign.moneyRaised >= campaign.goal, "Goal not reached");

        // Update state
        uint256 amount = campaign.moneyRaised;
        campaign.moneyRaised = 0;

        // Send ETH
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(amount);
    }

    /**
     * @notice Allows contributors to claim a refund if the goal was not met
     * @dev Users must "pull" their own refunds to save contract gas and improve security
     */
    function refund() external {
        // Checks conditions required to proceed with refund
        require(campaign.deadline <= block.timestamp, "Campaign is still active");
        require(campaign.moneyRaised < campaign.goal, "Goal has been reached");
        require(funders[msg.sender] > 0, "You have not funded this campaign");

        uint256 fundedAmount = funders[msg.sender];
        funders[msg.sender] = 0; // Reset individual balance before transfer
        campaign.moneyRaised -= fundedAmount; // Update total raised

        // Complete refund
        (bool success,) = msg.sender.call{value: fundedAmount}("");
        require(success, "Refund failed");

        emit Refunded(msg.sender, fundedAmount);
    }
}
