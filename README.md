# Decentralized Crowdfunding Platform

A robust, security-focused smart contract built with **Solidity** and the **Foundry** development framework. This contract allows users to fund projects with a specific goal and deadline, ensuring transparent and trustless fundraising.

## Features

* **Fixed Goal & Deadline:** Campaigns have a clear target and timeframe.
* **Security First:** Implemented using the **Checks-Effects-Interactions (CEI)** pattern to mitigate Reentrancy risks.
* **Pull-Payment System:** Contributors "pull" their own refunds, preventing Denial of Service (DoS) attacks.
* **Modern Solidity:** Built with version `0.8.20` and uses low-level `.call` for gas-efficient ETH transfers.
* **Automated Testing:** Full test suite coverage for success and revert cases.

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
* **Framework:** [Foundry](https://book.getfoundry.sh/)
* **CI/CD:** GitHub Actions
* **Testing:** Forge (Solidity Scripting)

---