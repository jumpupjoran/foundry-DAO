# Foundry DAO Governance

This project demonstrates a decentralized governance system using ERC20-based voting and time-locked proposals. It was developed as part of the Cyfrin Foundry Solidity course’s advanced smart contract module, utilizing `Foundry` for Solidity-based testing and OpenZeppelin’s governance contracts for core functionality.

**Note**: This project uses OpenZeppelin v4.8.3 for compatibility.

- [Foundry DAO Governance](#foundry-dao-governance)
  - [Overview](#overview)
  - [Getting Started](#getting-started)
    - [Requirements](#requirements)
    - [quickstart](#quickstart)
  - [Project Structure](#project-structure)
    - [Deployment](#deployment)
    - [Gas Estimation](#gas-estimation)
  - [Formatting](#formatting)
    - [8. Additional Resources](#8-additional-resources)
  - [Additional Resources](#additional-resources)
  - [Acknowledgments](#acknowledgments)
  - [License](#license)

## Overview

This DAO governance implementation includes several key elements:

- **ERC20 Voting Token**: Uses `GovToken.sol` to facilitate voting.
- **Governor Contract**: `MyGovernor.sol` for proposing, voting, and executing actions.
- **Time-Locked Execution**: Once a proposal passes the voting phase, it is queued in the `Timelock` contract. The `Timelock` is then responsible for executing the proposal after a certain delay, giving the `timelock` the execution authority
- **Governance of State Storage**: `Box.sol` is a mock contract demonstrating how governance controls external contract states.

This project combines governance and timelocks to form a structured DAO governance model, where token holders can vote on proposals and decide actions within the DAO.

## Getting Started

### Requirements

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) – for version control
- [Foundry](https://getfoundry.sh/) – for testing and contract interaction

Verify your installations with:

```bash
git --version
forge --version
```

### quickstart

To clone and setup the repository:

```bash
git clone https://github.com/jumpupjoran/foundry-DAO.git
cd foundry-dao
forge install
forge build
```

## Project Structure

- **`Box.sol`**: A simple contract that stores an integer, which can only be updated by the DAO. Demonstrates governance controlling contract state.
- **`GovToken.sol`**: Implements an ERC20 token with voting capabilities, allowing token holders to delegate votes and participate in DAO governance.
- **`MyGovernor.sol`**: The main governance contract, built with OpenZeppelin’s governor extensions to handle proposal creation, voting, quorum requirements, and time-locked execution.
- **`TimeLock.sol`**: Enforces a delay on executing proposals, giving participants time to respond before actions are finalized.
- **`MyGovernorTest.t.sol`**: Contains test cases to verify proposal creation, voting, and execution processes using Foundry’s testing framework.

````

## Usage

### Testing

Run the tests using Foundry’s `forge` command:
```bash
forge test
````

### Deployment

There are no deployment scripts provided. However, you can manually deploy each contract and initialize them accordingly.

### Gas Estimation

Estimate gas usage for your transactions:

```bash
forge snapchot
```

A `.gas-snapshot` file will be generated, showing gas costs for the various operations in the contracts.

## Formatting

To format the code:

```bash
forge fmt
```

### 8. Additional Resources

## Additional Resources

- [Vitalik’s Article on Money-Based Voting](https://vitalik.ca/general/2018/03/28/plutocracy.html) – A discussion on why ERC20 token-based voting may not always be the best choice.
- OpenZeppelin Governance Contracts documentation – For details on the `Governor`, `ERC20Votes`, and `TimelockController` functionalities.

## Acknowledgments

This project was developed as part of Cyfrin’s advanced Solidity course. Special thanks to the Cyfrin team for their resources and guidance in building decentralized governance systems.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
