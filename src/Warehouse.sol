// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {Manufacturer} from "./Manufacturer.sol";

contract Warehouse {
    Manufacturer manufacturer;
    // I have assumed that one manufacturer has one warehouse where he stores all his products and sells to retailers.

    // The manufacturer needs to send fertilizer in the right order of fertilizerId. eg. If he has sent till date fertilizers
    // with fertilizerIds 0,1,2 he can not send fertilizer with fertilizerId 4, he needs to first send fertilizerId 3.

    uint256[] listOfFertilizerId;
    // I have assumed that the manufacturer, at a time, sends fertilizer of only one kind to the warehouse.
    Manufacturer.Consignment[] listOfAllConignmentsReceived;

    struct FertilizerInfo {
        uint256 fertilizerId;
        string nameOfFertilizer;
        uint256 uniqueFertilizerIdentifier;
    }
    FertilizerInfo[] public fertilizerInfo;

    struct FertilizerSold {
        string nameOfFertilizer;
        uint256 fertilizerPrice;
        uint256 fertilizerQuantity;
    }
    FertilizerSold[] public fertilizerSold;

    mapping(uint256 fertilizerId => uint256 quantity) fertilizerIdToQuantity;
    mapping(uint256 fertilizerId => uint256 subsidisedPrice) fertilizerIdToSubsidisedPrice;

    // the warehouse can hold a maximum of 10000 sacks of fertilizers(kind does not matter, size of all sacks is same).
    uint256 immutable MAX_QUANTITY = 10000;
    uint256 public totalQuantity;

    address immutable owner;
    address public addressOfManufacturer;

    event ConsignmentReceivedFromManufacturer(
        uint256 consignmentId,
        uint256 fertilizerId,
        uint256 fertilizerQuantity,
        uint256 fertilizerSubsidisedPrice
    );
    event FertilizerSoldToRetailer(
        string nameOfFertilizer,
        uint256 fertilizerQuantity
    );

    error InvalidFertilizerId();

    modifier onlyOwner() {
        require(msg.sender != owner, "can be called only by warehouse owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function receiveConsignmentFromManufacturer(
        Manufacturer.Consignment memory _consignment,
        string memory _fertilizerName,
        uint256 _fertilizerSubsidisedPrice
    ) public returns (bool) {
        uint256 _consignmentId = _consignment.consignmentId;
        uint256 _fertilizerId = _consignment.fertilizerId;
        uint256 _fertilizerQuantity = _consignment.fertilizerQuantity;
        uint256 _uniqueFertilizerInfo = uint256(
            keccak256(bytes(_fertilizerName))
        );

        require(
            totalQuantity <= MAX_QUANTITY,
            "Quantity has exceeded maximum capacity of warehouse"
        );
        require(
            totalQuantity + _fertilizerQuantity <= MAX_QUANTITY,
            "Can not receive entire consignment because the maximum capacity will be exceeded"
        );

        if (_fertilizerId < numberOfFertilizers()) {
            uint256 oldQuantity = fertilizerIdToQuantity[_fertilizerId];
            uint256 newQuantity = oldQuantity + _fertilizerQuantity;
            uint256 ferilizerSubsidisedPrice = fertilizerIdToSubsidisedPrice[
                _fertilizerId
            ];

            fertilizerIdToQuantity[_fertilizerId] = newQuantity;
            totalQuantity += _fertilizerQuantity;

            listOfAllConignmentsReceived.push(_consignment);

            emit ConsignmentReceivedFromManufacturer(
                _consignmentId,
                _fertilizerId,
                _fertilizerQuantity,
                ferilizerSubsidisedPrice
            );
        } else if (_fertilizerId == numberOfFertilizers()) {
            listOfFertilizerId.push(_fertilizerId);
            fertilizerIdToQuantity[_fertilizerId] = _fertilizerQuantity;
            fertilizerIdToSubsidisedPrice[
                _fertilizerId
            ] = _fertilizerSubsidisedPrice;

            FertilizerInfo memory _fertilizerInfo = FertilizerInfo({
                fertilizerId: _fertilizerId,
                nameOfFertilizer: _fertilizerName,
                uniqueFertilizerIdentifier: _uniqueFertilizerInfo
            });
            fertilizerInfo.push(_fertilizerInfo);

            listOfAllConignmentsReceived.push(_consignment);

            emit ConsignmentReceivedFromManufacturer(
                _consignmentId,
                _fertilizerId,
                _fertilizerQuantity,
                _fertilizerSubsidisedPrice
            );
        } else {
            revert InvalidFertilizerId();
        }

        return true;
    }

    function sellFertilizerToRetailer(
        string memory _nameOfFertilizer,
        uint256 _fertilizerPrice,
        uint256 _fertilizerQuantity
    ) public returns (bool) {
        uint256 _fertilizerId = getFertilizerIdByName(_nameOfFertilizer);
        require(
            _fertilizerId != type(uint256).max,
            "The particular fertilizer is not in inventory"
        );

        require(
            _fertilizerPrice == fertilizerIdToSubsidisedPrice[_fertilizerId],
            "the price given is incorrect"
        );
        require(
            _fertilizerQuantity <= fertilizerIdToQuantity[_fertilizerId],
            "not enought quantity to sell"
        );

        fertilizerIdToQuantity[_fertilizerId] -= _fertilizerQuantity;

        FertilizerSold memory _fertilizerSold = FertilizerSold({
            nameOfFertilizer: _nameOfFertilizer,
            fertilizerPrice: _fertilizerPrice,
            fertilizerQuantity: _fertilizerQuantity
        });
        fertilizerSold.push(_fertilizerSold);

        emit FertilizerSoldToRetailer(_nameOfFertilizer, _fertilizerQuantity);

        return true;
    }

    function getAddressOfManufacturer() public view returns (address) {
        address _addressOfManufacturer = manufacturer.addressOfManufacturer();
        return _addressOfManufacturer;
    }

    function getNameOfManufacturer() public view returns (string memory) {
        string memory _nameOfManufacturer = manufacturer.nameOfManufacturer();
        return _nameOfManufacturer;
    }

    /////////////////
    // GETTERS //////
    /////////////////

    function numberOfFertilizers() public view returns (uint256) {
        return listOfFertilizerId.length;
    }

    function getTotalQuantityInWarehouse() public view returns (uint256) {
        return totalQuantity;
    }

    function getMaximumCapacity() public pure returns (uint256) {
        return MAX_QUANTITY;
    }

    function getQuantityOfFertilizerId(
        uint256 _fertilizerId
    ) public view returns (uint256) {
        return fertilizerIdToQuantity[_fertilizerId];
    }

    function getSubsidisedPriceOfFertilizerId(
        uint256 _fertilizerId
    ) public view returns (uint256) {
        return fertilizerIdToSubsidisedPrice[_fertilizerId];
    }

    function getConsignmentInformation(
        uint256 _consignmentId
    ) public view returns (Manufacturer.Consignment memory) {
        return listOfAllConignmentsReceived[_consignmentId];
    }

    function getFertilizerIdByName(
        string memory _fertilizerName
    ) public view returns (uint256 idFound) {
        uint256 _uniqueFertilizerIdentifier = uint256(
            keccak256(bytes(_fertilizerName))
        );
        bool fertilizerIdFound = false;
        for (uint256 i = 0; i < fertilizerInfo.length; i++) {
            if (
                fertilizerInfo[i].uniqueFertilizerIdentifier ==
                _uniqueFertilizerIdentifier
            ) {
                fertilizerIdFound = true;
                return fertilizerInfo[i].fertilizerId;
            }
        }
        if (fertilizerIdFound == false) {
            return type(uint256).max;
        }
    }
}
