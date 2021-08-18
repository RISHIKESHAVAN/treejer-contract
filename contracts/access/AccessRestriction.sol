// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/** @title AccessRestriction contract */

contract AccessRestriction is AccessControlUpgradeable, PausableUpgradeable {
    bytes32 public constant PLANTER_ROLE = keccak256("PLANTER_ROLE");
    bytes32 public constant TREEJER_CONTRACT_ROLE =
        keccak256("TREEJER_CONTRACT_ROLE");

    /** NOTE {isAccessRestriction} set inside the initialize to {true} */
    bool public isAccessRestriction;

    /**
     * @dev initialize accessRestriction contract and set true for {isAccessRestriction}
     * @param _deployer address of the deployer that DEFAULT_ADMIN_ROLE set to it
     */
    function initialize(address _deployer) public initializer {
        AccessControlUpgradeable.__AccessControl_init();
        PausableUpgradeable.__Pausable_init();

        isAccessRestriction = true;

        if (hasRole(DEFAULT_ADMIN_ROLE, _deployer) == false) {
            _setupRole(DEFAULT_ADMIN_ROLE, _deployer);
        }
    }

    /** NOTE modifier to check msg.sender has admin role */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        _;
    }

    /**
     * @dev check if given address is planter
     * @param _address input address
     */
    function ifPlanter(address _address) public view {
        require(isPlanter(_address), "Caller is not a planter");
    }

    /**
     * @dev check if given address has planter role
     * @param _address input address
     * @return if given address has planter role
     */
    function isPlanter(address _address) public view returns (bool) {
        return hasRole(PLANTER_ROLE, _address);
    }

    /**
     * @dev check if given address is admin
     * @param _address input address
     */
    function ifAdmin(address _address) public view {
        require(isAdmin(_address), "Caller is not admin");
    }

    /**
     * @dev check if given address has admin role
     * @param _address input address
     * @return if given address has admin role
     */
    function isAdmin(address _address) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    /** @dev check if functionality is not puased */
    function ifNotPaused() public view {
        require(!paused(), "Pausable: paused");
    }

    /** @dev check if functionality is puased */
    function ifPaused() public view {
        require(paused(), "Pausable: not paused");
    }

    /** @dev pause functionality */
    function pause() external onlyAdmin {
        _pause();
    }

    /** @dev unpause functionality */
    function unpause() external onlyAdmin {
        _unpause();
    }

    /**
     * @dev check if given address is Treejer contract
     * @param _address input address
     */
    function ifTreejerContract(address _address) public view {
        require(isTreejerContract(_address), "caller is not treejer contract");
    }

    /**
     * @dev check if given address has Treejer contract role
     * @param _address input address
     * @return if given address has Treejer contract role
     */
    function isTreejerContract(address _address) public view returns (bool) {
        return hasRole(TREEJER_CONTRACT_ROLE, _address);
    }

    /**
     * @dev check if given address is Admin or Treejer contract
     * @param _address input address
     */
    function ifAdminOrTreejerContract(address _address) public view {
        require(
            isAdmin(_address) || isTreejerContract(_address),
            "not Admin or Treejer Contract"
        );
    }
}
