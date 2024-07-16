// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
简单的众筹合约示例
*/
contract CrowdFunding {
    // 状态变量
    address public immutable beneficiary; // 受益人
    uint256 public immutable fundingGoal; // 需要筹资的目标金额
    uint256 public fundingAmount; // 当前已募集的金额
    mapping(address => uint256) public funders; // 资助者address -> 资助金额
    mapping(address => bool) private fundersInserted; // 资助者是否之前已资助过
    address[] public fundersKey; // 保存资助者address的动态数组
    bool public AVAILABLED = true; // 不用自销毁方法，使用变量来控制本次众筹的状态

    // 部署的时候，写入受益人地址+筹资目标数量
    constructor(address beneficiary_, uint256 goal_) {
        beneficiary = beneficiary_;
        fundingGoal = goal_;
    }

    // 资助函数
    // 本次众筹可用时才可以捐。合约关闭之后，就不能再操作了
    function contribute() external payable {
        require(AVAILABLED, "CrowdFunding is closed");

        // 检查捐赠金额是否会超过目标金额
        uint256 potentialFundingAmount = fundingAmount + msg.value;
        uint256 refundAmount = 0; // 保存需要退还的金额

        if (potentialFundingAmount > fundingGoal) {
            refundAmount = potentialFundingAmount - fundingGoal; // 计算需退还的金额
            funders[msg.sender] += (msg.value - refundAmount);
            fundingAmount += (msg.value - refundAmount);
        } else {
            funders[msg.sender] += msg.value; // 同一个资助人可以资助多次
            fundingAmount += msg.value;
        }

        // 更新资助者的信息(第一次资助才需要进行更新操作)
        if (!fundersInserted[msg.sender]) {
            fundersInserted[msg.sender] = true;
            fundersKey.push(msg.sender);
        }

        // 退还多余的金额给当前的资助者
        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount);
        }
    }

    // 判断是否关闭本次众筹
    function close() external returns (bool) {
        // 1.检查
        if (fundingAmount < fundingGoal) {
            return false;
        }
        uint256 amount = fundingAmount;
        // 2.修改状态
        fundingAmount = 0;
        AVAILABLED = false;
        // 3.向受益人转账目标金额
        payable(beneficiary).transfer(amount);
        return true;
    }

    // 获取资助者的人数
    function fundersLenght() public view returns (uint256) {
        return fundersKey.length;
    }
}
