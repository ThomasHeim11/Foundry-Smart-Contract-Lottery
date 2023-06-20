// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "../test/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubsciptionUsingConfig() internal returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , , ) = helperConfig
            .activeNetworkConfig();
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint64) {
        console.log("Creating subscription on ChainId", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator)
            .createSubscription();

        vm.stopBroadcast();
        console.log("Your sub Id is:", subId);
        console.log("Please update subscriptionId in HelperConfig.s.sol");
        return subId;
    }

    function run() external returns (uint64) {
        return createSubsciptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUN_AMOUNT = 3 ether;

    function FundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subscriptionId,
            ,
            address link
        ) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subId, link);
    }

    function fundSubscription(
        address vrfCordinator,
        uint64 subId,
        address link
    ) public {
        console.log("Funding subscription", subId);
        console.log("Using vrfCoordinator", vrfCordinator);
        console.log("On CahinID:", block.chainid);
        if (block.chainid == 11155111) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCordinator).fundSubscription(
                subId,
                FUN_AMOUNT
            );
            vm.stopBroadcast();
        }
        {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                vrfCordinator,
                FUN_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }

    function fun() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {

    function addConsumer (address raffle, address VRFCoordinator, uint64 subId) public {
        console.log("Adding consumer to contract", raffle);
        console.log("Using vrfCoordinator", VRFCoordinator);
        console.log("On CahinID:", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(VRFCoordinator).addConsumer(subId,raffle);
        VM.stopBroadcast();

    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            ,
            uint64 subId,
            ,
            ,
        ) = helperConfig.activeNetworkConfig();
        addConsumer(raffle, vrfCoordinator, subId);
    } 

}



        
    
    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment (
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(raffle);
    }
}
