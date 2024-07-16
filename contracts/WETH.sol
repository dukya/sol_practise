// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
包装ETH主币，实现ERC20的方法
*/
contract WETH {
    // 常量定义
    string public constant name = "Wrapped Ether";
    string public constant symbol = "WETH";
    uint8 public constant decimals = 18;

    // 事件定义
    event Approval(
        address indexed src,
        address indexed delegateAds,
        uint256 amount
    );
    event Transfer(address indexed src, address indexed toAds, uint256 amount);
    event Deposit(address indexed toAds, uint256 amount);
    event Withdraw(address indexed src, uint256 amount);

    // 状态变量
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // 存款函数(可进行收款操作)
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // 取款函数
    function withdraw(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    // 当前合约的balance总量
    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    // 调用方(原始转账方)授权delegateAds地址可以帮忙转出amount数量的资产
    function approve(
        address delegateAds,
        uint256 amount
    ) public returns (bool) {
        // 原始转账方授权delegateAds地址amount的转账额度
        allowance[msg.sender][delegateAds] = amount;
        emit Approval(msg.sender, delegateAds, amount);
        return true;
    }

    // 调用方(原始转账方)向指定地址转移amount数量的资产
    function transfer(address toAds, uint256 amount) public returns (bool) {
        return transferFrom(msg.sender, toAds, amount);
    }

    // 授权方转移原始转账方的amount资产
    function transferFrom(
        address src,
        address toAds,
        uint256 amount
    ) public returns (bool) {
        // 确保原始转账方的余额不小于待转出的金额
        require(balanceOf[src] >= amount);
        // 若是授权方调用函数，则进入下面逻辑(确保授权额度不小于转账金额，并减少对应的授权额度)
        if (src != msg.sender) {
            require(allowance[src][msg.sender] >= amount);
            allowance[src][msg.sender] -= amount;
        }
        // 原始转账方的余额减少
        balanceOf[src] -= amount;
        // 收账方的余额增加
        balanceOf[toAds] += amount;
        emit Transfer(src, toAds, amount);
        return true;
    }

    // receive()函数
    receive() external payable {
        deposit();
    }

    // fallback()函数
    fallback() external payable {
        deposit();
    }
}
