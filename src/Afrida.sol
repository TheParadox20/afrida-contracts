// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Afrida
 * @dev Implements donation process and fund disbursement
 */
contract Afrida {
    int8 quoram = 2; // 50% of total votes to release funds
    uint8 commision = 5; // 5% of total funds
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    //modifiers

    modifier onlyOwner {
        require(msg.sender == admin, "Only owner can interact with contract");
        _;
    }

    modifier onlyDonor(address donation, address doner) {
        require(donations[donation].votes[doner].weight > 0, "Only doners can interact with contract");
        _;
    }

    modifier onlyDonee(address donee) {
        require(msg.sender == admin || msg.sender == donations[donee].withdrawal, "Only donation owner can interact with contract");
        _;
    }

    //events
    event DonationRecieved(uint amount, address from);
    event DonationCreated(address by);
    //types
    struct Voter {
        int8 weight; // weight is accumulated by delegation
        uint amount; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint8 step;
    }

    struct Donation{
        address payable  withdrawal;
        uint target; // amount that must me achieved otherwise reimbursement
        uint amount; // total amount held by contract
        uint[] steps; // disbursement amount steps
        uint8 step; // current stage of disbursement
        int8 doners; // total number of doners
        int8 vote; // total weight of votes
        mapping(address => Voter) votes;
    }

    mapping(address => Donation) public donations;

    function createDonation() public payable {
        // require(donations[msg.sender].amount>1 gwei, "Donation exist");
        require(msg.value>0, "Donation seed must be greater than 0");
        donations[msg.sender].amount += msg.value;
        donations[msg.sender].withdrawal = payable(msg.sender);
    }

    function setWithdrawal(address payable withdrawal) onlyDonee(msg.sender) public {
        donations[msg.sender].withdrawal = withdrawal;
    }

    function delegateTo(address voter, address donation) onlyDonor(donation, voter) public {
        require((donations[donation].votes[msg.sender].weight>0 && donations[donation].votes[msg.sender].voted==false), "Invalid user");
        donations[donation].votes[msg.sender].voted = true;
        donations[donation].votes[msg.sender].delegate = voter;
        donations[donation].votes[voter].weight += donations[donation].votes[msg.sender].weight;
    }

    function voteFor(address donation, bool choice) onlyDonor(donation, msg.sender) public {
        require(donations[donation].votes[msg.sender].voted==false, "Already voted");
        donations[donation].votes[msg.sender].voted = true;
        if(choice){
            donations[donation].vote += donations[donation].votes[msg.sender].weight;
        } else {
            donations[donation].vote -= donations[donation].votes[msg.sender].weight;
        }
    }

    function getVotes(address donation) public view returns (int8){
        return donations[donation].vote;
    }

    function donate(address donee) public payable {
        donations[donee].amount += msg.value;
        donations[donee].votes[msg.sender].weight += 1;
        donations[donee].votes[msg.sender].amount = msg.value;
        donations[donee].doners++;
        emit DonationRecieved(msg.value, msg.sender);
    }

    function refund(address payable voter, address donation) public {
        require(donations[donation].votes[voter].amount>0, "Invalid user");
        require(donations[donation].amount-getCommision(donation)>donations[donation].votes[voter].amount, "Insufficient funds in contract, try again later");
        voter.transfer(donations[donation].votes[voter].amount);
        donations[donation].amount -= donations[donation].votes[voter].amount;
        donations[donation].votes[voter].amount = 0;
        donations[donation].votes[voter].weight = 0;
    }
    function checkQuoram(address donation) internal view returns (bool) {
        return donations[donation].vote >= donations[donation].doners/quoram;
    }
    function getCommision(address donation) internal pure returns (uint) {
    }

    function release(address donation) onlyDonee(donation) public {
        require(donations[donation].amount-getCommision(donation)>0, "Insufficient funds");
        require(checkQuoram(donation),"Voters quorum not reached");
        donations[donation].withdrawal.transfer(donations[donation].steps[donations[donation].step]);
        donations[donation].amount -= donations[donation].steps[donations[donation].step];
        donations[donation].step++;
    }

    function getDonation() public view returns (// returns donees donation
        address withdrawal,
        uint target,
        uint amount,
        uint[] memory steps,
        uint8 step,
        int8 doners,
        int vote
    ) {
        Donation storage donation = donations[msg.sender];
        return (
            donation.withdrawal,
            donation.target,
            donation.amount,
            donation.steps,
            donation.step,
            donation.doners,
            donation.vote
        );
    }

    function getMyDonation(address donation) public view returns (// returns donees donation
        int8 weight,
        uint amount,
        bool voted,
        address delegate,
        uint8 step
    ) {
        Voter storage voter = donations[donation].votes[msg.sender];
        return (
            voter.weight,
            voter.amount,
            voter.voted,
            voter.delegate,
            voter.step
        );
    }

    // admin related funtions
    function changeOwner(address newOwner) onlyOwner public {
        admin = newOwner;
    }
    function getCommision() onlyOwner public view returns (uint8) {
        return  commision;
    }
    function setCommision(uint8 newCommision) onlyOwner public {
        commision = newCommision;
    }
    function getQuorum() onlyOwner public view  returns (int8) {
        return  quoram;
    }
    function setQuorum(int8 newQuorum) onlyOwner public {
        quoram = newQuorum;
    }
}