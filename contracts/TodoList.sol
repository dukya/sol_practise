// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract TodoList {
    // 结构体声明
    struct Todo {
        string name;
        bool isCompleted;
    }
    Todo[] public list; // 存储在storage中的动态数组

    // 创建任务
    function create(string memory name_) external {
        list.push(Todo({name: name_, isCompleted: false}));
    }

    // 修改任务名称
    function modifyName1(uint256 index_, string memory name_) external {
        // 方法1: 直接修改，修改一个属性时候比较省gas
        list[index_].name = name_;
    }

    function modifyName2(uint256 index_, string memory name_) external {
        // 方法2: 先获取并存储到storage，在修改多个属性的时候比较省gas
        Todo storage temp = list[index_]; // TODO:这里相当于是引用吗?
        temp.name = name_;
    }

    // 修改完成状态1:手动指定完成或者未完成
    function modifyStatus1(uint256 index_, bool status_) external {
        list[index_].isCompleted = status_;
    }

    // 修改完成状态2:自动切换toggle
    function modifyStatus2(uint256 index_) external {
        list[index_].isCompleted = !list[index_].isCompleted;
    }

    // 获取任务1: memory : 2次拷贝
    // 29448 gas
    function get1(
        uint256 index_
    ) external view returns (string memory name_, bool status_) {
        Todo memory temp = list[index_]; // storage拷贝到memory上?
        return (temp.name, temp.isCompleted); // 再将memory上的temp变量每个成员拷贝一份?
    }

    // 获取任务2: storage : 1次拷贝
    // 预期：get2的gas费用比较低（相对于get1）
    // 29388 gas
    function get2(
        uint256 index_
    ) external view returns (string memory name_, bool status_) {
        Todo storage temp = list[index_]; // 此处应该是引用方式(即temp进行改变应该会影响list[index_]对应的变量)
        return (temp.name, temp.isCompleted); // 将storage上的temp变量每个成员拷贝一份?
    }
}
