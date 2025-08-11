// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "../core/BasePaymaster.sol";
import "../core/Helpers.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract VerifyingPaymaster is BasePaymaster {
   using ECDSA for bytes32;
   using UserOperationLib for PackedUserOperation;

   address public immutable verifyingSigner;

   constructor(IEntryPoint _entryPoint, address _verifyingSigner) BasePaymaster(_entryPoint) {
       verifyingSigner = _verifyingSigner;
   }

   // PackedUserOpのデータをエンコードする
   function pack(PackedUserOperation calldata userOp) internal pure returns (bytes memory ret) {
       return abi.encode(
           userOp.sender,
           userOp.nonce,
           userOp.initCode,
           userOp.callData,
           userOp.accountGasLimits,
           userOp.preVerificationGas,
           userOp.gasFees,
           userOp.paymasterAndData,
           userOp.signature
       );
   }

   // オフチェーンの署名用のハッシュを生成
   function getHash(PackedUserOperation calldata userOp) public view returns (bytes32) {
       return keccak256(abi.encode(
           pack(userOp),
           block.chainid,
           address(this)
       ));
   }

   /**
    * paymasterAndData[:20] : address(this)
    * paymasterAndData[20:] : signature
    */
   function _validatePaymasterUserOp(
       PackedUserOperation calldata userOp, 
       bytes32 /*userOpHash*/, 
       uint256 maxCost
   ) internal override returns (bytes memory context, uint256 validationData) {
       (maxCost); // unused parameter
       
       require(userOp.paymasterAndData.length >= 20, "bad paymasterData");
       bytes calldata signature = userOp.paymasterAndData[20:];
       require(signature.length == 64 || signature.length == 65, "VerifyingPaymaster: invalid signature length");
       
       bytes32 hash = MessageHashUtils.toEthSignedMessageHash(getHash(userOp));
       if (verifyingSigner != ECDSA.recover(hash, signature)) {
           return ("", SIG_VALIDATION_FAILED);
       }
       return ("", SIG_VALIDATION_SUCCESS);
   }
}