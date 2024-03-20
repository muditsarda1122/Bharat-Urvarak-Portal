//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {DepartmentOfAgriculture} from "./DepartmentOfAgriculture.sol";
import {Warehouse} from "./Warehouse.sol";
import {DepartmentOfFertilizer} from "./DepartmentOfFertilizer.sol";

contract Manufacturer {
    DepartmentOfAgriculture departmentOfAgriculture;
    Warehouse warehouse;
    DepartmentOfFertilizer departmentOfFertilizer;

    struct ManufacturerInfo {
        string manufacturerName;
        uint256 uniqueManufacturerIdentifier;
        uint256[] fertilizerIds;
    }
    ManufacturerInfo public manufacturerInfo;

    struct Fertilizers {
        uint256 fertilizerId;
        string fertilizerName;
        uint256 uniqueFertilizerIdentifier;
        uint256 fertlizerManufacturingPrice;
        uint256 fertilizerSubsidisedRate;
        bool isB2Certified;
    }
    Fertilizers[] public listOfFertilizers;

    struct Consignment {
        uint256 consignmentId;
        uint256 fertilizerId;
        uint256 fertilizerQuantity;
    }
    Consignment[] public listOfConignmentsSentToDOA;
    Consignment[] public listOfAllConsignmentsSentToWarehouse;

    struct ProductsSold {
        string nameOfFerilizer;
        uint256 fertilizerQuantity;
        uint256 fertilizerPrice;
        uint256 fertilizerManufacturingPrice;
    }
    ProductsSold[] public infoOfAllProductsSold;
    ProductsSold[] public listOfProductsSoldToBeSentToDOF;

    mapping(uint256 consignmentId => bool isB1Certified) B1Certifications;

    address immutable owner;

    event FertilizerAdded(string name);
    event FertilizerRemoved(string name);
    event ManufacturingPriceUpdated(uint256 oldPrice, uint256 newPrice);
    event B2CertificateAcquired(uint fertilizerId);
    event B1CertificateAcquired(
        uint fertilizerId,
        uint256 quantity,
        uint consignmentId
    );
    event PaymentReceivedFromRetailer(address sender, uint256 value);
    event ProductSoldInfoAdded(
        string fertilizerName,
        uint256 fertilizerQuantity,
        uint256 fertilizerPrice
    );

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Can be called only by the owner(manufacturer)"
        );
        _;
    }

    // the manufacturer needs to add 1 product in constructor
    constructor(string memory _manufacturerName) {
        owner = msg.sender;
        manufacturerInfo.manufacturerName = _manufacturerName;
        uint256 _uniqueManufacturerIdentifier = uint256(
            keccak256(bytes(_manufacturerName))
        );
        manufacturerInfo
            .uniqueManufacturerIdentifier = _uniqueManufacturerIdentifier;
        manufacturerInfo.fertilizerIds = new uint256[](0);
    }

    function addProduct(
        string memory _fertilizerName,
        uint256 _fertilizerManufacturingPrice,
        uint256 _fertilizerSubsidisedRate
    ) internal onlyOwner {
        require(_fertilizerManufacturingPrice != 0, "Price can not be zero");
        require(
            _fertilizerSubsidisedRate < _fertilizerManufacturingPrice,
            "subsidised rate can not be greater than manufacturing price"
        );
        uint256 _fertilizerId = numberOfProducts();
        manufacturerInfo.fertilizerIds.push(_fertilizerId);

        uint256 _uniqueFertilizerIdentifier = uint256(
            keccak256(bytes(_fertilizerName))
        );

        Fertilizers memory _fertilizer = Fertilizers({
            fertilizerId: _fertilizerId,
            fertilizerName: _fertilizerName,
            uniqueFertilizerIdentifier: _uniqueFertilizerIdentifier,
            fertlizerManufacturingPrice: _fertilizerManufacturingPrice,
            fertilizerSubsidisedRate: _fertilizerSubsidisedRate,
            isB2Certified: false
        });
        listOfFertilizers.push(_fertilizer);

        emit FertilizerAdded(_fertilizerName);
    }

    function removeProduct(uint256 _fertilizerId) internal onlyOwner {
        require(_fertilizerId < numberOfProducts(), "Invalid fertilizerId");

        Fertilizers memory _fertilizerToBeRemoved = listOfFertilizers[
            _fertilizerId
        ];
        emit FertilizerRemoved(_fertilizerToBeRemoved.fertilizerName);
        require(
            _fertilizerToBeRemoved.fertlizerManufacturingPrice != 0 ||
                _fertilizerToBeRemoved.fertilizerSubsidisedRate != 0,
            "Fertilizer already removed"
        );

        _fertilizerToBeRemoved.fertilizerName = "";
        _fertilizerToBeRemoved.fertilizerSubsidisedRate = 0;
        _fertilizerToBeRemoved.fertlizerManufacturingPrice = 0;
        _fertilizerToBeRemoved.isB2Certified = false;
    }

    // function changePriceOfProduct(
    //     uint256 _fertilizerId,
    //     uint256 _newPrice
    // ) internal onlyOwner {
    //     require(_fertilizerId < numberOfProducts(), "Invalid fertilizerId");

    //     Fertilizers memory _fertilizerToBeUpdated = listOfFertilizers[
    //         _fertilizerId
    //     ];
    //     require(
    //         _fertilizerToBeUpdated.fertlizerManufacturingPrice != 0 ||
    //             _fertilizerToBeUpdated.fertilizerSubsidisedRate != 0,
    //         "Fertilizer already removed"
    //     );

    //     uint256 oldPrice = _fertilizerToBeUpdated.fertlizerManufacturingPrice;

    //     _fertilizerToBeUpdated.fertlizerManufacturingPrice = _newPrice;

    //     emit ManufacturingPriceUpdated(oldPrice, _newPrice);
    // }

    //send fertilizer for B2 certification
    function sendFertilizerForB2Certification(
        uint256 _fertilizerId
    ) private onlyOwner returns (bool) {
        require(_fertilizerId < numberOfProducts(), "Invalid productID");
        require(
            listOfFertilizers[_fertilizerId].isB2Certified == false,
            "The product has already been B2 certified"
        );

        Fertilizers
            memory fertilizerToBeSentForB2Certification = listOfFertilizers[
                _fertilizerId
            ];
        require(
            fertilizerToBeSentForB2Certification.fertlizerManufacturingPrice !=
                0 ||
                fertilizerToBeSentForB2Certification.fertilizerSubsidisedRate !=
                0,
            "The fertilizer has been removed"
        );

        bool success = departmentOfAgriculture.giveB2Certificate(
            manufacturerInfo.manufacturerName,
            _fertilizerId
        );
        require(success, "B2 certificate could not be attained");

        emit B2CertificateAcquired(_fertilizerId);

        return true;
    }

    //send fertilizer for B1 certification
    function sendFertilizerForB1Certification(
        uint256 _fertilizerId,
        uint256 quantity,
        uint256 consignmentId
    ) private onlyOwner returns (bool) {
        require(_fertilizerId < numberOfProducts(), "Invalid productID");
        Fertilizers
            memory fertilizerToBeSentForB1Certification = listOfFertilizers[
                _fertilizerId
            ];
        require(
            fertilizerToBeSentForB1Certification.fertlizerManufacturingPrice !=
                0 ||
                fertilizerToBeSentForB1Certification.fertilizerSubsidisedRate !=
                0,
            "The fertilizer has been removed"
        );

        bool success = departmentOfAgriculture.giveB1Certificate(
            manufacturerInfo.manufacturerName,
            _fertilizerId,
            consignmentId,
            quantity
        );
        require(
            success,
            "B1 certificate could not be attained for the consignment"
        );

        Consignment memory _consignment = Consignment({
            consignmentId: consignmentId,
            fertilizerId: _fertilizerId,
            fertilizerQuantity: quantity
        });
        listOfConignmentsSentToDOA.push(_consignment);

        B1Certifications[consignmentId] = true;

        emit B1CertificateAcquired(_fertilizerId, quantity, consignmentId);

        return true;
    }

    function sendConsignmentToWarehouse(
        uint256 _consignmentId,
        uint256 _fertilizerId,
        string memory _fertilizerName,
        uint256 _fertilizerQuantity,
        uint256 _fertilizerSubsidisedPrice
    ) private onlyOwner returns (bool) {
        require(_fertilizerId < numberOfProducts(), "Invalid productID");
        require(
            _consignmentId == listOfAllConsignmentsSentToWarehouse.length,
            "Invalid consignmentId"
        );
        require(
            _fertilizerQuantity != 0,
            "fertilizer quantity can not be zero"
        );
        require(
            _fertilizerSubsidisedPrice != 0,
            "fertilizer subsidised price can not be zero"
        );

        require(
            checkIfFertilizerIsB2Certified(_fertilizerId),
            "The fertilizer is not B2 certified"
        );
        require(
            checkIfB1Certified(_consignmentId),
            "The consignment is not B1 certified"
        );
        require(
            listOfFertilizers[_fertilizerId].fertlizerManufacturingPrice != 0,
            "This fertilizer has been removed"
        );
        require(
            listOfFertilizers[_fertilizerId].fertilizerSubsidisedRate ==
                _fertilizerSubsidisedPrice,
            "subsidised price is incorrect"
        );

        Consignment memory _consignemnt = Consignment({
            consignmentId: _consignmentId,
            fertilizerId: _fertilizerId,
            fertilizerQuantity: _fertilizerQuantity
        });
        listOfAllConsignmentsSentToWarehouse.push(_consignemnt);

        bool success = warehouse.receiveConsignmentFromManufacturer(
            _consignemnt,
            _fertilizerName,
            _fertilizerSubsidisedPrice
        );
        require(success, "Consignment could not be sent to warehouse");

        return true;
    }

    function receiveInfoAboutSoldProductFromRetailer(
        string memory _fertilizerName,
        uint256 _fertilizerQuantity,
        uint256 _fertilizerPrice
    ) public returns (bool) {
        uint256 _uniqueFertilizerIdentifier = uint256(
            keccak256(bytes(_fertilizerName))
        );
        uint256 _fertilizerManufacturerPrice = 0;
        for (uint256 i = 0; i < listOfFertilizers.length; i++) {
            if (
                listOfFertilizers[i].uniqueFertilizerIdentifier ==
                _uniqueFertilizerIdentifier
            ) {
                _fertilizerManufacturerPrice = listOfFertilizers[i]
                    .fertlizerManufacturingPrice;
            }
        }

        ProductsSold memory productSold = ProductsSold({
            nameOfFerilizer: _fertilizerName,
            fertilizerQuantity: _fertilizerQuantity,
            fertilizerPrice: _fertilizerPrice,
            fertilizerManufacturingPrice: _fertilizerManufacturerPrice
        });
        infoOfAllProductsSold.push(productSold);
        listOfProductsSoldToBeSentToDOF.push(productSold);

        emit ProductSoldInfoAdded(
            _fertilizerName,
            _fertilizerQuantity,
            _fertilizerPrice
        );

        return true;
    }

    function sendInvoicesToDOF() internal onlyOwner {
        require(
            listOfProductsSoldToBeSentToDOF.length >= 100,
            "You can not send invoices for claim to Department of Fertilizers as you have less than 100 invoices"
        );

        departmentOfFertilizer.claimPayment(
            manufacturerInfo.manufacturerName,
            listOfProductsSoldToBeSentToDOF
        );

        for (uint256 i = 0; i < listOfProductsSoldToBeSentToDOF.length; i++) {
            listOfProductsSoldToBeSentToDOF.pop();
        }
        require(listOfProductsSoldToBeSentToDOF.length == 0);
    }

    receive() external payable {
        emit PaymentReceivedFromRetailer(msg.sender, msg.value);
    }

    ///////////////////////
    // GETTERS ////////////
    ///////////////////////

    function numberOfProducts() private view returns (uint256) {
        return manufacturerInfo.fertilizerIds.length;
    }

    function numberOfConsignments() private view returns (uint256) {
        return listOfAllConsignmentsSentToWarehouse.length;
    }

    function getFertilizerById(
        uint256 _fertilizerId
    ) private view returns (Fertilizers memory) {
        require(
            _fertilizerId < listOfFertilizers.length,
            "Invalid fertilizerID entered"
        );
        Fertilizers memory _fertilizer = listOfFertilizers[_fertilizerId];
        return _fertilizer;
    }

    function getConsignmentById(
        uint256 _consignmentId
    ) private view onlyOwner returns (Consignment memory) {
        require(
            _consignmentId < listOfConignmentsSentToDOA.length,
            "Invalid consignmentID entered"
        );
        Consignment memory _consignment = listOfConignmentsSentToDOA[
            _consignmentId
        ];
        return _consignment;
    }

    function checkIfB1Certified(
        uint256 _consignmentId
    ) private view onlyOwner returns (bool) {
        require(
            _consignmentId < listOfConignmentsSentToDOA.length,
            "Invalid consignmentID entered"
        );
        return B1Certifications[_consignmentId];
    }

    function checkIfFertilizerIsB2Certified(
        uint256 _fertilizerId
    ) private view onlyOwner returns (bool) {
        require(
            _fertilizerId < listOfFertilizers.length,
            "Invalid fertilizerID entered"
        );
        Fertilizers memory _fertilizer = listOfFertilizers[_fertilizerId];
        return _fertilizer.isB2Certified;
    }

    function addressOfManufacturer() public view returns (address) {
        return address(owner);
    }

    function nameOfManufacturer() public view returns (string memory) {
        return manufacturerInfo.manufacturerName;
    }
}
