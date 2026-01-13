// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Crowdfund} from "../src/Crowdfund.sol";

contract CrowdfundTest is Test {
    Crowdfund public crowdfund;

    // Test constants
    address public owner = address(1);
    address public alice = address(2);
    address public bob = address(3);
    uint256 public constant GOAL = 10 ether;
    uint256 public constant DURATION = 1 days;

    // Events (re-declared here to test emissions)
    event Funded(address indexed funder, uint256 amount);
    event Withdrawn(uint256 amount);
    event Refunded(address indexed funder, uint256 amount);

    function setUp() public {
        // Deploy as the "owner" address
        vm.prank(owner);
        crowdfund = new Crowdfund(GOAL, DURATION);

        // Give users some money
        vm.deal(alice, 20 ether);
        vm.deal(bob, 5 ether);
    }

    // --- Constructor Tests ---

    function test_DeploymentState() public view {
        (uint256 goal, uint256 deadline, uint256 raised, address payable campaignOwner) = crowdfund.campaign();
        assertEq(goal, GOAL);
        assertEq(deadline, block.timestamp + DURATION);
        assertEq(raised, 0);
        assertEq(campaignOwner, owner);
    }

    // --- Funding Tests ---

    function test_FundSuccess() public {
        vm.prank(alice);

        // Check event emission: (checkTopic1, checkTopic2, checkTopic3, checkData)
        vm.expectEmit(true, false, false, true);
        emit Funded(alice, 5 ether);

        crowdfund.fund{value: 5 ether}();

        assertEq(crowdfund.funders(alice), 5 ether);
        (,, uint256 raised,) = crowdfund.campaign();
        assertEq(raised, 5 ether);
    }

    function test_Revert_FundAfterDeadline() public {
        vm.warp(block.timestamp + DURATION + 1); // Move time past deadline
        vm.prank(alice);
        vm.expectRevert("Campaign has ended");
        crowdfund.fund{value: 1 ether}();
    }

    function test_Revert_FundWithZeroValue() public {
        vm.prank(alice);
        vm.expectRevert("ETH must be sent");
        crowdfund.fund{value: 0}();
    }

    // --- Withdrawal Tests ---

    function test_WithdrawSuccess() public {
        // 1. Setup: Reach goal
        vm.prank(alice);
        crowdfund.fund{value: 10 ether}();

        // 2. Warp past deadline
        vm.warp(block.timestamp + DURATION);

        // 3. Owner withdraws
        uint256 ownerBalanceBefore = owner.balance;

        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit Withdrawn(10 ether);
        crowdfund.withdraw();

        assertEq(owner.balance, ownerBalanceBefore + 10 ether);
        (,, uint256 raised,) = crowdfund.campaign();
        assertEq(raised, 0); // Check state reset
    }

    function test_Revert_WithdrawWhileActive() public {
        vm.prank(owner);
        vm.expectRevert("Campaign is still active");
        crowdfund.withdraw();
    }

    function test_Revert_WithdrawByNonOwner() public {
        vm.warp(block.timestamp + DURATION);
        vm.prank(alice);
        vm.expectRevert("Only owner can withdraw");
        crowdfund.withdraw();
    }

    function test_Revert_WithdrawGoalNotReached() public {
        vm.prank(alice);
        crowdfund.fund{value: 5 ether}();

        vm.warp(block.timestamp + DURATION);

        vm.prank(owner);
        vm.expectRevert("Goal not reached");
        crowdfund.withdraw();
    }

    // --- Refund Tests ---

    function test_RefundSuccess() public {
        // 1. Setup: Goal not reached
        vm.prank(alice);
        crowdfund.fund{value: 5 ether}();

        vm.warp(block.timestamp + DURATION);

        // 2. Alice claims refund
        uint256 aliceBalanceBefore = alice.balance;

        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit Refunded(alice, 5 ether);
        crowdfund.refund();

        assertEq(alice.balance, aliceBalanceBefore + 5 ether);
        assertEq(crowdfund.funders(alice), 0);
        (,, uint256 raised,) = crowdfund.campaign();
        assertEq(raised, 0);
    }

    function test_Revert_RefundWhileActive() public {
        vm.prank(alice);
        crowdfund.fund{value: 5 ether}();

        vm.prank(alice);
        vm.expectRevert("Campaign is still active");
        crowdfund.refund();
    }

    function test_Revert_RefundIfGoalReached() public {
        vm.prank(alice);
        crowdfund.fund{value: 10 ether}();

        vm.warp(block.timestamp + DURATION);

        vm.prank(alice);
        vm.expectRevert("Goal has been reached");
        crowdfund.refund();
    }

    function test_Revert_RefundIfZeroContribution() public {
        vm.warp(block.timestamp + DURATION);

        vm.prank(bob); // Bob never funded
        vm.expectRevert("You have not funded this campaign");
        crowdfund.refund();
    }
}
