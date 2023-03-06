// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Deposit is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    address public targetContract;
    uint256 public totalSupply;
    
    mapping(address => uint256) private balances;

    mapping(address => uint256) private lastStakeDate;

    /**
     * @dev Staking event
     */
    event staking(address indexed user, uint256 amount);

    /**
     * @dev Event at the time of withdrawal
     */
    event withdrawal(address indexed user, uint256 amount);

    /**
     * @dev Initializing the contract.Contract is being stopped at the time of contract deployment.
     * @param _targetContract [address] address of the ERC20 token to be staked
     */
    constructor(address _targetContract) {
        targetContract = _targetContract;
        pause();
    }

    /**
     * @dev Stop the staking and unstaking processes
     */
    function pause() public onlyOwner nonReentrant {
        _pause();
    }

    /**
     * @dev Resume the stopped staking and unstaking processes
     */
    function unpause() public onlyOwner nonReentrant {
        _unpause();
    }
        
    /**
     * @dev Deposit ERC20 tokens for staking
     * @param amount uint256 Staking amount
     */
    function stake(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Please specify a value larger than 0 for the number of tokens to deposit.");

        totalSupply = totalSupply.add(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        lastStakeDate[msg.sender] = block.timestamp;

        IERC20(targetContract).safeTransferFrom(msg.sender, address(this), amount);
        emit staking(msg.sender, amount);
    }

    /**
     * @dev  Withdraw the staked ERC20 tokens
     *       Able to withdraw the tokens 24 hours after the last deposit.
     * @param amount [uint256] Unstaking amount 
     */
    function unstake(uint256 amount) public whenNotPaused nonReentrant{
        require(amount > 0, "Please specify a value larger than 0 for the number of tokens to withdraw.");
        require(amount <= balances[msg.sender], "Please set a value smaller than or equal to the current staking amount for the number of tokens to withdraw.");
        require(block.timestamp > lastStakeDate[msg.sender] + 1 days , "Please wait at least 1 day after the last staking time.");

        totalSupply = totalSupply.sub(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);

        IERC20(targetContract).safeTransfer(msg.sender, amount);
        emit withdrawal(msg.sender, amount);
    }

    /**
     * @dev Returns the number of decimal places of the currency unit used in the token being staked
     * @return decimal [uint8] The number of decimal places of the currency unit
     */
    function decimals() public view returns (uint8) {
        return IERC20Metadata(targetContract).decimals();
    }

    /**
     * @dev Returning the last deposit time at the specified address
     * @param account [address] user address
     * @return balance [uint256] the last deposit time at the specified address
     */
    function lastStake(address account) external view returns (uint256) {
        return lastStakeDate[account];
    }

    /**
     * @dev Returning the balance at the specified address
     * @param account [address] user address
     * @return balance [uint256] Balance at the specified address
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}