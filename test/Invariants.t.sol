// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";
import {Handler} from "./Handler.t.sol";
import {Crowdfund} from "../src/Crowdfund.sol";

contract CrowdfundInvariants is StdInvariant, Test {
    Handler public handler;
    Crowdfund public crowdfund;

    function setUp() public {
        crowdfund = new Crowdfund();
        handler = new Handler(crowdfund);

        // Tell Foundry to only fuzz the functions inside the Handler
        targetContract(address(handler));
    }

    function invariant_BalanceMatchesRaised() public view {
        assertEq(address(crowdfund).balance, handler.phantomBalance());
    }
}
