//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Warehouse} from "./Warehouse.sol";
import {Manufacturer} from "./Manufacturer.sol";

contract Retailer {
    Warehouse warehouse;
    Manufacturer manufacturer;

    struct _Manufacturer {
        uint256 manufacturerId;
        string manufacturerName;
        uint256 uniqueManufacturerIdentifier;
        address manufacturerAddress;
    }
    _Manufacturer[] public listOfManufacturers;

    struct fertilizerInfo {
        string fertilizerName;
        uint256 fertilizerId;
        uint256 fertilizerPrice;
        uint256 fertilizerQuantity;
    }

    struct Invoice {
        uint256 manufacturerId;
        string fertilizerName;
        uint256 fertilizerQuantity;
        uint256 fertilizerPrice;
    }
    Invoice[] public invoices;

    mapping(uint256 manufacturerId => uint256[] fertilizerIds) manufacturerIdToFertilizerIds;
    mapping(uint256 manufacturerId => mapping(uint256 fertilizerId => fertilizerInfo)) manufacturerIdToFertilizerInfo;
    mapping(address warehouseAddress => address manufacturerAddress) warehouseAddressToManufacturerAddress;

    address immutable owner;
    string nameOfRetailer;

    event FertilizerQuantityUpdated(
        string nameOfFertilizer,
        uint256 oldQuantity,
        uint256 newQuantity
    );
    event NewFertilizerAddedToExistingManufacturer(
        string nameOfManufacturer,
        string nameOfFertilizer,
        uint256 priceOfFertilizer,
        uint256 quantityOfFertilizer
    );
    event NewManufacturerAndFertilizerDetailsAdded(
        string nameOfManufacturer,
        uint256 manufacturerId,
        string nameOfFertilizer,
        uint256 priceOfFertilizer,
        uint256 quantityOfFertilizer
    );
    event PaymentReceivedFromFarmer(address sender, uint256 value);
    event FertilizerSoldToFarmer(
        // string nameOfManufacturer,
        string nameOfFertilizer,
        uint256 fertilizerQuantity,
        uint256 FertilizerPrice
    );

    error ManufacturerNotFound();
    error FertilizerNotFound();

    modifier onlyOwner() {
        require(msg.sender == owner, "can only be called by the owner");
        _;
    }

    constructor(string memory _name) {
        owner = msg.sender;
        nameOfRetailer = _name;
    }

    // buy fertilizers from warehouse and pay to manufacturer
    function buyFertilizerFromWarehouse(
        string memory _nameOfManufacturer,
        string memory _nameOfFertilizer,
        uint256 _fertilizerId,
        uint256 _fertilizerPrice,
        uint256 _fertilizerQuantity,
        address _warehouseAddress
    ) internal onlyOwner returns (bool) {
        require(_fertilizerPrice != 0, "Fertilizer price can not be zero");
        require(
            _fertilizerQuantity != 0,
            "Fertilizer quantity can not be zero"
        );

        bool success = Warehouse(_warehouseAddress).sellFertilizerToRetailer(
            _nameOfFertilizer,
            _fertilizerPrice,
            _fertilizerQuantity
        );
        require(
            success,
            "fertilizer could not successfully be bought from warehouse"
        );

        uint256 _uniqueManufacturerIdentifier = uint256(
            keccak256(bytes(_nameOfManufacturer))
        );

        bool _manufacturerFound = false;
        for (uint256 i = 0; i < listOfManufacturers.length; i++) {
            // case1: the manufacturer is already registered in listOfManufacturers
            if (
                listOfManufacturers[i].uniqueManufacturerIdentifier ==
                _uniqueManufacturerIdentifier
            ) {
                _manufacturerFound = true;

                uint256 _manufacturerId = listOfManufacturers[i].manufacturerId;
                uint256[] memory _ferilizerIds = manufacturerIdToFertilizerIds[
                    _manufacturerId
                ];

                bool _fertilizerFound = false;
                for (uint256 j = 0; j < _ferilizerIds.length; j++) {
                    // case1 a: the fertilizer is also registered so we shall only increase the quantity
                    if (_ferilizerIds[j] == _fertilizerId) {
                        fertilizerInfo
                            memory _fertilizerInfo = manufacturerIdToFertilizerInfo[
                                i
                            ][j];
                        uint256 _oldQuantity = _fertilizerInfo
                            .fertilizerQuantity;
                        uint256 _newQuantity = _oldQuantity +
                            _fertilizerQuantity;

                        _fertilizerInfo.fertilizerQuantity = _newQuantity;

                        _fertilizerFound = true;

                        emit FertilizerQuantityUpdated(
                            _nameOfFertilizer,
                            _oldQuantity,
                            _newQuantity
                        );
                    }
                }

                // case1 b: the fertilizer is NOT registered so we need to create fertilizerInfo struct, push in listOfManufacturers,
                //          update manufacturerIdToFertilizerIds and manufacturerIdToFertilizerInfo
                if (_fertilizerFound == false) {
                    uint256 _numberOfFertilizers = _ferilizerIds.length;

                    _ferilizerIds[_numberOfFertilizers] = _fertilizerId;
                    fertilizerInfo memory _fertilizerInfo = fertilizerInfo({
                        fertilizerName: _nameOfFertilizer,
                        fertilizerId: _fertilizerId,
                        fertilizerPrice: _fertilizerPrice,
                        fertilizerQuantity: _fertilizerQuantity
                    });
                    manufacturerIdToFertilizerInfo[i][
                        _fertilizerId
                    ] = _fertilizerInfo;

                    emit NewFertilizerAddedToExistingManufacturer(
                        _nameOfManufacturer,
                        _nameOfFertilizer,
                        _fertilizerPrice,
                        _fertilizerQuantity
                    );
                }
            }
        }
        // case 2: the manufacturer is NOT registered in listOfManufacturers. We need to update listOfManufacturers, create
        //         fertilizerInfo struct, update manufacturerIdToFertilizerIds, manufacturerIdToFertilizerInfo and manufacturerAddressToRetailerAddress
        if (_manufacturerFound == false) {
            uint256 _manufacturerId = listOfManufacturers.length;
            address _manufacturerAddress = Warehouse(_warehouseAddress)
                .getAddressOfManufacturer();

            _Manufacturer memory _manufacturer = _Manufacturer({
                manufacturerId: _manufacturerId,
                manufacturerName: _nameOfManufacturer,
                uniqueManufacturerIdentifier: _uniqueManufacturerIdentifier,
                manufacturerAddress: _manufacturerAddress
            });
            listOfManufacturers.push(_manufacturer);

            uint256[] memory _fertilizerIds;
            _fertilizerIds[0] = _fertilizerId;

            manufacturerIdToFertilizerIds[_manufacturerId] = _fertilizerIds;

            fertilizerInfo memory _fertilizerInfo = fertilizerInfo({
                fertilizerName: _nameOfFertilizer,
                fertilizerId: _fertilizerId,
                fertilizerPrice: _fertilizerPrice,
                fertilizerQuantity: _fertilizerQuantity
            });
            manufacturerIdToFertilizerInfo[_manufacturerId][
                _fertilizerId
            ] = _fertilizerInfo;

            warehouseAddressToManufacturerAddress[
                _warehouseAddress
            ] = _warehouseAddress;

            emit NewManufacturerAndFertilizerDetailsAdded(
                _nameOfManufacturer,
                _manufacturerId,
                _nameOfFertilizer,
                _fertilizerPrice,
                _fertilizerQuantity
            );
        }

        address receiver = Warehouse(_warehouseAddress)
            .getAddressOfManufacturer();
        uint256 costToBePaid = _fertilizerPrice * _fertilizerQuantity;
        (bool _success, ) = receiver.call{value: costToBePaid}("");
        require(_success, "Payment failed");

        return true;
    }

    // sell fertilizer to farmer
    function sellFertilizerToFarmer(
        string memory _nameOfManufacturer,
        string memory _fertilizerName,
        uint256 _fertilizerQuantity,
        uint256 _fertilizerPrice
    ) public returns (bool _fertilizerFound) {
        // from nameOfManufacturer --> manufacturerId --> [] fertilizerIds --traverse it--> find fertilizerInfo of each fertilizer and put check on quantity

        uint256 _uniqueManufacturerIdentifier = uint256(
            keccak256(bytes(_nameOfManufacturer))
        );
        uint256 _uniqueFertilizerIdentifier = uint256(
            keccak256(bytes(_fertilizerName))
        );

        uint256 _manufacturerID;
        // address _manufacturerAddress;
        // bool manufacturerFound = false;
        for (uint256 i = 0; i < listOfManufacturers.length; i++) {
            if (
                listOfManufacturers[i].uniqueManufacturerIdentifier ==
                _uniqueManufacturerIdentifier
            ) {
                _manufacturerID = listOfManufacturers[i].manufacturerId;
                // _manufacturerAddress = listOfManufacturers[i]
                //     .manufacturerAddress;
                // manufacturerFound = true;
            }

            if (i == listOfManufacturers.length - 1) {
                revert ManufacturerNotFound();
            }
        }
        // if (manufacturerFound == false) {
        //     revert ManufacturerNotFound();
        // }

        uint256[]
            memory listOfFertilizerIdsOfTheManufacturer = manufacturerIdToFertilizerIds[
                _manufacturerID
            ];

        bool fertilizerFound = false;
        for (
            uint256 j = 0;
            j < listOfFertilizerIdsOfTheManufacturer.length;
            j++
        ) {
            fertilizerInfo
                memory _fertilizerInfo = manufacturerIdToFertilizerInfo[
                    _manufacturerID
                ][j];
            uint256 _fertilizerIdentifier = uint256(
                keccak256(bytes(_fertilizerInfo.fertilizerName))
            );

            if (_fertilizerIdentifier == _uniqueFertilizerIdentifier) {
                require(
                    _fertilizerInfo.fertilizerPrice == _fertilizerPrice,
                    "The price of fertilizer is incorrect"
                );
                require(
                    _fertilizerQuantity <= _fertilizerInfo.fertilizerQuantity,
                    "Not enough quantity to be sold"
                );

                // uint256 oldQuantity = _fertilizerInfo.fertilizerQuantity;
                // uint256 newQuantity = oldQuantity - _fertilizerQuantity;

                _fertilizerInfo.fertilizerQuantity -= _fertilizerQuantity;

                fertilizerFound = true;

                Invoice memory invoice = Invoice({
                    manufacturerId: _manufacturerID,
                    fertilizerName: _fertilizerName,
                    fertilizerQuantity: _fertilizerQuantity,
                    fertilizerPrice: _fertilizerPrice
                });

                // call sendInfoOfSoldFertilizerToManufacturer
                sendInfoOfSoldFertilizerToManufacturer(invoice);
                invoices.push(invoice);

                // uint256 _amountToBePaidToManufacturer = _fertilizerQuantity *
                //     _fertilizerPrice;
                (bool success, ) = listOfManufacturers[_manufacturerID]
                    .manufacturerAddress
                    .call{value: _fertilizerQuantity * _fertilizerPrice}("");
                require(success, "Payment could not be made to manufacturer");

                // using _nameOfManufacturer here results in stack too deep, hence removed.
                emit FertilizerSoldToFarmer(
                    // _nameOfManufacturer,
                    _fertilizerName,
                    _fertilizerQuantity,
                    _fertilizerPrice
                );
                return true;
            }
        }
        if (fertilizerFound == false) {
            return false;
        }
    }

    function sendInfoOfSoldFertilizerToManufacturer(
        Invoice memory _invoice
    ) internal {
        uint256 _manufacturerId = _invoice.manufacturerId;
        string memory _fertilizerName = _invoice.fertilizerName;
        uint256 _fertilizerQuantity = _invoice.fertilizerQuantity;
        uint256 _fertilizerPrice = _invoice.fertilizerPrice;
        address _manufacturerAddress = listOfManufacturers[_manufacturerId]
            .manufacturerAddress;

        bool success = Manufacturer(payable(_manufacturerAddress))
            .receiveInfoAboutSoldProductFromRetailer(
                _fertilizerName,
                _fertilizerQuantity,
                _fertilizerPrice
            );
        require(success, "fertilizer info could not be sent to manufacturer");
    }

    receive() external payable {
        emit PaymentReceivedFromFarmer(msg.sender, msg.value);
    }

    /////////////////
    // GETTERS //////
    /////////////////
    function getAddressOfRetailer() public view returns (address) {
        return address(this);
    }

    function getNameOfRetailer() public view returns (string memory) {
        return nameOfRetailer;
    }

    function getManufacturerInformationUsingManufacturerName(
        string memory _manufacturerName
    ) public view returns (_Manufacturer memory _manufacturer) {
        uint256 _uniqueManufacturerIdentifier = uint256(
            keccak256(bytes(_manufacturerName))
        );
        for (uint256 i = 0; i < listOfManufacturers.length; i++) {
            if (
                listOfManufacturers[i].uniqueManufacturerIdentifier ==
                _uniqueManufacturerIdentifier
            ) {
                return _manufacturer = listOfManufacturers[i];
            }

            if (i == listOfManufacturers.length - 1) {
                revert ManufacturerNotFound();
            }
        }
    }

    function getManufacturerAddressUsingWarehouseAddress(
        address _warehouseAddress
    ) public view returns (address) {
        require(
            _warehouseAddress != address(0),
            "warehouse address can not be zero address"
        );
        return warehouseAddressToManufacturerAddress[_warehouseAddress];
    }

    function getListOfFertilizerIdsUsingManufacturerId(
        uint256 _manufacturerId
    ) public view returns (uint256[] memory) {
        require(
            _manufacturerId < listOfManufacturers.length,
            "incorrect manufacturer ID"
        );
        return manufacturerIdToFertilizerIds[_manufacturerId];
    }

    function getFertilizerInfoUsingManufacturerIdAndFertilizerId(
        uint256 _manufacturerId,
        uint256 _fertilizerId
    ) public view returns (fertilizerInfo memory _fertilizerInfo) {
        require(
            _manufacturerId < listOfManufacturers.length,
            "incorrect manufacturer ID"
        );

        uint256[]
            memory _listOfAllFertilizerIds = manufacturerIdToFertilizerIds[
                _manufacturerId
            ];

        for (uint256 i = 0; i < _listOfAllFertilizerIds.length; i++) {
            if (_listOfAllFertilizerIds[i] == _fertilizerId) {
                return
                    _fertilizerInfo = manufacturerIdToFertilizerInfo[
                        _manufacturerId
                    ][i];
            }

            if (i == _listOfAllFertilizerIds.length - 1) {
                revert FertilizerNotFound();
            }
        }
    }

    function getAllInvoices() public view returns (Invoice[] memory) {
        return invoices;
    }
}
