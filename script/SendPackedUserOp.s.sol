//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "lib/forge-std/src/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {MinimalAccount} from "../src/ethereum/MinimalAcc.sol";

contract SendPackedUserOp is Script {

    using MessageHashUtils for bytes32;

    uint256 constant AMOUNT = 1e18;

    function run() public {
        // HelperConfig helperConfig = new HelperConfig();
        // address dest = helperConfig.getConfig().usdc; // arbitrum mainnet usdc address
        // uint256 value = 0;
        // address minimalAccountAddress = DevOpsTools.get_most_recent_deployment("MinimalAccount", block.chainid);
        // bytes memory functionData = abi.encodeWithSelector(IERC20.approve.selector, minimalAccountAddress, AMOUNT);
        // bytes memory executeCallData = abi.encodeWithSelector(MinimalAccount.excute.selector, dest, value, functionData);

        // PackedUserOperation memory packedUserOp = generateSignedUserOperation(
        //     executeCallData,
        //     helperConfig.getConfig(),
        //     minimalAccountAddress
        // );
        // PackedUserOperation [] memory ops = new PackedUserOperation[](1);
        // ops[0] = packedUserOp;

        // vm.startBroadcast();
        // IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(ops, payable(helperConfig.getConfig().account));
        // vm.stopBroadcast();
    }

    function generateSignedUserOperation(
        bytes memory callData,
        HelperConfig.NetworkConfig memory config,
        address minimalAccount
        
    ) public view returns (PackedUserOperation memory) {
        // 1. generate unsigned data 
        uint256 nonce = vm.getNonce(minimalAccount) - 1;
        PackedUserOperation memory userOp = _generateUnsignedUserOperation(
            callData,
            minimalAccount,
            nonce
        );
    
        //2. get userOp Hash
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash(); // hash to ETH format

        //3. sign it 
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
         
        if(block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }

        userOp.signature = abi.encodePacked(r, s, v); // r,s,v not vrs
        return userOp;
    }

    function _generateUnsignedUserOperation(bytes memory callData, address sender, uint256 nonce)
        internal pure returns (PackedUserOperation memory) {
            uint256 verificationGasLimit = 999999999; //verify signature
            uint256 callGasLimit = verificationGasLimit;// gas to execute tx
            uint256 maxPriorityFeePerGas = 256;//to block builder
            uint256 maxFeePerGas = maxPriorityFeePerGas;// max fee user accept

            return PackedUserOperation({
                sender: sender,
                nonce: nonce, //Prevents replay attacks
                initCode: hex"", // acc already exists
                callData: callData, // encode func to execute(mint, transfer, etc)
                accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | uint256(callGasLimit)),
                preVerificationGas: verificationGasLimit, //Gas used before execution, by bundler
                gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | uint256(maxFeePerGas)),
                paymasterAndData: hex"", //no paymaster, user pay themselves
                signature: hex"" // unsigned, sig add later 
            });
        }
}