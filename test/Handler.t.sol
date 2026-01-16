// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Crowdfund} from "../src/Crowdfund.sol";

contract Handler is Test {
    Crowdfund public crowdfund;
    uint256 public phantomBalance; // Our "Ghost Variable" to track expected balance

    constructor(Crowdfund _crowdfund) {
        crowdfund = _crowdfund;
    }

    function fund(uint256 id, uint256 amount) public {
        if (crowdfund.campaignCount() == 0) return;

        amount = bound(amount, 1, address(this).balance); // Don't send more than we have
        id = bound(id, 0, crowdfund.campaignCount() - 1); // Only valid IDs

        vm.deal(address(this), amount);

        try crowdfund.fund{value: amount}(id) {
        // This only runs if the fund() call was successful!
        phantomBalance += amount;
        } catch {
            // If it reverted, we do nothing.
        }
    }

    function createCampaign(uint256 goal, uint256 duration) public {
        // Bound the random inputs so they make sense
        goal = bound(goal, 0.01 ether, 100 ether);
        duration = bound(duration, 1 hours, 365 days);

        crowdfund.createCampaign(goal, duration);
    }
}
