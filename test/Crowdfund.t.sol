// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Crowdfund} from "../src/Crowdfund.sol";

contract CrowdfundTest is Test {
    Crowdfund public crowdfund;

    uint256 public campaignId;

    // Test constants
    address public owner = address(1);
    address public alice = address(2);
    address public bob = address(3);
    uint256 public constant GOAL = 10 ether;
    uint256 public constant DURATION = 1 days;

    // Events (re-declared here to test emissions)
    event Funded(uint256 indexed campaignId, address indexed funder, uint256 amount);
    event Withdrawn(uint256 indexed campaignId, uint256 amount);
    event Refunded(uint256 indexed campaignId, address indexed funder, uint256 amount);


    function setUp() public {
        // Deploy contract
        crowdfund = new Crowdfund();
        campaignId = 0;

        // Deploy as the "owner" address
        vm.prank(owner);
        crowdfund.createCampaign(GOAL, DURATION);

        // Give users some money
        vm.deal(alice, 20 ether);
        vm.deal(bob, 5 ether);

        
    }

    // --- Constructor Tests ---

    function test_DeploymentState() public {
        vm.prank(owner);
        crowdfund.createCampaign(GOAL, DURATION);
      
        (
            uint256 goal, 
            uint256 deadline, 
            uint256 raised, 
            address payable campaignOwner,
        ) = crowdfund.campaigns(campaignId);

        assertEq(goal, GOAL);
        assertEq(deadline, block.timestamp + DURATION);
        assertEq(raised, 0);
        assertEq(campaignOwner, owner);
    }

    // --- Funding Tests ---

    function test_FundSuccess() public {
        vm.prank(alice);

        // Check event emission: (checkTopic1, checkTopic2, checkTopic3, checkData)
        vm.expectEmit(true, true, false, true);
        emit Funded(campaignId, alice, 5 ether);

        crowdfund.fund{value: 5 ether}(campaignId);

        assertEq(crowdfund.campaignFunders(campaignId, alice), 5 ether);

        (,, uint256 raised,,) = crowdfund.campaigns(campaignId);
        assertEq(raised, 5 ether);
    }

    function test_Revert_FundAfterDeadline() public {
        vm.warp(block.timestamp + DURATION + 1); // Move time past deadline
        vm.prank(alice);
        vm.expectRevert("Campaign has ended");
        crowdfund.fund{value: 1 ether}(campaignId);
    }

    function test_Revert_FundWithZeroValue() public {
        vm.prank(alice);
        vm.expectRevert("ETH must be sent");
        crowdfund.fund{value: 0}(campaignId);
    }

    // --- Withdrawal Tests ---

    function test_WithdrawSuccess() public {
        // 1. Setup: Reach goal
        vm.prank(alice);
        crowdfund.fund{value: 10 ether}(campaignId);

        // 2. Warp past deadline
        vm.warp(block.timestamp + DURATION);

        // 3. Owner withdraws
        uint256 ownerBalanceBefore = owner.balance;

        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit Withdrawn(campaignId, 10 ether);
        
        crowdfund.withdraw(campaignId);

        assertEq(owner.balance, ownerBalanceBefore + 10 ether);
        (,, uint256 raised,,) = crowdfund.campaigns(campaignId);
        assertEq(raised, 0); // Check state reset
    }

    function test_Revert_WithdrawWhileActive() public {
        vm.prank(owner);
        vm.expectRevert("Campaign is still active");
        crowdfund.withdraw(campaignId);
    }

    function test_Revert_WithdrawByNonOwner() public {
        vm.warp(block.timestamp + DURATION);
        vm.prank(alice);
        vm.expectRevert("Only owner can withdraw");
        crowdfund.withdraw(campaignId);
    }

    function test_Revert_WithdrawGoalNotReached() public {
        vm.prank(alice);
        crowdfund.fund{value: 5 ether}(campaignId);

        vm.warp(block.timestamp + DURATION);

        vm.prank(owner);
        vm.expectRevert("Goal not reached");
        crowdfund.withdraw(campaignId);
    }

    // --- Refund Tests ---

    function test_RefundSuccess() public {
        // 1. Setup: Goal not reached
        vm.prank(alice);
        crowdfund.fund{value: 5 ether}(campaignId);

        vm.warp(block.timestamp + DURATION);

        // 2. Alice claims refund
        uint256 aliceBalanceBefore = alice.balance;

        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit Refunded(campaignId, alice, 5 ether);
        crowdfund.refund(campaignId);

        assertEq(alice.balance, aliceBalanceBefore + 5 ether);
        assertEq(crowdfund.campaignFunders(campaignId, alice), 0);
        (,, uint256 raised,,) = crowdfund.campaigns(campaignId);
        assertEq(raised, 0);
    }

    function test_Revert_RefundWhileActive() public {
        vm.prank(alice);
        crowdfund.fund{value: 5 ether}(campaignId);

        vm.prank(alice);
        vm.expectRevert("Campaign is still active");
        crowdfund.refund(campaignId);
    }

    function test_Revert_RefundIfGoalReached() public {
        vm.prank(alice);
        crowdfund.fund{value: 10 ether}(campaignId);

        vm.warp(block.timestamp + DURATION);

        vm.prank(alice);
        vm.expectRevert("Goal has been reached");
        crowdfund.refund(campaignId);
    }

    function test_Revert_RefundIfZeroContribution() public {
        vm.warp(block.timestamp + DURATION);

        vm.prank(bob); // Bob never funded
        vm.expectRevert("You have not funded this campaign");
        crowdfund.refund(campaignId);
    }

    function test_Revert_InvalidId_Fund() public {
        vm.prank(alice);
        vm.expectRevert("Invalid Campaign ID");
        crowdfund.fund{value: 1 ether}(999); // ID 999 doesn't exist
    }

    function test_Revert_InvalidId_Withdraw() public {
        vm.expectRevert("Invalid Campaign ID");
        crowdfund.withdraw(999);
    }

    function test_Revert_InvalidId_Refund() public {
        vm.expectRevert("Invalid Campaign ID");
        crowdfund.refund(999);
    }

    function test_CampaignIsolation() public {
        // Create a second campaign
        vm.prank(bob);
        crowdfund.createCampaign(20 ether, DURATION); // This will be ID 1
        
        // Alice funds Campaign 0
        vm.prank(alice);
        crowdfund.fund{value: 5 ether}(0);
        
        // Check that Campaign 1 is still at 0
        (,, uint256 raised1,,) = crowdfund.campaigns(1);
        assertEq(raised1, 0, "Campaign 1 should not have funds from Campaign 0");
    }

    
    function test_MultipleContributions() public {
        vm.startPrank(alice);
        crowdfund.fund{value: 1 ether}(0);
        crowdfund.fund{value: 2 ether}(0);
        vm.stopPrank();

        assertEq(crowdfund.campaignFunders(0, alice), 3 ether);
    }

    function test_Revert_WithdrawTransferFailed() public {
        Rejector rejector = new Rejector();
        vm.prank(address(rejector));
        crowdfund.createCampaign(GOAL, DURATION); // ID 1
        
        crowdfund.fund{value: GOAL}(1);
        vm.warp(block.timestamp + DURATION);
        
        vm.prank(address(rejector));
        vm.expectRevert("Refund failed"); // withdraw uses "Transfer failed"
        crowdfund.withdraw(1);
    }

    function test_Revert_RefundTransferFailed() public {
        Rejector rejector = new Rejector();
        vm.deal(address(rejector), 1 ether);
        
        vm.prank(address(rejector));
        crowdfund.fund{value: 1 ether}(0);
        
        vm.warp(block.timestamp + DURATION);
        
        vm.prank(address(rejector));
        vm.expectRevert("Refund failed"); // refund uses "Refund failed"
        crowdfund.refund(0);
    }
}

contract Rejector {
    // This contract has no receive() or fallback() function.
    // Therefore, any ETH sent to it via .call will fail.

    function performWithdraw(address target, uint256 id) external {
        Crowdfund(target).withdraw(id);
    }

    function performRefund(address target, uint256 id) external {
        Crowdfund(target).refund(id);
    }
}
