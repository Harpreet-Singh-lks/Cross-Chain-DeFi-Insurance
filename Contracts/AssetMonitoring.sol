// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AssetMonitor is Ownable {
    // Price feed addresses for different assets
    mapping(address => AggregatorV3Interface) public assetPriceFeeds;
    
    // Threshold values for asset price changes that trigger alerts
    mapping(address => uint256) public alertThresholds; // in percentage, multiplied by 100 (e.g., 500 = 5%)
    
    // Price baselines for comparison
    mapping(address => int256) public priceBaselines;
    
    event AssetPriceAlert(address indexed asset, int256 previousPrice, int256 currentPrice, uint256 percentageChange);
    
    // Constructor with initial assets to monitor
    constructor() {
        // Example: ETH/USD price feed on Polygon
        setAssetPriceFeed(address(0xEthAddress), 0x0715A7794a1dc8e42615F059dD6e406A6594651A);
        // Set default threshold to 5%
        setAlertThreshold(address(0xEthAddress), 500);
        // Store initial price as baseline
        updatePriceBaseline(address(0xEthAddress));
    }
    
    // Add or update a price feed for an asset
    function setAssetPriceFeed(address asset, address priceFeed) public onlyOwner {
        assetPriceFeeds[asset] = AggregatorV3Interface(priceFeed);
    }
    
    // Set alert threshold for an asset
    function setAlertThreshold(address asset, uint256 thresholdInBps) public onlyOwner {
        alertThresholds[asset] = thresholdInBps;
    }
    
    // Update price baseline for comparison
    function updatePriceBaseline(address asset) public {
        (,int256 price,,,) = assetPriceFeeds[asset].latestRoundData();
        priceBaselines[asset] = price;
    }
    
    // Get the latest price for an asset
    function getLatestPrice(address asset) public view returns (int256) {
        (,int256 price,,,) = assetPriceFeeds[asset].latestRoundData();
        return price;
    }
    
    // Check if price change exceeds threshold
    function checkPriceDeviation(address asset) public returns (bool) {
        require(address(assetPriceFeeds[asset]) != address(0), "Price feed not set");
        
        int256 baselinePrice = priceBaselines[asset];
        int256 currentPrice = getLatestPrice(asset);
        
        if (baselinePrice == 0) {
            updatePriceBaseline(asset);
            return false;
        }
        
        // Calculate percentage change (multiply by 10000 for precision)
        uint256 percentageChange;
        if (currentPrice > baselinePrice) {
            percentageChange = uint256((currentPrice - baselinePrice) * 10000 / baselinePrice);
        } else {
            percentageChange = uint256((baselinePrice - currentPrice) * 10000 / baselinePrice);
        }
        
        // Check if change exceeds threshold
        if (percentageChange >= alertThresholds[asset] * 100) {
            emit AssetPriceAlert(asset, baselinePrice, currentPrice, percentageChange);
            return true;
        }
        
        return false;
    }
}