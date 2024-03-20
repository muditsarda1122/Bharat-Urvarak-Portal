//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Retailer} from "./Retailer.sol";

contract Farmer {
    Retailer retailer;

    struct FarmerInventory {
        uint256 fertilizerId;
        string fertilizerName;
        uint256 uniqueFertilizerIdentifier;
        uint256 fertilizerQuantity;
        uint256 fertilizerPrice;
    }
    FarmerInventory[] public inventory;

    struct RetailerInfo {
        string nameOfRetailer;
        uint256 uniqueRetailerIdentifier;
        address retailerAddress;
    }
    RetailerInfo[] public retailerInfo;

    address public owner;

    event FertilizerBought(
        string nameOfFertilizer,
        uint256 quantityOfFertilizer,
        uint256 priceOfFertilizer
    );
    event RetailerInfoAdded(string nameOfRetailer, address retailerAddress);

    error RetailerInfoNotYetAdded();
    error FertilizerNotFound();
    error RetailerNotFound();

    modifier onlyOwner() {
        require(msg.sender == owner, "caller must be the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function buyFertilizerFromRetailer(
        string memory _nameOfRetailer,
        string memory _nameOfManufacturer,
        string memory _fertilizerName,
        uint256 _fertilizerQuantity,
        uint256 _fertilizerPrice
    ) internal onlyOwner returns (bool) {
        require(
            _fertilizerQuantity != 0,
            "fertilizer quantity can not be equal to zero"
        );
        require(_fertilizerPrice != 0, "fertilizer price can not be zero");

        bool succeeded = retailer.sellFertilizerToFarmer(
            _nameOfManufacturer,
            _fertilizerName,
            _fertilizerQuantity,
            _fertilizerPrice
        );
        require(succeeded, "transaction failed");

        uint256 _fertilizerId = getfertilizerIdByName(_fertilizerName);
        uint256 _uniqueFertilizerIdentifier = uint256(
            keccak256(bytes(_fertilizerName))
        );

        // the fertilizer has been bought before and hence we need to only increment the quantity
        if (_fertilizerId < inventory.length) {
            inventory[_fertilizerId].fertilizerQuantity += _fertilizerQuantity;

            emit FertilizerBought(
                _fertilizerName,
                _fertilizerQuantity,
                _fertilizerPrice
            );
        }
        // the fertilizer has never been bought before so we need to register a new FarmerInventory type struct
        else {
            FarmerInventory memory _farmerInventory = FarmerInventory({
                fertilizerId: _fertilizerId,
                fertilizerName: _fertilizerName,
                uniqueFertilizerIdentifier: _uniqueFertilizerIdentifier,
                fertilizerQuantity: _fertilizerQuantity,
                fertilizerPrice: _fertilizerPrice
            });
            inventory.push(_farmerInventory);

            emit FertilizerBought(
                _fertilizerName,
                _fertilizerQuantity,
                _fertilizerPrice
            );
        }

        address _retailerAddress;
        uint256 _uniqueRetailerIdentifier = uint256(
            keccak256(bytes(_nameOfRetailer))
        );
        for (uint256 i = 0; i < retailerInfo.length; i++) {
            if (
                retailerInfo[i].uniqueRetailerIdentifier ==
                _uniqueRetailerIdentifier
            ) {
                _retailerAddress = retailerInfo[i].retailerAddress;
            }
        }
        if (_retailerAddress == address(0)) {
            revert RetailerInfoNotYetAdded();
        }

        uint256 amountToBePaid = _fertilizerQuantity * _fertilizerPrice;

        (bool success, ) = _retailerAddress.call{value: amountToBePaid}("");
        require(success, "payment failed to retailer");

        return true;
    }

    function addRetailerInfo(
        string memory _nameOfRetailer,
        address _retailerAddress
    ) internal onlyOwner {
        require(
            _retailerAddress != address(0),
            "Enter a valid retailer address"
        );
        uint256 _uniqueRetailerIdentifier = uint256(
            keccak256(bytes(_nameOfRetailer))
        );

        RetailerInfo memory _retailerInfo = RetailerInfo({
            nameOfRetailer: _nameOfRetailer,
            uniqueRetailerIdentifier: _uniqueRetailerIdentifier,
            retailerAddress: _retailerAddress
        });
        retailerInfo.push(_retailerInfo);

        emit RetailerInfoAdded(_nameOfRetailer, _retailerAddress);
    }

    ///////////////////
    // GETTERS ////////
    ///////////////////
    function getfertilizerIdByName(
        string memory _fertilizerName
    ) public view returns (uint256 fertilizerID) {
        uint256 _uniqueFertilizerIdentifier = uint256(
            keccak256(bytes(_fertilizerName))
        );

        bool fertilizerIdFound = false;
        for (uint256 i = 0; i < inventory.length; i++) {
            if (
                inventory[i].uniqueFertilizerIdentifier ==
                _uniqueFertilizerIdentifier
            ) {
                fertilizerIdFound = true;
                return inventory[i].fertilizerId;
            }
        }
        if (fertilizerIdFound == false) {
            return type(uint256).max;
        }
    }

    function getFertilizerInfoUsingFertilizerName(
        string memory _name
    ) public view returns (FarmerInventory memory _inventory) {
        uint256 _uniqueFertilizerIdentifier = uint256(keccak256(bytes(_name)));
        for (uint256 i = 0; i < inventory.length; i++) {
            if (
                inventory[i].uniqueFertilizerIdentifier ==
                _uniqueFertilizerIdentifier
            ) {
                return _inventory = inventory[i];
            }

            if (i == inventory.length - 1) {
                revert FertilizerNotFound();
            }
        }
    }

    function getRetailerInformationUsingRetailerName(
        string memory _name
    ) public view returns (RetailerInfo memory _retailerInfo) {
        uint256 _uniqueRetailerIdentifier = uint256(keccak256(bytes(_name)));
        for (uint256 i = 0; i < retailerInfo.length; i++) {
            if (
                retailerInfo[i].uniqueRetailerIdentifier ==
                _uniqueRetailerIdentifier
            ) {
                return _retailerInfo = retailerInfo[i];
            }

            if (i == retailerInfo.length - 1) {
                revert RetailerNotFound();
            }
        }
    }
}
