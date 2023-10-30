// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File contracts/interfaces/IReferrerStorage.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


interface IReferrerStorage {
    event ReferrerSet(
        address sender,
        address referrer,
        uint256 blockTime
    );
    function referrers(address _sender) external view returns(address referrer);
    function setReferrer(address _referrer) external;


}


// File contracts/ReferrerStorage.sol

contract ReferrerStorage is IReferrerStorage {
    // sender => referrer
    mapping(address => address) public override referrers;

    function setReferrer(address _referrer) public {
        require(msg.sender != _referrer, "not user self");
        require(referrers[msg.sender] == address(0), "User invited");
        referrers[msg.sender] = _referrer;
        emit ReferrerSet(msg.sender, _referrer, block.timestamp);
    }
}
