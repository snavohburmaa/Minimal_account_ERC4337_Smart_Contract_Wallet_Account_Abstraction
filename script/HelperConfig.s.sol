//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "lib/forge-std/src/Script.sol";
import {MinimalAccount} from "../src/ethereum/MinimalAcc.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    error HelperConifg__InvalidChainId();

    struct NetworkConfig { 
        address entryPoint;
        address account;
        address usdc;
    }

    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant LOCAL_CHAIN_ID = 31337;
    uint256 constant ARBITRUM_SEPOLIA_CHAIN_ID = 42161;
    uint256 constant ETH_MAINNET_CHAIN_ID = 1;

    address constant BURNER_WALLET = 0xc2013a8a76BAC5914a88bf2F809334468332589d; // for burning tokens, metmask
    // address constant FOUNDRY_DEFAUT_WALLET = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38; // for foundry default wallet
    address constant ANVIL_DEFAULT_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;


    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        networkConfigs[ZKSYNC_SEPOLIA_CHAIN_ID] = getZksyncSepoliaConfig();
        networkConfigs[ARBITRUM_SEPOLIA_CHAIN_ID] = getArbSepoliaConfig();
        // networkConfigs[ETH_MAINNET_CHAIN_ID] = getEthMainnetConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if(chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else if (networkConfigs[chainId].account != address(0)) {
            return networkConfigs[chainId];
        } else {
            revert HelperConifg__InvalidChainId();
        }
    }

    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: 0x5FbDB2315678afecb367f032d93F642f64180aa3,
            account: BURNER_WALLET,
            usdc: address(0) // Placeholder - set to actual USDC address
        });
    }

    // function getEthMainnetConfig() public pure returns (NetworkConfig memory) {
    //     return NetworkConfig({
    //         entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032,
    //         usdc: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
    //         account: BURNER_WALLET
    //     });
        // https://blockscan.com/address/0x0000000071727De22E5E9d8BAf0edAc6f37da032
    // }

    // function getArbMainnetConfig() public pure returns (NetworkConfig memory) {
    //     return NetworkConfig({
    //         entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032,
    //         usdc: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831,
    //         account: BURNER_WALLET
    //     });
    // }

    function getZksyncSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: address(0),
            account: BURNER_WALLET,
            usdc: address(0) // Placeholder - set to actual USDC address
        });
    }

    function getArbSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
            usdc: address(0), 
            account: BURNER_WALLET
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.account != address(0)) {
            return localNetworkConfig;
        }

        //deploy mocks 
        vm.startBroadcast(ANVIL_DEFAULT_ACCOUNT);
        EntryPoint entryPoint = new EntryPoint();
        vm.stopBroadcast();
        // Create and store new config if it doesn't exist
        localNetworkConfig = NetworkConfig({
            entryPoint: address(entryPoint),
            account: ANVIL_DEFAULT_ACCOUNT,
            usdc: address(0) // Use mock ERC20 for local testing if needed
        });
        return localNetworkConfig;
    }   
}