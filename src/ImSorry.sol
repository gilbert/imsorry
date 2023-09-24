// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ItsOk {
    function youCanCallMe(address from, uint amount, bytes calldata data) external;
}

contract ImSorry {
    uint feesBalance;
    mapping(address => uint) public balances;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'ImSorry: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function deposit() external payable lock {
        balances[msg.sender] += msg.value;
    }

    function withdraw(address to) external lock {
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;

        // A user's share of the total fees is their share of the total balance
        uint feeShare = feesBalance * amount / address(this).balance;
        feesBalance -= feeShare;

        payable(to).transfer(amount + feeShare);
    }

    function flashLoan(uint amountOut, address to, bytes calldata data) external lock {
        uint balance0 = address(this).balance;
        to.call{value: amountOut}(data);
        ItsOk(to).youCanCallMe(msg.sender, amountOut, data);

        // 1% fee
        uint fee = amountOut / 100;
        feesBalance += fee;
        require(address(this).balance == balance0 + fee, "ImSorry: You have to pay");
    }

    receive() external payable {
        require(unlocked == 1, "Not flashLoaning");
    }
}
