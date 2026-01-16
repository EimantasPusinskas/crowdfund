# Decentralized Crowdfunding Platform

A robust, multi-campaign crowdfunding smart contract built with **Solidity** and **Foundry**. This platform enables trustless fundraising where funds are only accessible if specific goals are met within a defined timeframe, otherwise, contributors are guaranteed a refund via a secure pull-payment pattern.

## Features

* **Multi-Campaign Registry:** Deploy one contract to manage hundreds of individual crowdfunding campaigns.
* **Security First Architecture:** Implemented using the **Checks-Effects-Interactions (CEI)** pattern to mitigate Reentrancy risks.
* **Pull-Payment System:** Contributors "pull" their own refunds, preventing Denial of Service (DoS) attacks.
* **Modern Solidity:** Built with version `0.8.20` and uses low-level `.call` for gas-efficient ETH transfers.
* **Automated Testing:** 100% Branch coverage including edge cases and failed transfer simulations.

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