// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {SimpleAccount} from "account-abstraction/samples/SimpleAccount.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {NalndaSCW} from "./NalndaSCW.sol";

contract NalndaSCWFactory {
    NalndaSCW public immutable accountImplementation;

    constructor(IEntryPoint entryPoint) {
        accountImplementation = new NalndaSCW(entryPoint);
    }

    function createAccount(address owner, uint256 salt) public returns (NalndaSCW account) {
        address accountAddress = getAddress(owner, salt);
        if (accountAddress.code.length > 0) {
            return NalndaSCW(payable(accountAddress));
        }

        account = NalndaSCW(
            payable(address(
                    new ERC1967Proxy{salt: bytes32(salt)}(
                        address(accountImplementation), abi.encodeCall(SimpleAccount.initialize, (owner))
                    )
                ))
        );
    }

    function getAddress(address owner, uint256 salt) public view returns (address) {
        return Create2.computeAddress(
            bytes32(salt),
            keccak256(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(address(accountImplementation), abi.encodeCall(SimpleAccount.initialize, (owner)))
                )
            )
        );
    }
}
