# Decentralized Crowdfunding Platform

A robust, multi-campaign crowdfunding smart contract built with **Solidity** and **Foundry**. This platform enables trustless fundraising where funds are only accessible if specific goals are met within a defined timeframe, otherwise, contributors are guaranteed a refund via a secure pull-payment pattern.

## Features

* **Multi-Campaign Registry:** Deploy one contract to manage hundreds of individual crowdfunding campaigns.
* **Security First Architecture:** Implemented using the **Checks-Effects-Interactions (CEI)** pattern to mitigate Reentrancy risks.
* **Pull-Payment System:** Contributors "pull" their own refunds, preventing Denial of Service (DoS) attacks.
* **Gas Optimiszed:** Uses low-level `.call` for ETH transfers and efficient storage mapping for campaign management.
* **Advanced QA:** Verified with both 100% Branch Coverage and Stateful Invariant Testing.

---

## Testing & Security

This project employs a multi-layered testing strategy to ensure the safety of user funds:

### 1. Unit Testing (100% Branch Coverage)
Every logical path, including edge cases like failed ETH transfers and unauthorized access attempts, is verified.
* **Coverage:** 100% Lines / 100% Branches
* **Framework:** Forge Standard Library

### 2. Stateful Invariant Testing (Fuzzing)
Using the **Handler Pattern**, the contract was subjected to **128,000+ random function calls** to verify global invariants.
* **Core Invariant:** `address(crowdfund).balance == sum(all_contributions)`
* **Result:** **PASSED**. Even under thousands of random transaction sequences, the accounting logic remained unbreakable.


---

## Contract Logic

| Condition | Outcome |
| :--- | :--- |
| **Goal Met & Deadline Passed** | Owner can `withdraw` all funds. |
| **Goal Not Met & Deadline Passed** | Contributors can `refund` their specific contribution. |
| **Deadline Not Reached** | Funds remain locked in the contract for security. |

---

## Tech Stack

* **Smart Contracts:** Solidity
* **Framework:** Foundry
* **CI/CD:** GitHub Actions
* **Testing:** Forge

---
