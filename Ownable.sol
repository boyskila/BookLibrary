// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Ownable {

    address private owner;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public isOwner {
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}