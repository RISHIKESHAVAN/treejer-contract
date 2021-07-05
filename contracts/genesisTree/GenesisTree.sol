//SPDX-License-Identifier: MIT

pragma solidity ^0.6.9;

import "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../access/IAccessRestriction.sol";
import "../gsn/RelayRecipient.sol";
import "../greenblock/IGBFactory.sol";
import "../tree/ITree.sol";
import "../treasury/ITreasury.sol";
import "../planter/IPlanter.sol";

contract GenesisTree is Initializable, RelayRecipient {
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for uint32;
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint64;
    using SafeMathUpgradeable for uint32;
    using SafeMathUpgradeable for uint16;

    bool public isGenesisTree;

    IAccessRestriction public accessRestriction;
    ITree public treeToken;
    IGBFactory public gbFactory;
    ITreasury public treasury;
    IPlanter public planter;

    struct GenTree {
        address payable planterId;
        uint256 treeType;
        uint32 provideStatus;
        uint32 countryCode;
        uint64 treeStatus;
        uint64 plantDate;
        uint64 birthDate;
        string treeSpecs;
    }

    struct UpdateGenTree {
        string updateSpecs;
        uint64 updateStatus;
    }

    mapping(uint256 => GenTree) public genTrees;
    mapping(uint256 => UpdateGenTree) public updateGenTrees;

    event TreePlanted(uint256 treeId, address planter);
    event PlantVerified(uint256 treeId, uint256 updateStatus);
    event TreeUpdated(uint256 treeId);
    event UpdateVerified(uint256 treeId, uint64 updateStatus);

    modifier onlyAdmin() {
        accessRestriction.ifAdmin(_msgSender());
        _;
    }

    modifier ifNotPaused() {
        accessRestriction.ifNotPaused();
        _;
    }

    modifier onlyAuction() {
        accessRestriction.ifAuction(_msgSender());
        _;
    }

    modifier validTree(uint256 _treeId) {
        require(genTrees[_treeId].treeStatus > 0, "invalid tree");
        _;
    }

    modifier validIpfs(string memory _ipfs) {
        require(bytes(_ipfs).length > 0, "invalid ipfs hash");
        _;
    }

    function initialize(address _accessRestrictionAddress) public initializer {
        IAccessRestriction candidateContract = IAccessRestriction(
            _accessRestrictionAddress
        );
        require(candidateContract.isAccessRestriction());
        isGenesisTree = true;
        accessRestriction = candidateContract;
    }

    function setTrustedForwarder(address _address) external onlyAdmin {
        trustedForwarder = _address;
    }

    function setGBFactoryAddress(address _address) external onlyAdmin {
        IGBFactory candidateContract = IGBFactory(_address);
        require(candidateContract.isGBFactory());
        gbFactory = candidateContract;
    }

    function setTreasuryAddress(address _address) external onlyAdmin {
        ITreasury candidateContract = ITreasury(_address);
        require(candidateContract.isTreasury());
        treasury = candidateContract;
    }

    function setPlanterAddress(address _address) external onlyAdmin {
        IPlanter candidateContract = IPlanter(_address);
        require(candidateContract.isPlanter());
        planter = candidateContract;
    }

    function setTreeTokenAddress(address _address) external onlyAdmin {
        ITree candidateContract = ITree(_address);
        require(candidateContract.isTree());
        treeToken = candidateContract;
    }

    function addTree(uint256 _treeId, string memory _treeDescription)
        external
        onlyAdmin
        validIpfs(_treeDescription)
    {
        require(genTrees[_treeId].treeStatus == 0, "duplicate tree");

        genTrees[_treeId] = GenTree(
            address(0),
            0,
            0,
            0,
            1,
            0,
            0,
            _treeDescription
        );
    }

    function asignTreeToPlanter(uint256 _treeId, address payable _planterId)
        external
        onlyAdmin
        validTree(_treeId)
    {
        require(genTrees[_treeId].treeStatus == 1, "the tree is planted");

        (uint8 _planterType, , , , , , , ) = planter.planters(_planterId);

        require(_planterType > 0, "planter not exist");

        genTrees[_treeId].planterId = _planterId;
    }

    function plantTree(
        uint256 _treeId,
        string memory _treeSpecs,
        uint64 _birthDate,
        uint16 _countryCode
    ) external validTree(_treeId) validIpfs(_treeSpecs) {
        require(
            genTrees[_treeId].treeStatus == 1,
            "invalid tree status for plant"
        );

        GenTree storage tempGenTree = genTrees[_treeId];
        bool _canPlant = planter.plantingPermision(
            _msgSender(),
            tempGenTree.planterId
        );
        require(_canPlant, "can't plant");

        if (_msgSender() != tempGenTree.planterId) {
            tempGenTree.planterId = _msgSender();
        }

        updateGenTrees[_treeId] = UpdateGenTree(_treeSpecs, 1);

        tempGenTree.countryCode = _countryCode;
        tempGenTree.birthDate = _birthDate;
        tempGenTree.plantDate = now.toUint64();

        emit TreePlanted(_treeId, tempGenTree.planterId);
    }

    function verifyPlant(uint256 _treeId, bool _isVerified)
        external
        ifNotPaused
        validTree(_treeId)
    {
        require(genTrees[_treeId].treeStatus == 1, "invalid tree status");

        require(
            updateGenTrees[_treeId].updateStatus == 1,
            "invalid update status"
        );

        require(
            genTrees[_treeId].planterId != _msgSender(),
            "Planter of tree can't accept update"
        );

        require(
            accessRestriction.isAdmin(_msgSender()) ||
                _checkPlanter(_treeId, _msgSender()),
            "ambassador or planter can verify plant"
        );

        UpdateGenTree storage tempUpdateGenTree = updateGenTrees[_treeId];

        if (_isVerified) {
            GenTree storage tempGenTree = genTrees[_treeId];

            tempGenTree.treeSpecs = tempUpdateGenTree.updateSpecs;
            tempGenTree.treeStatus = 2;

            tempUpdateGenTree.updateStatus = 3;
        } else {
            tempUpdateGenTree.updateStatus = 2;
        }

        emit PlantVerified(_treeId, tempUpdateGenTree.updateStatus);
    }

    function updateTree(uint256 _treeId, string memory _treeSpecs)
        external
        validTree(_treeId)
        validIpfs(_treeSpecs)
    {
        require(
            genTrees[_treeId].planterId == _msgSender(),
            "Only Planter of tree can send update"
        );
        require(genTrees[_treeId].treeStatus > 1, "Tree not planted");
        require(
            updateGenTrees[_treeId].updateStatus != 1,
            "update genesis tree status is pending"
        );
        require(
            now >=
                genTrees[_treeId].plantDate.add(
                    genTrees[_treeId].treeStatus.mul(3600).add(86400)
                ),
            "Update time not reach"
        );

        UpdateGenTree storage updateGenTree = updateGenTrees[_treeId];

        updateGenTree.updateSpecs = _treeSpecs;
        updateGenTree.updateStatus = 1;

        emit TreeUpdated(_treeId);
    }

    function verifyUpdate(uint256 _treeId, bool _isVerified)
        external
        ifNotPaused
        validTree(_treeId)
    {
        require(
            genTrees[_treeId].planterId != _msgSender(),
            "Planter of tree can't verify update"
        );
        require(
            updateGenTrees[_treeId].updateStatus == 1,
            "update status must be pending"
        );
        require(genTrees[_treeId].treeStatus > 1, "Tree not planted");
        require(
            accessRestriction.isAdmin(_msgSender()) ||
                _checkPlanter(_treeId, _msgSender()),
            "Admin or ambassador or planter can accept updates"
        );

        UpdateGenTree storage updateGenTree = updateGenTrees[_treeId];

        if (_isVerified) {
            GenTree storage genTree = genTrees[_treeId];

            updateGenTree.updateStatus = 3;
            uint32 age = now
            .sub(genTrees[_treeId].plantDate)
            .div(3600)
            .toUint32();
            if (age > genTree.treeStatus) {
                genTree.treeStatus = age;
            }
            genTree.treeSpecs = updateGenTree.updateSpecs;

            if (treeToken.exists(_treeId)) {
                treasury.fundPlanter(
                    _treeId,
                    genTree.planterId,
                    genTree.treeStatus
                );
            }
        } else {
            updateGenTree.updateStatus = 2;
        }

        emit UpdateVerified(_treeId, updateGenTree.updateStatus);
    }

    function availability(uint256 _treeId, uint32 _provideType)
        external
        onlyAuction
        validTree(_treeId)
        returns (uint32)
    {
        if (treeToken.exists(_treeId)) {
            return 1;
        }
        uint32 nowProvideStatus = genTrees[_treeId].provideStatus;

        if (nowProvideStatus == 0) {
            genTrees[_treeId].provideStatus = _provideType;
        }

        return nowProvideStatus;
    }

    function updateOwner(uint256 _treeId, address _ownerId)
        external
        onlyAuction
    {
        genTrees[_treeId].provideStatus = 0;

        treeToken.safeMint(_ownerId, _treeId);
    }

    function updateAvailability(uint256 _treeId) external onlyAuction {
        genTrees[_treeId].provideStatus = 0;
    }

    function updateTreefromOffer(
        uint256 _treeId,
        string memory _specsCid,
        address _owner
    ) external onlyAuction validIpfs(_specsCid) {
        genTrees[_treeId].provideStatus = 0;

        genTrees[_treeId].treeSpecs = _specsCid;

        treeToken.safeMint(_owner, _treeId);
    }

    function _checkPlanter(uint256 _treeId, address _sender)
        private
        view
        returns (bool)
    {
        address _planterAddress = genTrees[_treeId].planterId;

        (uint8 _planterType, , , , , , , ) = planter.planters(_planterAddress);

        (, uint8 _verifierStatus, , , , , , ) = planter.planters(_sender);

        if (_planterType > 1) {
            if (_verifierStatus == 1 || _verifierStatus == 2) {
                if (_planterType == 2) {
                    return planter.memberOf(_sender) == _planterAddress;
                } else if (_planterType == 3) {
                    return
                        planter.memberOf(_sender) ==
                        planter.memberOf(_planterAddress) ||
                        planter.memberOf(_planterAddress) == _sender;
                }
            }
        }
        return false;
    }
}
