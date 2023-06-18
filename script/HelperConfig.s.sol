// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script{
    struc NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
    }
    
    NetworkConfign public activeNetworkConfig;

    constructor() {
        if (block.chainId == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvileConfig();
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig ({
            entranceFee: 0.1 ether,
            interval: 30,
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0, 
            callbackGasLimit 500000
        });
    }

    function getOrCreateEntConfig()
        public
        returns (NetworkConfig memory) {
            if (activeNetworkConfig.vrfCoordinator != address(0)) {
                return activeNetworkConfig;
            }
        }
}