// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {StakingReward} from "../src/Staking/StakingRewards.sol";
import {RewardToken} from "../src/RewardToken.sol";
import {RealEstateNft} from "../src/RealEstateNft.sol";
import {MockUSDC} from "../mock/MockUSDC.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingRewardsTest is Test {
    StakingReward stakingReward;
    RewardToken rewardToken;
    RealEstateNft realEstateNft;
    MockUSDC mockUsdc;
    bytes32 constant merkelTreeRoot =
        0xea9dd63ff30f9a026d565cbad51ab2319afc7537424e2e510ede5325b791e432;
    uint256 constant NFT_PRICE = 100 * 1E6;
    uint256 constant NFT_PRICE_WTIH_DISCOUNT = 90 * 1E6; // 10% discount
    bytes32[] proof = new bytes32[](3);

    address bob;
    address alice;
    uint256 bobsTokenId;

    function setUp() public {
        mockUsdc = new MockUSDC();
        realEstateNft = new RealEstateNft(merkelTreeRoot, address(mockUsdc));

        rewardToken = new RewardToken();

        stakingReward = new StakingReward(
            address(rewardToken),
            address(realEstateNft)
        );
        rewardToken.setMinter(address(stakingReward));

        bob = address(0x01);
        alice = address(0x20);

        mockUsdc.transfer(bob, 1000 * 1e6);

        // mint a nft
        proof[
            0
        ] = 0x50bca9edd621e0f97582fa25f616d475cabe2fd783c8117900e5fed83ec22a7c;
        proof[
            1
        ] = 0x3a1c62a50e81c8b4c8110a9c7e9bef8862f413c809f3108381d19cbc5257f857;
        proof[
            2
        ] = 0x66af32f3d30d6dc65c85e44e9440bb28b3e0336196460fc418fb736d2bd7ea62;

        // Bob with address 0x01 transfer 90 usdc with discount of 10% to the RealEstateNft for the NFT mint
        vm.startPrank(bob);
        IERC20(mockUsdc).transfer(
            address(realEstateNft),
            NFT_PRICE_WTIH_DISCOUNT
        );
        bobsTokenId = realEstateNft.mint(NFT_PRICE, bob, 0, proof);

        vm.stopPrank();
    }

    function testStake() public {
        uint currentTime = block.timestamp;
        vm.warp(currentTime + 1 days);

        // One day after bob stake his nft
        vm.startPrank(bob);
        realEstateNft.safeTransferFrom(
            bob,
            address(stakingReward),
            bobsTokenId
        );
        vm.stopPrank();

        // Advance the block timestamp by two days
        vm.warp(block.timestamp + 2 days);

        vm.prank(bob);
        stakingReward.getReward();

        uint bobRewardAmt = rewardToken.balanceOf(address(bob));

        assertEq(bobRewardAmt, 20 * 1e18);
    }

    function testMultipleNftStake() public {
        uint currentTime = block.timestamp;
        vm.warp(currentTime + 1 days);

        // One day after bob stake his nft
        vm.startPrank(bob);
        realEstateNft.approve(address(stakingReward), bobsTokenId);
        stakingReward.stake(bobsTokenId);
        vm.stopPrank();

        // Advance the block timestamp by two days
        vm.warp(block.timestamp + 2 days);

        // Bob with address 0x01 transfer 90 usdc with discount of 10% to the RealEstateNft for the NFT mint
        // mint a nft
        proof[
            0
        ] = 0x5fa3dab1e0e1070445c119c6fd10edd16d6aa2f25a5899217f919c041d474318;
        proof[
            1
        ] = 0x895c5cff012220658437b539cdf2ce853576fc0a881d814e6c7da6b20e9b8d8d;
        proof[
            2
        ] = 0x66af32f3d30d6dc65c85e44e9440bb28b3e0336196460fc418fb736d2bd7ea62;

        vm.startPrank(bob);
        IERC20(mockUsdc).transfer(
            address(realEstateNft),
            NFT_PRICE_WTIH_DISCOUNT
        );
        uint bobTokenId2 = realEstateNft.mint(NFT_PRICE, bob, 8, proof);
        // bob stake the 2nd nft
        realEstateNft.safeTransferFrom(
            bob,
            address(stakingReward),
            bobTokenId2
        );

        vm.stopPrank();

        // Advance the block timestamp by 1 days
        vm.warp(block.timestamp + 1 days);

        vm.prank(bob);
        stakingReward.getReward();

        uint bobRewardAmt = rewardToken.balanceOf(address(bob));

        assertEq(bobRewardAmt, 40 * 1e18);
    }

    function testStakeAndWithdraw() public {
        vm.startPrank(bob);
        realEstateNft.safeTransferFrom(
            bob,
            address(stakingReward),
            bobsTokenId
        );
        vm.stopPrank();

        address previousOwner = realEstateNft.ownerOf(bobsTokenId);

        // bob withdraw
        vm.prank(bob);
        stakingReward.withdraw(bobsTokenId);
        address currOwner = realEstateNft.ownerOf(bobsTokenId);

        assertEq(previousOwner, address(stakingReward));
        assertEq(currOwner, address(bob));
    }

    function testStakeAndWithdrawOnlyOwner() public {
        vm.startPrank(bob);
        realEstateNft.safeTransferFrom(
            bob,
            address(stakingReward),
            bobsTokenId
        );
        vm.stopPrank();

        // Advance the block timestamp by two days
        vm.warp(block.timestamp + 1 days);

        // bob withdraw
        vm.expectRevert("Cannot withdraw");
        vm.prank(alice);
        stakingReward.withdraw(bobsTokenId);
    }
}
