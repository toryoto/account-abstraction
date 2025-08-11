// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "../interfaces/ISenderCreator.sol";
import "./SimpleAccount.sol";

/**
 * A sample factory contract for SimpleAccount
 * A UserOperations "initCode" holds the address of the factory, and a method call (to createAccount, in this sample factory).
 * The factory's createAccount returns the target account address even if it is already installed.
 * This way, the entryPoint.getSenderAddress() can be called either before or after the account is created.
 */
contract SimpleAccountFactory {
    SimpleAccount public immutable accountImplementation;
    ISenderCreator public immutable senderCreator;

    constructor(IEntryPoint _entryPoint) {
        accountImplementation = new SimpleAccount(_entryPoint);
        senderCreator = _entryPoint.senderCreator();
    }

    // ERC4337対応のアカウントをデプロイしてアドレスを返すメソッド
    // すでに作成済みの場合はそのアドレスを返す
    // CREATE2を使用することで決定論的なアドレス作成をする
    function createAccount(address owner,uint256 salt) public returns (SimpleAccount ret) {
        require(msg.sender == address(senderCreator), "only callable from SenderCreator");
        address addr = getAddress(owner, salt);
        uint256 codeSize = addr.code.length;
        // すでにアカウントがデプロイされている場合は既存のアドレスを返す
        if (codeSize > 0) {
            return SimpleAccount(payable(addr));
        }
        // プロキシパターンでアカウントをデプロイ
        ret = SimpleAccount(payable(new ERC1967Proxy{salt : bytes32(salt)}(
                address(accountImplementation),
                abi.encodeCall(SimpleAccount.initialize, (owner))
            )));
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAddress(address owner,uint256 salt) public view returns (address) {
        return Create2.computeAddress(bytes32(salt), keccak256(abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    address(accountImplementation),
                    abi.encodeCall(SimpleAccount.initialize, (owner))
                )
            )));
    }
}
