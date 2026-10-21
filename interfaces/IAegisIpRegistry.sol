// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;
interface IAegisIpRegistry {
    function buyIpLicense(uint256 ipId) external payable;
    function registerNewIp(uint256 licenseFeeWei, bytes32 ipHash) external returns (uint256);
}
