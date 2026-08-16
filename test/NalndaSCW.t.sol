// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {Test} from "forge-std/Test.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {NalndaSCW} from "../src/NalndaSCW.sol";
import {NalndaSCWFactory} from "../src/NalndaSCWFactory.sol";

contract MockEntryPoint {}

contract ExecutionTarget {
    uint256 public value;

    function setValue(uint256 newValue) external {
        value = newValue;
    }
}

contract NalndaSCWTest is Test {
    NalndaSCWFactory private factory;
    IEntryPoint private entryPoint;
    address private owner;

    function setUp() public {
        entryPoint = IEntryPoint(address(new MockEntryPoint()));
        factory = new NalndaSCWFactory(entryPoint);
        owner = makeAddr("owner");
    }

    function testFactoryDeploysCounterfactualAccount() public {
        uint256 salt = 42;
        address predicted = factory.getAddress(owner, salt);

        NalndaSCW account = factory.createAccount(owner, salt);

        assertEq(address(account), predicted);
        assertEq(account.owner(), owner);
        assertEq(address(account.entryPoint()), address(entryPoint));
        assertGt(address(account).code.length, 0);
    }

    function testCreateAccountReturnsExistingAccount() public {
        NalndaSCW first = factory.createAccount(owner, 1);
        NalndaSCW second = factory.createAccount(owner, 1);

        assertEq(address(first), address(second));
    }

    function testAnyoneCanDeployAccount() public {
        address caller = makeAddr("caller");

        vm.prank(caller);
        NalndaSCW account = factory.createAccount(owner, 1);

        assertEq(account.owner(), owner);
    }

    function testOwnerCanExecuteCall() public {
        NalndaSCW account = factory.createAccount(owner, 1);
        ExecutionTarget target = new ExecutionTarget();

        vm.prank(owner);
        account.execute(address(target), 0, abi.encodeCall(ExecutionTarget.setValue, (123)));

        assertEq(target.value(), 123);
    }

    function testOwnerCanTransferOwnership() public {
        NalndaSCW account = factory.createAccount(owner, 1);
        address newOwner = makeAddr("newOwner");

        vm.prank(owner);
        vm.expectEmit(true, true, false, false);
        emit NalndaSCW.OwnershipTransferred(owner, newOwner);
        account.transferOwnership(newOwner);

        assertEq(account.owner(), newOwner);
    }

    function testNonOwnerCannotTransferOwnership() public {
        NalndaSCW account = factory.createAccount(owner, 1);
        address caller = makeAddr("caller");

        vm.prank(caller);
        vm.expectRevert("only owner");
        account.transferOwnership(makeAddr("newOwner"));
    }

    function testCannotTransferOwnershipToZeroAddress() public {
        NalndaSCW account = factory.createAccount(owner, 1);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(NalndaSCW.OwnableInvalidOwner.selector, address(0)));
        account.transferOwnership(address(0));
    }

    function testOwnerCanRenounceOwnership() public {
        NalndaSCW account = factory.createAccount(owner, 1);

        vm.prank(owner);
        account.renounceOwnership();

        assertEq(account.owner(), address(0));
    }

    function testNonOwnerCannotExecuteCall() public {
        NalndaSCW account = factory.createAccount(owner, 1);
        address caller = makeAddr("caller");

        vm.prank(caller);
        vm.expectRevert("account: not Owner or EntryPoint");
        account.execute(address(0), 0, bytes(""));
    }

    function testImplementationCannotBeInitialized() public {
        NalndaSCW implementation = factory.accountImplementation();

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        implementation.initialize(owner);
    }
}
