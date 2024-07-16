// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
多签钱包的功能: 合约有多个owner，一笔交易发出后，需要多个owner确认，只有确认数达到最低要求之后才可以真正的执行。
- 除了存款外，其他所有方法都需要owner地址才可以触发
- 允许批准的交易，在没有真正执行前取消
- 足够数量的approve后，才允许真正执行
*/
contract MultiSigWallet {
    // 状态变量
    address[] public owners; // 保存多个owner的动态数组
    mapping(address => bool) public isOwner; // 判断当前addr是否为owner
    uint256 public required; // 交易可执行的最低要求数
    // 事务结构体定义
    struct Transaction {
        address to; //转账地址
        uint256 value; //转账金额
        bytes data; //额外数据
        bool exected; //当前事务是否已执行
    }
    Transaction[] public transactions; // 保存所有已提交的事务列表
    mapping(uint256 => mapping(address => bool)) public approved; // 保存对应ID的事务是否被某个owner批准(tx_id -> { owner_addr -> is_approved})

    // 事件定义
    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId);
    event Approve(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);

    // receive收款函数
    receive() external payable {
        emit Deposit(msg.sender, msg.value); // 触发事件
    }

    // 函数修饰器 是否是合约拥有者(不带参数)
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    // 当前事务是否存在(带参数)
    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "tx doesn't exist");
        _;
    }

    // 当前事务是否已经调用方授权过(带参数)
    modifier notApproved(uint256 _txId) {
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }

    // 当前事务是否已经执行过(带参数)
    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].exected, "tx is exected");
        _;
    }

    // 构造函数(多个owner合约地址 + 合约可执行的最低要求数)
    constructor(address[] memory _owners, uint256 _required) {
        // 入参判断
        require(_owners.length > 0, "owner required");
        require(
            _required > 0 && _required <= _owners.length,
            "invalid required number of owners"
        );
        for (uint256 index = 0; index < _owners.length; index++) {
            address owner = _owners[index];
            require(owner != address(0), "invalid owner"); // 判断当前owner地址是否合法
            require(!isOwner[owner], "owner is not unique"); // 如果addr重复会抛出错误
            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    // 当前合约的balance总额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // 当前合约拥有者提交事务等待其他owner批准，返回对应的事务ID编号
    // 事务(收款地址+转账金额+额外数据+未执行状态)
    function submit(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (uint256) {
        transactions.push(
            Transaction({to: _to, value: _value, data: _data, exected: false})
        );
        emit Submit(transactions.length - 1);
        return transactions.length - 1;
    }

    // 当前合约拥有者进行事务批准操作(输入为事务ID编号)
    // 检查条件: 当前合约拥有者、当前事务已存在、当前事务未被该拥有者授权、当前事务还未执行
    function approve(
        uint256 _txId
    ) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId) {
        approved[_txId][msg.sender] = true; // 当前事务已被当前调用方(owner)授权过，即被设置为true
        emit Approve(msg.sender, _txId);
    }

    // 当前合约拥有者进行事务操作(输入为事务ID编号)
    // 检查条件: 当前合约拥有者、 当前事务已存在、 当前事务还未被执行
    function execute(
        uint256 _txId
    ) external onlyOwner txExists(_txId) notExecuted(_txId) {
        // 保证当前事务的批准数不小于最低要求数
        require(getApprovalCount(_txId) >= required, "approvals < required");
        Transaction storage transaction = transactions[_txId]; // 不进行拷贝操作，引用storage的transactions[_txId]
        transaction.exected = true; // 修改对应事务的可执行状态
        // 当前事务保存了转账地址、转账金额、calldata数据
        // 使用call方法真正向转账地址发送对应的转账金额和calldata数据
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");
        emit Execute(_txId);
    }

    // 当前合约拥有者进行事务收回批准的操作
    // 检查条件: 当前合约拥有者、当前事务已存在、当前事务还未执行
    function revoke(
        uint256 _txId
    ) external onlyOwner txExists(_txId) notExecuted(_txId) {
        // 确保当前事务已被当前拥有者批准
        require(approved[_txId][msg.sender], "tx not approved");
        approved[_txId][msg.sender] = false; // 收回批准
        emit Revoke(msg.sender, _txId);
    }

    // 辅助函数, 获取当前事务的被owner批准总数
    function getApprovalCount(
        uint256 _txId
    ) public view returns (uint256 count) {
        for (uint256 index = 0; index < owners.length; index++) {
            if (approved[_txId][owners[index]]) {
                count += 1;
            }
        }
    }
}
