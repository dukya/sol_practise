// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
- 任何人都可以发送金额到合约
- 只有owner可以取款
- 有3种取钱方式
*/
contract EtherWallet {
    // 状态变量
    address payable public immutable owner;
    // 事件定义
    event Log(string funName, address from, uint256 value, bytes data);

    // 构造函数
    constructor() {
        owner = payable(msg.sender);
    }

    // 收款函数
    receive() external payable {
        emit Log("receive", msg.sender, msg.value, "");
    }

    // fallback()函数
    fallback() external payable {
        emit Log("fallback", msg.sender, msg.value, "");
    }

    // 函数修饰器
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // 取款方式1
    function withdraw1(uint256 amount) external onlyOwner {
        uint256 total = getBalance();
        require(total >= amount, "Not enough balance");
        // owner.transfer相比msg.sender更消耗Gas
        // owner.transfer(address(this).balance);
        payable(msg.sender).transfer(total);
    }

    // 取款方式2
    function withdraw2(uint256 amount) external onlyOwner {
        uint256 total = getBalance();
        require(total >= amount, "Not enough balance");
        bool success = payable(msg.sender).send(total);
        require(success, "Send Failed");
    }

    // 取款方式3
    function withdraw3(uint256 amount) external onlyOwner {
        uint256 total = getBalance();
        require(total >= amount, "Not enough balance");
        (bool success, ) = msg.sender.call{value: total}("");
        require(success, "Call Failed");
    }

    // 当前合约的balance总余额
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
