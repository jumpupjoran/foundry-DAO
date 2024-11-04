// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {GovToken} from "../src/GovToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {Box} from "../src/Box.sol";

contract MyGovernorTest is Test {
    GovToken token;
    TimeLock timelock;
    MyGovernor governor;
    Box box;

    uint256 public constant MIN_DELAY = 3600; // 1 hour - after a proposal is queued, it must wait for this time before being executed
    uint256 public constant QUORUM_PERCENTAGE = 4; // Need 4% of voters to pass
    uint256 public constant VOTING_PERIOD = 50400; // This is how long voting lasts
    uint256 public constant VOTING_DELAY = 1; //  how many blocks until a vote is active after a proposal is proposed

    address[] proposers;
    address[] executors;

    bytes[] functionCalls;
    address[] addressesToCall;
    uint256[] values;

    address public voter = makeAddr("voter");

    function setUp() public {
        token = new GovToken();
        token.mint(voter, 100e18);

        vm.prank(voter);
        token.delegate(voter); // giving the voting power to the account itself, EASY TO FORGET STEP
        timelock = new TimeLock(MIN_DELAY, proposers, executors);
        governor = new MyGovernor(token, timelock);
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.TIMELOCK_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor)); // only the gov can propose things to the timelock
        timelock.grantRole(executorRole, address(0)); // we say that anybody can execute the proposals for this example
        timelock.revokeRole(adminRole, msg.sender); // the user is not the admin anymore

        box = new Box();
        box.transferOwnership(address(timelock)); // the timeLock owns the dao and the dao owns the timelock, its like a weird relationship
    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        box.store(1);
    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 777;
        string memory description = "Store 1 in Box";
        bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)", valueToStore);
        addressesToCall.push(address(box));
        values.push(0); // we dont want to send any value with the transaction
        functionCalls.push(encodedFunctionCall);
        // 1. Propose to the DAO
        uint256 proposalId = governor.propose(addressesToCall, values, functionCalls, description);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        //  2. vote on the proposal
        string memory reason = "I like a do da cha cha";
        // 0 = Against, 1 = For, 2 = Abstain for this example
        uint8 voteWay = 1;
        vm.prank(voter);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        // 3. queue the transaction
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(addressesToCall, values, functionCalls, descriptionHash);
        vm.roll(block.number + MIN_DELAY + 1);
        vm.warp(block.timestamp + MIN_DELAY + 1);

        // 4. Execute
        governor.execute(addressesToCall, values, functionCalls, descriptionHash);

        assert(box.retrieve() == valueToStore);
    }
}
