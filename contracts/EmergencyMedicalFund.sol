// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract EmergencyMedicalFund {
    address public patient;
    address public oracle;
    uint256 public expiry;

    mapping(address => uint256) public contributions;
    address[] public contributors;
    uint256 public totalContributed;

    mapping(address => bool) public isHospital;

    bool public emergencyConfirmed;
    bool public paid;

    constructor(address _oracle, uint256 _expiry) {
        patient = msg.sender;
        oracle = _oracle;
        expiry = _expiry;
    }

    // --- Contribute ETH ---
    receive() external payable {
        if (contributions[msg.sender] == 0) contributors.push(msg.sender);
        contributions[msg.sender] += msg.value;
        totalContributed += msg.value;
    }

    // --- Manage hospitals (only patient) ---
    function addHospital(address _hospital) external {
        require(msg.sender == patient, "Only patient");
        isHospital[_hospital] = true;
    }

    // --- Oracle confirms emergency ---
    function confirmEmergency() external {
        require(msg.sender == oracle, "Only oracle");
        emergencyConfirmed = true;
    }

    // --- Payout funds to hospital ---
    function payout(address _hospital) external {
        require(emergencyConfirmed, "Not confirmed");
        require(isHospital[_hospital], "Not hospital");
        require(!paid, "Already paid");

        paid = true;
        (bool sent, ) = _hospital.call{value: address(this).balance}("");
        require(sent, "Transfer failed");
    }

    // --- Refund contributors if expired ---
    function refund() external {
        require(block.timestamp >= expiry, "Not expired");
        uint256 share = (contributions[msg.sender] * address(this).balance) /
            totalContributed;
        contributions[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: share}("");
        require(sent, "Refund failed");
    }
}
