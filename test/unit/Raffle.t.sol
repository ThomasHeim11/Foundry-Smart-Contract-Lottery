// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VM} from "forge-vm/VM.sol";
import {VRFCoordinatorMock} from "@chainlink/contracts/src/v0.8/tests/VRFCoordinatorMock.sol";

contract RaffleTest is Test {
    /* Event */
    event EnteredRaffle(address indexed player);
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            link,

        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitlizesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWHenYouDontPayEnought() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval +1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCheckUpKeepReturnFalseIfIthasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testCeckUpkeepReturnsFalseIfRaffleNotOpen () public {

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.wrap(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assert(upkeepNeeded == false);
    }

    function testPerformUpkeepCanonlyRunIfCheckUpkeepIsTrue() public {

        vm.prank(PLAYER);
        raffle.enterRaffle(value: entranceFee)();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currenBalance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = 0;
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__PerformUpkeepNotNeeded.selector, currenBalance, numPlayers, raffleState)
            );
        raffle.performUpkeep("");
    }

    modifier raffleEnteredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }
        
    }

    function testPerformUpkeepUpdateRaffleStateAndEmitRequestId() public {
        raffleEnteredAndTimePassed
{ 
    vm.recordLogs();
    raffle.performUpkeep("");
    Vm.log[] memory entries = vm.RecordedLogs();
    bytes32 requestId = entries[0].topics[1];

    Raffle.RaffleState raffleState = raffle.getRaffleState();

    assert(uint256(requestId) > 0);
    aasert(uint256(rState) ==1);
    }

    modifier skipFork() {
        if(block.chainid != 31337 ) {
            return;
        }
        _;
    }

    function testFufillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) 
        public
        raffleEnteredAndTimePassed
        skipFork
    {
        vm.expectRevert("nonexsistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomness(
            randomRequestId,
            address(raffle)
        );
    }

    function testFufillRandomWordsPicksWinnerResetsAndSendsMoney() 
        public raffleEnteredAndTimePassed
        {

            uint256 additionEnters = 5;
            uint256 startingIndex = 1;
            for(uint256 i = startingIndex; i< startingIndex + additionEnters; i++) {
                address player = address(uint160(i));
                hoax(player, STARTING_USER_BALANCE);
                raffle.enterRaffle{value: entranceFee}();
            }

            uint256 prize = entranceFee * (additionEnters + 1);

            vm.recordLogs();
            raffle.performUpkeep("");
            Vm.log[] memory entries = vm.RecordedLogs();
            bytes32 requestId = entries[0].topics[1];

            uint256 previousTimeStamp = raffle.getLastTimeStamp();

            VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomness(
                uint256(requestId),
                address(raffle)
            );

            assert(uint256(raffle.getRaffleState()) == 0);
            assert(raffle.getRecentWinner() != address(0)); 
            assert (raffle.getLenghtOfPlayers() == 0);
            assert(previousTimeStamp < raffle.getLastTimeStamp());
            assert(raffle.getRecentWinner().balance == STARTING_USER_BALANCE + prize - entranceFee);
        }
}