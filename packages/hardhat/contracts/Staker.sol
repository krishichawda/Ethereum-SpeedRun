// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    event Stake(address, uint256);

    mapping(address => uint256) public balances;

    uint256 public constant threshold = 1 ether;

    uint256 public deadline = block.timestamp + 30 hours;

    bool public openForWithdraw;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    function stake() public payable {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    modifier deadlineReached(bool isDeadlineReached) {
        uint256 timeRemaining = timeLeft();
        if (isDeadlineReached) {
            require(timeRemaining <= 0, "Deadline has not passed yet");
        } else {
            require(timeRemaining > 0, "Deadline has already passed !");
        }
        _;
    }

    function execute() public stakingNotCompleted {
        uint256 contractBalance = address(this).balance;
        if (contractBalance >= threshold) {
            exampleExternalContract.complete{value: contractBalance}();
        } else {
            openForWithdraw = true;
        }
    }

    function timeLeft() public returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    receive() external payable {
        stake();
    }

    modifier stakingNotCompleted() {
        bool completed = exampleExternalContract.completed();

        require(!completed, "The Staking process is completed");
        _;
    }

    function withdraw(address payable _to)
        public
        deadlineReached(true)
        stakingNotCompleted
    {
        require(openForWithdraw, "Not Open For Withdraw");

        uint256 userBalance = balances[msg.sender];

        require(userBalance > 0, "Balance is Empty");

        balances[msg.sender] = 0;
        (bool sent, ) = _to.call{value: userBalance}("");

        require(sent, "Failed to send ether");
    }
}
