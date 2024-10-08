// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Afrida
 * @dev Implements donation process and fund disbursement
 */
contract Afrida {
    uint8 quoram = 2; // 50% of total votes to release funds
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    //modifiers

    modifier onlyOwner {
        require(msg.sender == admin);
        _;
    }

    modifier onlyDonor(address user) {
        require(msg.sender == user);
        _;
    }

    //events
    event DonationRecieved(uint amount, address from);
    //types
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        bool vote;   // index of the voted proposal
    }

    struct Donation{
        uint target; // amount that must me achieved otherwise reimbursement
        uint amount;
        uint vote;
        mapping(address => Voter) votes;
    }

    mapping(address => Donation) public donations;

    function delegateTo(address voter) onlyDonor(msg.sender) onlyDonor(voter) public {}
    function refund(address voter) public {}
    function changeOwner(address newOwner) onlyOwner public {
        admin = newOwner;
    }
}