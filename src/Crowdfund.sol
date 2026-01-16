// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Multi-Campaign Decentralized Crowdfunding Registry
 * @author EP
 * @notice This contract acts as a platform where multiple users can create, manage, and fund independent crowdfunding campaigns.
 * @dev Manages campaign isolation via nested mappings and ensures security through the Checks-Effects-Interactions pattern.
 */
contract Crowdfund {
    struct Campaign {
        uint256 goal; // Target amount to raise (in wei)
        uint256 deadline; // Timestamp when the campaign ends
        uint256 moneyRaised; // Current total raised
        address payable owner; // Creator of the campaign
        uint256 campaignId;
    }

    mapping(uint256 => Campaign) public campaigns;
    uint256 campaignCount = 0;

    // Events to allow off-chain apps to react to contract changes
    event Funded(uint256 indexed campaignId, address indexed funder, uint256 amount);
    event Withdrawn(uint256 indexed campaignId, uint256 amount);
    event Refunded(uint256 indexed campaignId, address indexed funder, uint256 amount);

    // Tracks how much each individual address has contributed to each campaign
    mapping(uint256 => mapping(address => uint256)) public campaignFunders;

    /**
     * @notice Creates a new crowdfunding campaign and stores it in the registry
     * @dev Increments campaignCount to ensure every campaign has a unique ID
     * @param _goal The funding target in wei
     * @param _durationSeconds How long the campaign stays active from the block timestamp
     */
    function createCampaign(uint256 _goal, uint256 _durationSeconds) public {
        // Creates new campaign in the mapping at the current count
        campaigns[campaignCount] = Campaign({
            goal: _goal,
            deadline: block.timestamp + _durationSeconds,
            moneyRaised: 0,
            owner: payable(msg.sender),
            campaignId: campaignCount
        });

        // Increments campaign count so that next campaign created gets a new ID
        campaignCount++;
    }

    /**
     * @notice Allows users to contribute ETH to a specific campaign
     * @dev Updates the nested mapping to track individual contributions per ID
     * @param _id The unique identifier of the campaign to fund
     */
    function fund(uint256 _id) external payable {
        require(_id < campaignCount, "Invalid Campaign ID");

        // pointer to the specific campaign in storage
        Campaign storage c = campaigns[_id];

        // Check if campaign is still active and that some ETH has been sent
        require(block.timestamp < c.deadline, "Campaign has ended");
        require(msg.value > 0, "ETH must be sent");

        // Update state
        campaignFunders[_id][msg.sender] += msg.value;
        c.moneyRaised += msg.value;

        emit Funded(_id, msg.sender, msg.value);
    }

    /**
     * @notice Allows a campaign owner to claim funds if their specific goal was met
     * @dev Follows Checks-Effects-Interactions to prevent reentrancy
     * @param _id The unique identifier of the campaign to withdraw from
     */
    function withdraw(uint256 _id) external {
        require(_id < campaignCount, "Invalid Campaign ID");

        // pointer to the specific campaign in storage
        Campaign storage c = campaigns[_id];

        // Check conditions required to proceed with withdraw
        require(c.deadline <= block.timestamp, "Campaign is still active");
        require(msg.sender == c.owner, "Only owner can withdraw");
        require(c.moneyRaised >= c.goal, "Goal not reached");

        // Update state
        uint256 amount = c.moneyRaised;
        c.moneyRaised = 0;

        // Send ETH
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Refund failed");

        emit Withdrawn(_id, amount);
    }

    /**
     * @notice Allows contributors to claim a refund if a specific campaign failed
     * @dev Users must "pull" their own refunds to maintain contract security
     * @param _id The unique identifier of the campaign to get a refund from
     */
    function refund(uint256 _id) external {
        require(_id < campaignCount, "Invalid Campaign ID");

        // pointer to the specific campaign in storage
        Campaign storage c = campaigns[_id];

        // Checks conditions required to proceed with refund
        require(c.deadline <= block.timestamp, "Campaign is still active");
        require(c.moneyRaised < c.goal, "Goal has been reached");
        require(campaignFunders[_id][msg.sender] > 0, "You have not funded this campaign");

        uint256 fundedAmount = campaignFunders[_id][msg.sender];
        campaignFunders[_id][msg.sender] = 0; // Reset individual balance before transfer
        c.moneyRaised -= fundedAmount; // Update total raised

        // Complete refund
        (bool success,) = msg.sender.call{value: fundedAmount}("");
        require(success, "Refund failed");

        emit Refunded(_id, msg.sender, fundedAmount);
    }
}

