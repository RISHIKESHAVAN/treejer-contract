// SPDX-License-Identifier: MIT

pragma solidity ^0.6.9;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../access/IAccessRestriction.sol";

contract TreasuryManager is Initializable {
    bool public isTreasuryManager;
    AssignModel[] public assignModels;
    uint256 public maxAssignedIndex;
    IAccessRestriction public accessRestriction;

    address payable gbFundAddress;
    address payable treeResearchAddress;
    address payable localDevelopAddress;
    address payable rescueFundAddress;
    address payable treejerDevelopAddress;
    address payable otherFundAddress1;
    address payable otherFundAddress2;

    struct FundDistribution {
        uint16 planterFund;
        uint16 gbFund;
        uint16 treeResearch;
        uint16 localDevelop;
        uint16 rescueFund;
        uint16 treejerDevelop;
        uint16 OtherFund1;
        uint16 otherFund2;
    }

    struct TotalFunds {
        uint256 planterFund;
        uint256 gbFund;
        uint256 treeResearch;
        uint256 localDevelop;
        uint256 rescueFund;
        uint256 treejerDevelop;
        uint256 otherFund1;
        uint256 otherFund2;
    }

    struct AssignModel {
        uint256 startingTreeId;
        uint256 distributionModelId;
    }

    mapping(uint256 => FundDistribution) public fundDistributions;
    mapping(uint256 => uint256) public planterFunds;
    mapping(uint256 => uint256) public plantersPaid;
    mapping(address => uint256) public balances;
    TotalFunds public totalFunds = TotalFunds(0, 0, 0, 0, 0, 0, 0, 0);

    event Event1(string description);
    event TreejerWithdraw(string title, uint256 amount, string reason);

    modifier onlyAdmin() {
        accessRestriction.ifAdmin(msg.sender);
        _;
    }

    modifier ifNotPaused() {
        accessRestriction.ifNotPaused();
        _;
    }
    modifier onlyAuction() {
        accessRestriction.ifAuction(msg.sender);
        _;
    }

    function initialize(address _accessRestrictionAddress) public initializer {
        IAccessRestriction candidateContract =
            IAccessRestriction(_accessRestrictionAddress);
        require(candidateContract.isAccessRestriction());
        isTreasuryManager = true;
        accessRestriction = candidateContract;
    }

    function setGbFundAddress(address payable _address) external onlyAdmin {
        gbFundAddress = _address;
    }

    function setTreeResearchAddress(address payable _address)
        external
        onlyAdmin
    {
        treeResearchAddress = _address;
    }

    function setLocalDevelopAddress(address payable _address)
        external
        onlyAdmin
    {
        localDevelopAddress = _address;
    }

    function setRescueFundAddress(address payable _address) external onlyAdmin {
        rescueFundAddress = _address;
    }

    function setTreejerDevelopAddress(address payable _address)
        external
        onlyAdmin
    {
        treejerDevelopAddress = _address;
    }

    function setOtherFund1(address payable _address) external onlyAdmin {
        otherFundAddress1 = _address;
    }

    function setOtherFund2(address payable _address) external onlyAdmin {
        otherFundAddress2 = _address;
    }

    function addFundDistributionModel() external onlyAdmin {}

    function assignTreeFundDistributionModel() external onlyAdmin {}

    function fundTree(uint256 _treeId, uint256 _amount) external {
        require(accessRestriction.isAuction(msg.sender));
        FundDistribution memory dm =
            fundDistributions[_findTreeDistributionModelId(_treeId)];
        planterFunds[_treeId] = (_amount * dm.planterFund) / 1000;
        totalFunds.gbFund += (_amount * dm.gbFund) / 1000;
        totalFunds.localDevelop += (_amount * dm.localDevelop) / 1000;
        totalFunds.otherFund1 += (_amount * dm.OtherFund1) / 1000;
        totalFunds.otherFund2 += (_amount * dm.otherFund2) / 1000;
        totalFunds.planterFund += (_amount * dm.planterFund) / 1000;
        totalFunds.rescueFund += (_amount * dm.rescueFund) / 1000;
        totalFunds.treejerDevelop += (_amount * dm.treejerDevelop) / 1000;
        totalFunds.treeResearch += (_amount * dm.treeResearch) / 1000;
    }

    function _findTreeDistributionModelId(uint256 _treeId)
        private
        returns (uint256)
    {
        uint256 i = 0;
        for (i; i < assignModels.length; i++) {
            if (assignModels[i].startingTreeId > _treeId) {
                return i - 1;
            }
        }
        if (_treeId > maxAssignedIndex) {
            emit Event1("there is no assigned values for this treeId");
        }
        return i;
    }

    function fundPlanter(
        uint256 _treeId,
        address payable _planterId,
        uint16 _treeStatus
    ) external {
        uint256 totalPayablePlanter;
        if (_treeStatus > 30 * 24 * 36) {
            totalPayablePlanter = planterFunds[_treeId] - plantersPaid[_treeId];
        } else {
            totalPayablePlanter = planterFunds[_treeId] * _treeStatus; //TODO: sk farid about here
        }
        if (totalPayablePlanter > 0) {
            plantersPaid[_treeId] += totalPayablePlanter;
            balances[_planterId] += totalPayablePlanter;
            totalFunds.planterFund -= totalPayablePlanter;
        }
    }

    function withdrawTreejerDevelop(uint256 _amount, string memory _reason)
        external
        onlyAdmin
    {
        require(_amount <= totalFunds.treejerDevelop, "insufficient amount");
        totalFunds.treejerDevelop -= _amount;
        if (!treejerDevelopAddress.send(_amount)) {
            emit TreejerWithdraw("treejerDevelop withdraw", _amount, _reason);
        } else {
            totalFunds.treejerDevelop += _amount;
        }
    }

    function withdrawPlanterBalance(uint256 _amount) external {
        accessRestriction.ifPlanter(msg.sender);
        require(_amount <= balances[msg.sender], "insufficient balance");
        balances[msg.sender] -= _amount;
        if (!msg.sender.send(_amount)) {
            balances[msg.sender] += _amount;
        }
    }
}
