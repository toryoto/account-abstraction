// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "../core/BasePaymaster.sol";
import "../core/Helpers.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract VerifyingPaymaster is BasePaymaster {
    using ECDSA for bytes32;

    address public immutable verifyingSigner;

    constructor(IEntryPoint _entryPoint, address _verifyingSigner)
        BasePaymaster(_entryPoint)
    {
        verifyingSigner = _verifyingSigner;
    }

    /// @notice 署名対象のハッシュ（EIP-191 / eth_sign）
    function _signingHash(
        PackedUserOperation calldata userOp
    ) internal view returns (bytes32) {
        // EntryPoint 準拠のハッシュ（= 署名を除く本体 + EntryPoint + chainid）
        bytes32 uoHash = entryPoint.getUserOpHash(userOp);
        bytes32 digest = keccak256(abi.encode(uoHash, address(this), block.chainid));
        return MessageHashUtils.toEthSignedMessageHash(digest);
    }

    /**
     * paymasterAndData[:20] : address(this)
     * paymasterAndData[20:] : signature (64 or 65 bytes)
     */
    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 /*userOpHash*/,
        uint256 /*maxCost*/
    ) internal override returns (bytes memory context, uint256 validationData) {
        bytes calldata pmd = userOp.paymasterAndData;
        require(pmd.length >= 20, "VerifyingPaymaster: bad paymasterAndData");

        // 先頭20バイトが自アドレスであることを確認
        address pmdAddr = address(bytes20(pmd[:20]));
        require(pmdAddr == address(this), "VerifyingPaymaster: wrong paymaster");

        // 署名取り出し
        bytes calldata signature = pmd[20:];
        require(
            signature.length == 64 || signature.length == 65,
            "VerifyingPaymaster: bad sig length"
        );

        // 署名検証（EIP-191）
        bytes32 hash = _signingHash(userOp);
        address recovered = ECDSA.recover(hash, signature);

        if (recovered != verifyingSigner) {
            return ("", SIG_VALIDATION_FAILED);
        }
        return ("", SIG_VALIDATION_SUCCESS);
    }
}
