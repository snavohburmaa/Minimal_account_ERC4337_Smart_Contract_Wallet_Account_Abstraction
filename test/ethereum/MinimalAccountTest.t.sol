//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MinimalAccount} from "../../src/ethereum/MinimalAcc.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployMinimal} from "../../script/DeployMinimal.s.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {SendPackedUserOp} from "../../script/SendPackedUserOp.s.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract MinimalAccountTest is Test {

    using MessageHashUtils for bytes32;

    MinimalAccount minimalAccount;
    HelperConfig helperConfig;
    DeployMinimal deployMinimal;
    ERC20Mock usdc;
    SendPackedUserOp sendPackedUserOp;

    uint256 constant AMOUNT = 1e18;
    address anvilDefaultAccount = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address NotOwner = makeAddr("Notowner");

    function setUp() public {
        deployMinimal = new DeployMinimal();
        (helperConfig, minimalAccount) = deployMinimal.deployMinimalAccount();
        usdc = new ERC20Mock();
        sendPackedUserOp = new SendPackedUserOp();
    }

//---------------------------TESTS EXCUTE FUNCTION-----------------------------// 

    //USDC mint
    //msg.sender -> minimal account
    //approve some amount 
    //come from entry point
    function testOwnerCanExcuteCommands() public {
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, 
            address(minimalAccount), AMOUNT);

        vm.prank(minimalAccount.owner());
        minimalAccount.excute(dest, value, functionData);

        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function testNonOwnerCannotExcuteCommands() public {
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, 
            address(minimalAccount), AMOUNT);

        vm.prank(NotOwner);
        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector);
        minimalAccount.excute(dest, value, functionData);
    }

//---------------------------TESTS SIGN USER OP -----------------------------// 

    function testRecoverSignedOp() public {
        //--------- arrange ---------//
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, 
            address(minimalAccount), AMOUNT);

        bytes memory executeCallData = 
            abi.encodeWithSelector(MinimalAccount.excute.selector, dest, value, functionData);

        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(
            executeCallData,
            helperConfig.getConfig(),
            address(minimalAccount)
        );

        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);

        //--------- act ---------//
        address actualSigner = ECDSA.recover(userOperationHash.toEthSignedMessageHash(),
            packedUserOp.signature);

        //--------- assert ---------//
        assertEq(actualSigner, minimalAccount.owner());
    }

    function testValidationOfUserOp() public {
        // sign user Op
        // call validateUserOp
        // assert correct return value 

        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, 
            address(minimalAccount), AMOUNT);

        bytes memory executeCallData = 
            abi.encodeWithSelector(MinimalAccount.excute.selector, dest, value, functionData);

        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(
            executeCallData,
            helperConfig.getConfig(),
            address(minimalAccount)
        );

        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);
        // uint256 missingAccountFunds = 1e18;

        vm.prank(helperConfig.getConfig().entryPoint);
        uint256 validationData = minimalAccount.validateUserOp(
            packedUserOp,
            userOperationHash,
            0 //missin acc funds
        );
        
        assertEq(validationData, 0);

    }

    function testEntryPointCanExecuteCommands() public {
         //--------- arrange ---------//
         assertEq(usdc.balanceOf(address(minimalAccount)), 0);
         address dest = address(usdc);
         uint256 value = 0;
         bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, 
             address(minimalAccount), AMOUNT);
 
         bytes memory executeCallData = 
             abi.encodeWithSelector(MinimalAccount.excute.selector, dest, value, functionData);
 
         PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(
             executeCallData,
             helperConfig.getConfig(),
             address(minimalAccount)
         );
 
        PackedUserOperation [] memory ops = new PackedUserOperation[](1);
         ops[0] = packedUserOp;

         //--------- act ---------// 

         //  tx.origin == msg.sender  
         vm.deal(anvilDefaultAccount, 100 ether);
         
         // Fund minimalacc with ETH -> can pay prefund to EntryPoint
         vm.deal(address(minimalAccount), 10 ether);
         
         vm.startBroadcast(anvilDefaultAccount);
         IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(ops, payable(NotOwner));
         vm.stopBroadcast();

         //--------- assert ---------//
         assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }
}