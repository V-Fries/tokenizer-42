// SPDX-License-Identifier: MIT
pragma solidity ^0.8.37;

import {Test} from "forge-std/Test.sol";
import {SimpleCoin42} from "../src/SimpleCoin42.sol";

contract SimpleCoin42Test is Test {
    string contractName;
    string contractSymbol;
    uint8 contractDecimals;
    address creator;

    SimpleCoin42 public simpleCoin42;

    function setUp() public {
        contractName = string(vm.randomBytes(vm.randomUint() % 100));
        contractSymbol = string(vm.randomBytes(vm.randomUint() % 100));
        contractDecimals = uint8(vm.randomUint());

        creator = makeAddr("owner");
        hoax(creator);
        simpleCoin42 = new SimpleCoin42(
            contractName,
            contractSymbol,
            contractDecimals
        );
    }

    function test_Name() public view {
        assertEq(simpleCoin42.name(), contractName);
    }

    function test_Symbol() public view {
        assertEq(simpleCoin42.symbol(), contractSymbol);
    }

    function test_Decimals() public view {
        assertEq(simpleCoin42.decimals(), contractDecimals);
    }

    function testFuzz_TotalSupply(
        address user,
        uint256 mintAmount,
        uint256 burnAmount
    ) public {
        vm.assume(user != address(0));
        burnAmount = bound(burnAmount, 0, mintAmount);

        uint256 supplyBeforeMinting = simpleCoin42.totalSupply();

        hoax(creator);
        simpleCoin42.mintTokens(user, mintAmount);

        uint256 supplyAfterMinting = simpleCoin42.totalSupply();

        assertEq(supplyAfterMinting, supplyBeforeMinting + mintAmount);

        hoax(user);
        simpleCoin42.burnTokens(burnAmount);

        assertEq(simpleCoin42.totalSupply(), supplyAfterMinting - burnAmount);
    }

    function testFuzz_BalanceOf(address addr, uint256 balance) public {
        vm.assume(addr != address(0));

        setBalance(addr, balance);
        assertEq(simpleCoin42.balanceOf(addr), balance);
    }

    function testFuzz_Allowance(
        address owner,
        address spender,
        uint256 allowanceToAssign
    ) public {
        setAllowance(owner, spender, allowanceToAssign);
        assertEq(simpleCoin42.allowance(owner, spender), allowanceToAssign);
    }

    function testFuzz_MintTokensValid(address user, uint256 amount) public {
        vm.assume(user != address(0));

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(creator);
        vm.expectEmit();
        emit SimpleCoin42.Transfer(address(0), user, amount);
        simpleCoin42.mintTokens(user, amount);

        assertEq(simpleCoin42.balanceOf(user), amount);
        assertEq(startingSupply + amount, simpleCoin42.totalSupply());
    }

    function testFuzz_MintTokensValidMultipleInARow(
        address user,
        uint256 amount_1,
        uint256 amount_2,
        uint256 amount_3
    ) public {
        vm.assume(user != address(0));
        vm.assume(amount_1 <= type(uint256).max - amount_2);
        vm.assume(amount_1 + amount_2 <= type(uint256).max - amount_3);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(creator);
        vm.expectEmit();
        emit SimpleCoin42.Transfer(address(0), user, amount_1);
        simpleCoin42.mintTokens(user, amount_1);

        assertEq(simpleCoin42.balanceOf(user), amount_1);
        assertEq(startingSupply + amount_1, simpleCoin42.totalSupply());

        hoax(creator);
        vm.expectEmit();
        emit SimpleCoin42.Transfer(address(0), user, amount_2);
        simpleCoin42.mintTokens(user, amount_2);

        assertEq(simpleCoin42.balanceOf(user), amount_1 + amount_2);
        assertEq(
            startingSupply + amount_1 + amount_2,
            simpleCoin42.totalSupply()
        );

        hoax(creator);
        vm.expectEmit();
        emit SimpleCoin42.Transfer(address(0), user, amount_3);
        simpleCoin42.mintTokens(user, amount_3);

        assertEq(simpleCoin42.balanceOf(user), amount_1 + amount_2 + amount_3);
        assertEq(
            startingSupply + amount_1 + amount_2 + amount_3,
            simpleCoin42.totalSupply()
        );
    }

    function testFuzz_MintTokensReceiverIs0(uint256 amount) public {
        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(creator);
        vm.expectRevert("token receiver may not be 0");
        simpleCoin42.mintTokens(address(0), amount);

        assertEq(simpleCoin42.balanceOf(address(0)), 0);
        assertEq(startingSupply, simpleCoin42.totalSupply());
    }

    function testFuzz_MintTokensCallerIsNotCreator(
        address user,
        uint256 amount
    ) public {
        vm.assume(user != creator);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(user);
        vm.expectRevert("Requires caller to be the contract creator");
        simpleCoin42.mintTokens(user, amount);

        assertEq(simpleCoin42.balanceOf(user), 0);
        assertEq(startingSupply, simpleCoin42.totalSupply());
    }

    function testFuzz_burnTokensValid(
        address user,
        uint256 userBalance,
        uint256 toBurn
    ) public {
        vm.assume(user != address(0));
        vm.assume(userBalance >= toBurn);

        setBalance(user, userBalance);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(user);
        vm.expectEmit();
        emit SimpleCoin42.Transfer(user, address(0), toBurn);
        simpleCoin42.burnTokens(toBurn);

        assertEq(simpleCoin42.balanceOf(user), userBalance - toBurn);
        assertEq(startingSupply - toBurn, simpleCoin42.totalSupply());
    }

    function testFuzz_burnTokensBalanceTooLow(
        address user,
        uint256 userBalance,
        uint256 toBurn
    ) public {
        vm.assume(user != address(0));
        vm.assume(userBalance < toBurn);

        setBalance(user, userBalance);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleCoin42.InsufficientBalance.selector,
                toBurn,
                userBalance
            )
        );
        simpleCoin42.burnTokens(toBurn);

        assertEq(simpleCoin42.balanceOf(user), userBalance);
        assertEq(startingSupply, simpleCoin42.totalSupply());
    }

    function testFuzz_burnTokensFromValid(
        address owner,
        uint256 initialOwnerBalance,
        address spender,
        uint256 initialSpenderBalance,
        uint256 allowance,
        uint256 toBurn
    ) public {
        vm.assume(owner != address(0));
        vm.assume(spender != address(0));
        vm.assume(initialOwnerBalance >= toBurn);
        vm.assume(allowance >= toBurn);
        vm.assume(
            owner == spender ||
                initialOwnerBalance <= type(uint256).max - initialSpenderBalance
        );

        setBalance(owner, initialOwnerBalance);
        if (spender != owner) {
            setBalance(spender, initialSpenderBalance);
            setAllowance(owner, spender, allowance);
        }

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(spender);
        vm.expectEmit();
        emit SimpleCoin42.Transfer(owner, address(0), toBurn);
        simpleCoin42.burnTokensFrom(owner, toBurn);

        assertEq(simpleCoin42.balanceOf(owner), initialOwnerBalance - toBurn);
        if (spender != owner) {
            assertEq(simpleCoin42.balanceOf(spender), initialSpenderBalance);
            assertEq(
                simpleCoin42.allowance(owner, spender),
                allowance - toBurn
            );
        }
        assertEq(startingSupply - toBurn, simpleCoin42.totalSupply());
    }

    function testFuzz_burnTokensFromInsufficientBalance(
        address owner,
        uint256 initialOwnerBalance,
        address spender,
        uint256 initialSpenderBalance,
        uint256 allowance,
        uint256 toBurn
    ) public {
        vm.assume(owner != address(0));
        vm.assume(spender != address(0));
        vm.assume(initialOwnerBalance < toBurn);
        vm.assume(allowance >= toBurn);
        vm.assume(
            owner == spender ||
                initialOwnerBalance <= type(uint256).max - initialSpenderBalance
        );

        setBalance(owner, initialOwnerBalance);
        if (spender != owner) {
            setBalance(spender, initialSpenderBalance);
            setAllowance(owner, spender, allowance);
        }

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(spender);
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleCoin42.InsufficientBalance.selector,
                toBurn,
                initialOwnerBalance
            )
        );
        simpleCoin42.burnTokensFrom(owner, toBurn);

        assertEq(simpleCoin42.balanceOf(owner), initialOwnerBalance);
        if (spender != owner) {
            assertEq(simpleCoin42.balanceOf(spender), initialSpenderBalance);
            assertEq(simpleCoin42.allowance(owner, spender), allowance);
        }
        assertEq(startingSupply, simpleCoin42.totalSupply());
    }

    function testFuzz_burnTokensFromInsufficientAllowance(
        address owner,
        uint256 initialOwnerBalance,
        address spender,
        uint256 initialSpenderBalance,
        uint256 allowance,
        uint256 toBurn
    ) public {
        vm.assume(owner != address(0));
        vm.assume(spender != address(0));
        vm.assume(owner != spender);
        vm.assume(initialOwnerBalance >= toBurn);
        vm.assume(allowance < toBurn);
        vm.assume(
            initialOwnerBalance <= type(uint256).max - initialSpenderBalance
        );

        setBalance(owner, initialOwnerBalance);
        setBalance(spender, initialSpenderBalance);
        setAllowance(owner, spender, allowance);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(spender);
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleCoin42.InsufficientAllowance.selector,
                toBurn,
                allowance
            )
        );
        simpleCoin42.burnTokensFrom(owner, toBurn);

        assertEq(simpleCoin42.balanceOf(owner), initialOwnerBalance);
        assertEq(simpleCoin42.balanceOf(spender), initialSpenderBalance);
        assertEq(simpleCoin42.allowance(owner, spender), allowance);
        assertEq(startingSupply, simpleCoin42.totalSupply());
    }

    function testFuzz_TransferValid(
        address user,
        uint256 initialUserBalance,
        address dest,
        uint256 initialDestBalance,
        uint256 amount
    ) public {
        vm.assume(user != address(0));
        vm.assume(dest != address(0));
        vm.assume(initialUserBalance >= amount);
        vm.assume(
            user == dest ||
                initialUserBalance <= type(uint256).max - initialDestBalance
        );
        vm.assume(
            user == dest || initialDestBalance <= type(uint256).max - amount
        );

        setBalance(user, initialUserBalance);
        if (user != dest) {
            setBalance(dest, initialDestBalance);
        }

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(user);
        vm.expectEmit();
        emit SimpleCoin42.Transfer(user, dest, amount);
        assertEq(simpleCoin42.transfer(dest, amount), true);

        if (user != dest) {
            assertEq(simpleCoin42.balanceOf(user), initialUserBalance - amount);
            assertEq(simpleCoin42.balanceOf(dest), initialDestBalance + amount);
        } else {
            assertEq(simpleCoin42.balanceOf(user), initialUserBalance);
        }
        assertEq(simpleCoin42.totalSupply(), startingSupply);
    }

    function testFuzz_TransferInsufficientBalance(
        address user,
        uint256 initialUserBalance,
        address dest,
        uint256 initialDestBalance,
        uint256 amount
    ) public {
        vm.assume(user != address(0));
        vm.assume(dest != address(0));
        vm.assume(initialUserBalance < amount);
        vm.assume(
            user == dest ||
                initialUserBalance <= type(uint256).max - initialDestBalance
        );
        vm.assume(
            user == dest || initialDestBalance <= type(uint256).max - amount
        );

        setBalance(user, initialUserBalance);
        if (user != dest) {
            setBalance(dest, initialDestBalance);
        }

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleCoin42.InsufficientBalance.selector,
                amount,
                initialUserBalance
            )
        );
        simpleCoin42.transfer(dest, amount);

        assertEq(simpleCoin42.balanceOf(user), initialUserBalance);
        if (user != dest) {
            assertEq(simpleCoin42.balanceOf(dest), initialDestBalance);
        }
        assertEq(simpleCoin42.totalSupply(), startingSupply);
    }

    function testFuzz_TransferInvalidDest(
        address user,
        uint256 initialUserBalance,
        uint256 amount
    ) public {
        vm.assume(user != address(0));
        vm.assume(initialUserBalance >= amount);

        setBalance(user, initialUserBalance);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(user);
        vm.expectRevert("token receiver may not be 0");
        simpleCoin42.transfer(address(0), amount);

        assertEq(simpleCoin42.balanceOf(user), initialUserBalance);
        assertEq(simpleCoin42.totalSupply(), startingSupply);
    }

    function testFuzz_TransferFromValidOwnerSpenderDestAreDistinct(
        address owner,
        uint256 initialOwnerBalance,
        address spender,
        uint256 initialSpenderBalance,
        address dest,
        uint256 initialDestBalance,
        uint256 allowance,
        uint256 amount
    ) public {
        vm.assume(owner != address(0));
        vm.assume(dest != address(0));
        vm.assume(spender != address(0));
        vm.assume(owner != dest);
        vm.assume(owner != spender);
        vm.assume(dest != spender);
        vm.assume(initialOwnerBalance >= amount);
        vm.assume(allowance >= amount);
        vm.assume(initialDestBalance <= type(uint256).max - amount);
        vm.assume(
            initialOwnerBalance <= type(uint256).max - initialDestBalance
        );
        vm.assume(
            initialOwnerBalance + initialDestBalance <=
                type(uint256).max - initialSpenderBalance
        );

        setBalance(owner, initialOwnerBalance);
        setBalance(spender, initialSpenderBalance);
        setAllowance(owner, spender, allowance);
        setBalance(dest, initialDestBalance);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(spender);
        vm.expectEmit();
        emit SimpleCoin42.Transfer(owner, dest, amount);
        assertEq(simpleCoin42.transferFrom(owner, dest, amount), true);

        assertEq(simpleCoin42.totalSupply(), startingSupply);

        assertEq(simpleCoin42.balanceOf(owner), initialOwnerBalance - amount);
        assertEq(simpleCoin42.balanceOf(dest), initialDestBalance + amount);
        assertEq(simpleCoin42.balanceOf(spender), initialSpenderBalance);
    }

    function testFuzz_TransferFromValidOwnerSpenderDestAreTheSame(
        address owner,
        uint256 initialOwnerBalance,
        uint256 amount
    ) public {
        vm.assume(owner != address(0));
        vm.assume(initialOwnerBalance >= amount);
        vm.assume(initialOwnerBalance <= type(uint256).max - amount);

        setBalance(owner, initialOwnerBalance);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(owner);
        vm.expectEmit();
        emit SimpleCoin42.Transfer(owner, owner, amount);
        assertEq(simpleCoin42.transferFrom(owner, owner, amount), true);

        assertEq(simpleCoin42.totalSupply(), startingSupply);
        assertEq(simpleCoin42.balanceOf(owner), initialOwnerBalance);
    }

    function testFuzz_TransferFromValidOwnerSpenderAreTheSame(
        address owner,
        uint256 initialOwnerBalance,
        address dest,
        uint256 initialDestBalance,
        uint256 amount
    ) public {
        vm.assume(owner != address(0));
        vm.assume(dest != address(0));
        vm.assume(owner != dest);
        vm.assume(initialOwnerBalance >= amount);
        vm.assume(initialDestBalance <= type(uint256).max - amount);
        vm.assume(
            initialOwnerBalance <= type(uint256).max - initialDestBalance
        );

        setBalance(owner, initialOwnerBalance);
        setBalance(dest, initialDestBalance);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(owner);
        vm.expectEmit();
        emit SimpleCoin42.Transfer(owner, dest, amount);
        assertEq(simpleCoin42.transferFrom(owner, dest, amount), true);

        assertEq(simpleCoin42.totalSupply(), startingSupply);

        assertEq(simpleCoin42.balanceOf(owner), initialOwnerBalance - amount);
        assertEq(simpleCoin42.balanceOf(dest), initialDestBalance + amount);
    }

    function testFuzz_TransferFromValidOwnerDestAreTheSame(
        address owner,
        uint256 initialOwnerBalance,
        address spender,
        uint256 initialSpenderBalance,
        uint256 allowance,
        uint256 amount
    ) public {
        vm.assume(owner != address(0));
        vm.assume(spender != address(0));
        vm.assume(owner != spender);
        vm.assume(initialOwnerBalance >= amount);
        vm.assume(allowance >= amount);
        vm.assume(
            initialOwnerBalance <= type(uint256).max - initialSpenderBalance
        );

        setBalance(owner, initialOwnerBalance);
        setBalance(spender, initialSpenderBalance);
        setAllowance(owner, spender, allowance);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(spender);
        vm.expectEmit();
        emit SimpleCoin42.Transfer(owner, owner, amount);
        assertEq(simpleCoin42.transferFrom(owner, owner, amount), true);

        assertEq(simpleCoin42.totalSupply(), startingSupply);

        assertEq(simpleCoin42.balanceOf(owner), initialOwnerBalance);
        assertEq(simpleCoin42.balanceOf(spender), initialSpenderBalance);
    }

    function testFuzz_TransferFromValidBalanceSpenderDestAreTheSame(
        address owner,
        uint256 initialOwnerBalance,
        address dest,
        uint256 initialDestBalance,
        uint256 allowance,
        uint256 amount
    ) public {
        vm.assume(owner != address(0));
        vm.assume(dest != address(0));
        vm.assume(owner != dest);
        vm.assume(initialOwnerBalance >= amount);
        vm.assume(allowance >= amount);
        vm.assume(initialDestBalance <= type(uint256).max - amount);
        vm.assume(
            initialOwnerBalance <= type(uint256).max - initialDestBalance
        );

        setBalance(owner, initialOwnerBalance);
        setAllowance(owner, dest, allowance);
        setBalance(dest, initialDestBalance);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(dest);
        vm.expectEmit();
        emit SimpleCoin42.Transfer(owner, dest, amount);
        assertEq(simpleCoin42.transferFrom(owner, dest, amount), true);

        assertEq(simpleCoin42.totalSupply(), startingSupply);

        assertEq(simpleCoin42.balanceOf(owner), initialOwnerBalance - amount);
        assertEq(simpleCoin42.balanceOf(dest), initialDestBalance + amount);
    }

    function testFuzz_TransferFromInsufficientBalanceOwnerSpenderDestAreDistinct(
        address owner,
        uint256 initialOwnerBalance,
        address spender,
        uint256 initialSpenderBalance,
        address dest,
        uint256 initialDestBalance,
        uint256 allowance,
        uint256 amount
    ) public {
        vm.assume(owner != address(0));
        vm.assume(dest != address(0));
        vm.assume(spender != address(0));
        vm.assume(owner != dest);
        vm.assume(owner != spender);
        vm.assume(dest != spender);
        vm.assume(initialOwnerBalance < amount);
        vm.assume(allowance >= amount);
        vm.assume(
            initialOwnerBalance <= type(uint256).max - initialDestBalance
        );
        vm.assume(
            initialOwnerBalance + initialDestBalance <=
                type(uint256).max - initialSpenderBalance
        );

        setBalance(owner, initialOwnerBalance);
        setBalance(spender, initialSpenderBalance);
        setAllowance(owner, spender, allowance);
        setBalance(dest, initialDestBalance);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(spender);
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleCoin42.InsufficientBalance.selector,
                amount,
                initialOwnerBalance
            )
        );
        simpleCoin42.transferFrom(owner, dest, amount);

        assertEq(simpleCoin42.totalSupply(), startingSupply);

        assertEq(simpleCoin42.balanceOf(owner), initialOwnerBalance);
        assertEq(simpleCoin42.balanceOf(dest), initialDestBalance);
        assertEq(simpleCoin42.balanceOf(spender), initialSpenderBalance);
    }

    function testFuzz_TransferFromInsufficientBalanceOwnerSpenderDestAreTheSame(
        address owner,
        uint256 initialOwnerBalance,
        uint256 amount
    ) public {
        vm.assume(owner != address(0));
        vm.assume(initialOwnerBalance < amount);

        setBalance(owner, initialOwnerBalance);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleCoin42.InsufficientBalance.selector,
                amount,
                initialOwnerBalance
            )
        );
        simpleCoin42.transferFrom(owner, owner, amount);

        assertEq(simpleCoin42.totalSupply(), startingSupply);
        assertEq(simpleCoin42.balanceOf(owner), initialOwnerBalance);
    }

    function testFuzz_TransferFromInsufficientBalanceOwnerSpenderAreTheSame(
        address owner,
        uint256 initialOwnerBalance,
        address dest,
        uint256 initialDestBalance,
        uint256 amount
    ) public {
        vm.assume(owner != address(0));
        vm.assume(dest != address(0));
        vm.assume(owner != dest);
        vm.assume(initialOwnerBalance < amount);
        vm.assume(
            initialOwnerBalance <= type(uint256).max - initialDestBalance
        );

        setBalance(owner, initialOwnerBalance);
        setBalance(dest, initialDestBalance);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleCoin42.InsufficientBalance.selector,
                amount,
                initialOwnerBalance
            )
        );
        simpleCoin42.transferFrom(owner, dest, amount);

        assertEq(simpleCoin42.totalSupply(), startingSupply);

        assertEq(simpleCoin42.balanceOf(owner), initialOwnerBalance);
        assertEq(simpleCoin42.balanceOf(dest), initialDestBalance);
    }

    function testFuzz_TransferFromInsufficientBalanceOwnerDestAreTheSame(
        address owner,
        uint256 initialOwnerBalance,
        address spender,
        uint256 initialSpenderBalance,
        uint256 allowance,
        uint256 amount
    ) public {
        vm.assume(owner != address(0));
        vm.assume(spender != address(0));
        vm.assume(owner != spender);
        vm.assume(initialOwnerBalance < amount);
        vm.assume(allowance >= amount);
        vm.assume(
            initialOwnerBalance <= type(uint256).max - initialSpenderBalance
        );

        setBalance(owner, initialOwnerBalance);
        setBalance(spender, initialSpenderBalance);
        setAllowance(owner, spender, allowance);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(spender);
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleCoin42.InsufficientBalance.selector,
                amount,
                initialOwnerBalance
            )
        );
        simpleCoin42.transferFrom(owner, owner, amount);

        assertEq(simpleCoin42.totalSupply(), startingSupply);

        assertEq(simpleCoin42.balanceOf(owner), initialOwnerBalance);
        assertEq(simpleCoin42.balanceOf(spender), initialSpenderBalance);
    }

    function testFuzz_TransferFromInsufficientBalanceSpenderDestAreTheSame(
        address owner,
        uint256 initialOwnerBalance,
        address dest,
        uint256 initialDestBalance,
        uint256 allowance,
        uint256 amount
    ) public {
        vm.assume(owner != address(0));
        vm.assume(dest != address(0));
        vm.assume(owner != dest);
        vm.assume(initialOwnerBalance < amount);
        vm.assume(allowance >= amount);
        vm.assume(
            initialOwnerBalance <= type(uint256).max - initialDestBalance
        );

        setBalance(owner, initialOwnerBalance);
        setAllowance(owner, dest, allowance);
        setBalance(dest, initialDestBalance);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(dest);
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleCoin42.InsufficientBalance.selector,
                amount,
                initialOwnerBalance
            )
        );
        simpleCoin42.transferFrom(owner, dest, amount);

        assertEq(simpleCoin42.totalSupply(), startingSupply);

        assertEq(simpleCoin42.balanceOf(owner), initialOwnerBalance);
        assertEq(simpleCoin42.balanceOf(dest), initialDestBalance);
    }

    function testFuzz_TransferFromInsufficientAllowanceOwnerSpenderDestAreDistinct(
        address owner,
        uint256 initialOwnerBalance,
        address spender,
        uint256 initialSpenderBalance,
        address dest,
        uint256 initialDestBalance,
        uint256 allowance,
        uint256 amount
    ) public {
        vm.assume(owner != address(0));
        vm.assume(dest != address(0));
        vm.assume(spender != address(0));
        vm.assume(owner != dest);
        vm.assume(owner != spender);
        vm.assume(dest != spender);
        vm.assume(allowance < amount);
        vm.assume(
            initialOwnerBalance <= type(uint256).max - initialDestBalance
        );
        vm.assume(
            initialOwnerBalance + initialDestBalance <=
                type(uint256).max - initialSpenderBalance
        );

        setBalance(owner, initialOwnerBalance);
        setBalance(spender, initialSpenderBalance);
        setAllowance(owner, spender, allowance);
        setBalance(dest, initialDestBalance);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(spender);
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleCoin42.InsufficientAllowance.selector,
                amount,
                allowance
            )
        );
        simpleCoin42.transferFrom(owner, dest, amount);

        assertEq(simpleCoin42.totalSupply(), startingSupply);

        assertEq(simpleCoin42.balanceOf(owner), initialOwnerBalance);
        assertEq(simpleCoin42.balanceOf(dest), initialDestBalance);
        assertEq(simpleCoin42.balanceOf(spender), initialSpenderBalance);
    }

    function testFuzz_TransferFromInsufficientAllowanceOwnerDestAreTheSame(
        address owner,
        uint256 initialOwnerBalance,
        address spender,
        uint256 initialSpenderBalance,
        uint256 allowance,
        uint256 amount
    ) public {
        vm.assume(owner != address(0));
        vm.assume(spender != address(0));
        vm.assume(owner != spender);
        vm.assume(allowance < amount);
        vm.assume(
            initialOwnerBalance <= type(uint256).max - initialSpenderBalance
        );

        setBalance(owner, initialOwnerBalance);
        setBalance(spender, initialSpenderBalance);
        setAllowance(owner, spender, allowance);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(spender);
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleCoin42.InsufficientAllowance.selector,
                amount,
                allowance
            )
        );
        simpleCoin42.transferFrom(owner, owner, amount);

        assertEq(simpleCoin42.totalSupply(), startingSupply);

        assertEq(simpleCoin42.balanceOf(owner), initialOwnerBalance);
        assertEq(simpleCoin42.balanceOf(spender), initialSpenderBalance);
    }

    function testFuzz_TransferFromInsufficientAllowanceSpenderDestAreTheSame(
        address owner,
        uint256 initialOwnerBalance,
        address dest,
        uint256 initialDestBalance,
        uint256 allowance,
        uint256 amount
    ) public {
        vm.assume(owner != address(0));
        vm.assume(dest != address(0));
        vm.assume(owner != dest);
        vm.assume(allowance < amount);
        vm.assume(
            initialOwnerBalance <= type(uint256).max - initialDestBalance
        );

        setBalance(owner, initialOwnerBalance);
        setAllowance(owner, dest, allowance);
        setBalance(dest, initialDestBalance);

        uint256 startingSupply = simpleCoin42.totalSupply();

        hoax(dest);
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleCoin42.InsufficientAllowance.selector,
                amount,
                allowance
            )
        );
        simpleCoin42.transferFrom(owner, dest, amount);

        assertEq(simpleCoin42.totalSupply(), startingSupply);

        assertEq(simpleCoin42.balanceOf(owner), initialOwnerBalance);
        assertEq(simpleCoin42.balanceOf(dest), initialDestBalance);
    }

    function setBalance(address user, uint256 amount) private {
        uint256 currentBalance = simpleCoin42.balanceOf(user);
        uint256 startingSupply = simpleCoin42.totalSupply();

        if (currentBalance > amount) {
            uint256 toBurn = currentBalance - amount;
            hoax(user);
            vm.expectEmit();
            emit SimpleCoin42.Transfer(user, address(0), toBurn);
            simpleCoin42.burnTokens(toBurn);
            assertEq(startingSupply - toBurn, simpleCoin42.totalSupply());
        } else {
            uint256 toMint = amount - currentBalance;
            hoax(creator);
            vm.expectEmit();
            emit SimpleCoin42.Transfer(address(0), user, toMint);
            simpleCoin42.mintTokens(user, toMint);
            assertEq(startingSupply + toMint, simpleCoin42.totalSupply());
        }

        assertEq(simpleCoin42.balanceOf(user), amount);
    }

    function setAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        hoax(owner);
        vm.expectEmit();
        emit SimpleCoin42.Approval(owner, spender, amount);
        simpleCoin42.approve(spender, amount);

        assertEq(simpleCoin42.allowance(owner, spender), amount);
    }
}
