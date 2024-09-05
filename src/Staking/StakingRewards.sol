// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {RealEstateNft} from "../RealEstateNft.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {console} from "forge-std/Test.sol";
import {RewardToken} from "../RewardToken.sol";

contract StakingReward is ReentrancyGuard, Pausable, Ownable2Step {
    /* ========== STATE VARIABLES ========== */

    RewardToken public rewardsToken;
    RealEstateNft public stakingNFT;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 115740740740741; // 10 / 86,400 seconds * 1e18 , 10 rewards per 24 hours in seconds
    uint256 public rewardsDuration = 1 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    mapping(uint256 tokenId => address) private _owners;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardsToken,
        address _stakingToken
    ) Ownable(msg.sender) {
        rewardsToken = RewardToken(_rewardsToken);
        stakingNFT = RealEstateNft(_stakingToken);

        lastUpdateTime = block.timestamp;
        // periodFinish = block.timestamp + rewardsDuration;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp;
        // return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }

        console.log(
            "lastTimeRewardApplicable() - lastUpdateTime",
            lastTimeRewardApplicable(),
            lastUpdateTime
        );
        return
            rewardPerTokenStored +
            (lastTimeRewardApplicable() - lastUpdateTime) *
            rewardRate;
    }

    function earned(address account) public view returns (uint256) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) /
                (1e18)) + rewards[account];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(
        uint256 tokenId
    ) external nonReentrant whenNotPaused updateReward(msg.sender) {
        // require(amount > 0, "Cannot stake 0");
        _totalSupply++;
        _balances[msg.sender]++;
        _owners[tokenId] = msg.sender;
        stakingNFT.transferFrom(msg.sender, address(this), tokenId);
        emit Staked(msg.sender, tokenId);
    }

    function withdraw(
        uint256 tokenId
    ) public nonReentrant updateReward(msg.sender) {
        require(_owners[tokenId] == msg.sender, "Cannot withdraw ");
        _totalSupply--;
        _balances[msg.sender]--;
        stakingNFT.transferFrom(address(this), msg.sender, tokenId);
        emit Withdrawn(msg.sender, tokenId);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        console.log("[getReward]", reward);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.mint(msg.sender, reward * 1e18);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        console.log(
            "rewardPerTokenStored, lastUpdateTime",
            rewardPerTokenStored,
            lastUpdateTime
        );
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // function notifyRewardAmount(
    //     uint256 reward
    // ) external onlyOwner updateReward(address(0)) {
    //     if (block.timestamp >= periodFinish) {
    //         rewardRate = reward / rewardsDuration;
    //     } else {
    //         uint256 remaining = periodFinish - block.timestamp;
    //         uint256 leftover = remaining * rewardRate;
    //         rewardRate = (reward + leftover) / rewardsDuration;
    //     }

    //     // Ensure the provided reward amount is not more than the balance in the contract.
    //     // This keeps the reward rate in the right range, preventing overflows due to
    //     // very high values of rewardRate in the earned and rewardsPerToken functions;
    //     // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    //     uint balance = rewardsToken.balanceOf(address(this));
    //     require(
    //         rewardRate <= balance / rewardsDuration,
    //         "Provided reward too high"
    //     );

    //     lastUpdateTime = block.timestamp;
    //     periodFinish = block.timestamp + rewardsDuration;
    //     emit RewardAdded(reward);
    // }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 tokenId);
    event Withdrawn(address indexed user, uint256 tokenId);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}
