//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "lib/forge-std/src/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {MinimalAccount} from "../src/ethereum/MinimalAcc.sol";
import {console2} from "forge-std/console2.sol";

contract DeployMinimal is Script {
    function run() public {
        (, MinimalAccount minimalAccount) = deployMinimalAccount();
        console2.log("MinimalAccount deployed to:", address(minimalAccount));
    }

    function deployMinimalAccount() public returns(HelperConfig, MinimalAccount) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        MinimalAccount minimalAccount = new MinimalAccount(config.entryPoint);
        minimalAccount.transferOwnership(config.account);
        vm.stopBroadcast();

        return (helperConfig, minimalAccount);
    }
}