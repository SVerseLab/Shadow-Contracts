// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IFODeployerV5.sol";

contract IFOStartEndBlockCalculator is Ownable {
    using SafeERC20 for IERC20;

    IFODeployerV5 public ifoDeployer;
    uint256 public constant BLOCKS_PER_MINUTE = 4; // For BSC, ~3 seconds per block
    uint256 public constant BLOCKS_PER_HOUR = BLOCKS_PER_MINUTE * 60;
    uint256 public constant BLOCKS_PER_DAY = BLOCKS_PER_HOUR * 24;

    constructor(address _ifoDeployer) {
        require(_ifoDeployer != address(0), "IFOStartEndBlockCalculator: Invalid IFO Deployer address");
        ifoDeployer = IFODeployerV5(_ifoDeployer);
    }

    event StartEndBlockCalculated(uint256 indexed startBlock, uint256 indexed endBlock);

    function getCurrentBlockNumber() public view returns (uint256) {
        return block.number;
    }

    function calculateFutureBlock(uint256 days, uint256 hours, uint256 minutes) public view returns (uint256) {
        uint256 totalBlocks = (days * BLOCKS_PER_DAY) + (hours * BLOCKS_PER_HOUR) + (minutes * BLOCKS_PER_MINUTE);
        return block.number + totalBlocks;
    }

    function calculateStartEndBlock(uint256 durationInBlocks) external onlyOwner {
        require(durationInBlocks > 0, "IFOStartEndBlockCalculator: Duration must be greater than 0");

        uint256 startBlock = block.number + 1;
        uint256 endBlock = startBlock + durationInBlocks;

        emit StartEndBlockCalculated(startBlock, endBlock);
    }

    function createIFOWithCalculatedBlocks(
        address _lpToken,
        address _offeringToken,
        uint256 durationInBlocks,
        address _adminAddress,
        address _iShdwAddress
    ) external onlyOwner {
        (uint256 startBlock, uint256 endBlock) = _calculateStartEndBlock(durationInBlocks);

        ifoDeployer.createIFO(
            _lpToken,
            _offeringToken,
            startBlock,
            endBlock,
            _adminAddress,
            _iShdwAddress
        );
    }

    function _calculateStartEndBlock(uint256 durationInBlocks) internal view returns (uint256 startBlock, uint256 endBlock) {
        require(durationInBlocks > 0, "IFOStartEndBlockCalculator: Duration must be greater than 0");

        startBlock = block.number + 1;
        endBlock = startBlock + durationInBlocks;

        return (startBlock, endBlock);
    }
}
