// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
1、所有人都可以存钱(ETH)
2、只有合约owner才可以取钱
3、只要取钱，合约就销毁掉selfdestruct
4、可扩展点：支持主币之外的资产(比如ERC20和ERC721)
*/

contract Bank {
    // 状态变量
    address public immutable owner;
    // 事件定义
    event Deposit(address sender, uint256 amount);
    event Withdraw(uint256 amount);

    // 构造函数
    constructor() {
        owner = msg.sender;
    }

    // 接收转账(TODO:如何向该合约进行转账?)
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // 合约拥有者进行取钱操作
    function withdraw() public {
        require(msg.sender == owner, "Not owner");
        uint256 cur_balance = getBalance();
        emit Withdraw(cur_balance);
        // selfdestruct(payable(msg.sender));
        (bool success, ) = payable(owner).call{value: cur_balance}("");
        if (!success) {
            revert("withdraw failed");
        }
        // require(success, "withdraw failed");
    }

    // 获取当前合约的balance值
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
