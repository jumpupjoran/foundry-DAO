// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {Box} from "../src/Box.sol";
import {Timelock} from "../src/TimeLock.sol";
import {GovToken} from "../src/GovToken.sol";

contract MyGovernorTest is Test {
    MyGovernor gov;
    Box box;
    Timelock timelock;
    GovToken govToken;

    address public USER = makeAddr("user");
    uint256 public constant INITIAL_SUPPLY = 100 ether;

    uint256 public constant MIN_DELAY = 3600; // 1 hour - after a proposal is queued, it must wait for this time before being executed
    uint256 public constant VOTING_DELAY = 1; //  how many blocks until a vote is active after a proposal is proposed
    uint256 public constant VOTING_PERIOD = 50400;
    address[] public proposers;
    address[] public executors;

    uint256[] values;
    bytes[] calldatas;
    address[] targets;

    function setUp() public {
        govToken = new GovToken(USER, INITIAL_SUPPLY);
        vm.startPrank(USER);
        govToken.delegate(USER); // giving the voting power to the account itself, EASY TO FORGET STEP

        timelock = new Timelock(MIN_DELAY, proposers, executors);
        gov = new MyGovernor(govToken, timelock);

        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.TIMELOCK_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(gov)); // only the gov can propose things to the timelock
        timelock.grantRole(executorRole, address(0)); //onybody can execute the proposals
        timelock.revokeRole(adminRole, USER); // the user is not the admin anymore
        vm.stopPrank();

        box = new Box(address(timelock)); // the timeLock owns the dao and the dao owns the timelock, its like a weird relationship
    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        box.store(42);
    }

    function testGovernanceUpdatesBox() public {
        uint256 newNumber = 888;
        bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)", newNumber);
        string memory description = "store 888 in the box";

        values.push(0); // we dont want to send any value with the transaction
        calldatas.push(encodedFunctionCall);
        targets.push(address(box));

        // 1. propose to the DAO
        uint256 proposalId = gov.propose(targets, values, calldatas, description);

        // view the state of the proposal
        console.log("proposal state: ", uint256(gov.state(proposalId))); // should be pending = 0;
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        console.log("proposal state: ", uint256(gov.state(proposalId))); // should be active = 1;

        //  2. vote on the proposal
        string memory reason = "cuz joran is cool";
        uint8 what_you_want_to_vote = 1; // 0 for against, 1 for for, 2 for abstain
        vm.prank(USER);
        gov.castVoteWithReason(proposalId, what_you_want_to_vote, reason); // you can also vote without a reason

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        // 3. queue the transaction
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        gov.queue(targets, values, calldatas, descriptionHash);

        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY + 1);

        // 4. execute
        gov.execute(targets, values, calldatas, descriptionHash);

        assert(box.getNumber() == newNumber);
        console.log("Box value: ", box.getNumber());
    }
}
