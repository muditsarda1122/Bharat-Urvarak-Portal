// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract DepartmentOfAgriculture {
    struct Manufacturer {
        uint256 manufacturerId;
        string manufacturerName;
        uint256 uniqueManufacturerIdentifier;
    }
    Manufacturer[] public listOfAllManufacturers;

    struct B2Certificate {
        uint256 certificateId;
        uint256 manufacturerId;
        uint256 fertilizerId;
        bool B2Certified;
    }
    B2Certificate[] public listOfAllB2Certificates;

    struct B1Certificate {
        uint256 certificateId;
        uint256 manufacturerId;
        uint256 consignmentId;
        uint256 quantity;
        bool B1Certified;
    }
    B1Certificate[] public listOfAllB1Certificates;

    mapping(uint256 manufacturerId => mapping(uint256 consignmentId => bool isB1Certified)) ManufacturersToB1Certifications;
    mapping(uint256 manufacturerId => mapping(uint256 fertilizerId => bool isB2Certified)) ManufacturersToB2Certifications;

    address immutable owner;

    event NewManufacturerAdded(uint256 manufacturerId);
    event B2CertificateGiven(string manufacturerName, uint256 fertilizerId);
    event B1CertificateGiven(
        string manufacturerName,
        uint256 fertilizerId,
        uint256 consignmentId,
        uint256 quantity
    );

    error manufacturerAlreadyAdded();
    error ManufacturerNotFound();

    modifier onlyOwner() {
        require(msg.sender == owner, "can be called only by DOA owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerNewManufacturer(
        string memory _name
    ) internal onlyOwner returns (uint256 manufacturerId) {
        uint256 _numberOfManufacturers = numberOfManufacturers();

        uint256 _checkUniqueManufacturerIdentifier = uint256(
            keccak256(bytes(_name))
        );
        for (uint256 i = 0; i < _numberOfManufacturers; i++) {
            if (
                listOfAllManufacturers[i].uniqueManufacturerIdentifier ==
                _checkUniqueManufacturerIdentifier
            ) {
                revert manufacturerAlreadyAdded();
            }
        }

        Manufacturer memory _newManufacturer = Manufacturer({
            manufacturerId: _numberOfManufacturers,
            manufacturerName: _name,
            uniqueManufacturerIdentifier: _checkUniqueManufacturerIdentifier
        });
        listOfAllManufacturers.push(_newManufacturer);

        emit NewManufacturerAdded(_newManufacturer.manufacturerId);

        return _newManufacturer.manufacturerId;
    }

    function giveB2Certificate(
        string memory _manufacturerName,
        uint256 fertilizerId
    ) public returns (bool) {
        uint256 _checkUniqueManufacturerIdentifier = uint256(
            keccak256(bytes(_manufacturerName))
        );
        uint256 _numberOfManufacturers = numberOfManufacturers();
        bool uniqueManufacturerIdFound = false;
        for (uint256 i = 0; i < _numberOfManufacturers; i++) {
            if (
                listOfAllManufacturers[i].uniqueManufacturerIdentifier ==
                _checkUniqueManufacturerIdentifier
            ) {
                uint256 _certificateId = listOfAllB2Certificates.length;

                B2Certificate memory _B2Certificate = B2Certificate({
                    certificateId: _certificateId,
                    manufacturerId: i,
                    fertilizerId: fertilizerId,
                    B2Certified: true
                });

                listOfAllB2Certificates.push(_B2Certificate);

                ManufacturersToB2Certifications[i][fertilizerId] = true;

                emit B2CertificateGiven(_manufacturerName, fertilizerId);

                uniqueManufacturerIdFound = true;
            }
        }

        if (uniqueManufacturerIdFound == false) {
            uint256 _manufacturerId = registerNewManufacturer(
                _manufacturerName
            );
            uint256 _certificateId = listOfAllB2Certificates.length;
            B2Certificate memory _B2Certificate = B2Certificate({
                certificateId: _certificateId,
                manufacturerId: _manufacturerId,
                fertilizerId: fertilizerId,
                B2Certified: true
            });

            listOfAllB2Certificates.push(_B2Certificate);

            ManufacturersToB2Certifications[_manufacturerId][
                fertilizerId
            ] = true;

            emit B2CertificateGiven(_manufacturerName, fertilizerId);
        }

        return true;
    }

    function giveB1Certificate(
        string memory _manufacturerName,
        uint256 _fertilizerId,
        uint256 _consignmentId,
        uint256 _quantity
    ) public returns (bool) {
        uint256 _checkUniqueManufacturerIdentifier = uint256(
            keccak256(bytes(_manufacturerName))
        );
        uint256 _numberOfManufacturers = numberOfManufacturers();

        bool uniqueIdentifierFound = false;
        for (uint256 i = 0; i < _numberOfManufacturers; i++) {
            if (
                listOfAllManufacturers[i].uniqueManufacturerIdentifier ==
                _checkUniqueManufacturerIdentifier
            ) {
                uint256 _certificateId = listOfAllB1Certificates.length;

                B1Certificate memory _B1Certificate = B1Certificate({
                    certificateId: _certificateId,
                    manufacturerId: i,
                    consignmentId: _consignmentId,
                    quantity: _quantity,
                    B1Certified: true
                });

                listOfAllB1Certificates.push(_B1Certificate);

                ManufacturersToB1Certifications[i][_consignmentId] = true;

                emit B1CertificateGiven(
                    _manufacturerName,
                    _fertilizerId,
                    _consignmentId,
                    _quantity
                );

                uniqueIdentifierFound = true;
            }
        }

        if (uniqueIdentifierFound == false) {
            uint256 _manufacturerId = registerNewManufacturer(
                _manufacturerName
            );
            uint256 _certificateId = listOfAllB1Certificates.length;
            B1Certificate memory _B1Certificate = B1Certificate({
                certificateId: _certificateId,
                manufacturerId: _manufacturerId,
                consignmentId: _consignmentId,
                quantity: _quantity,
                B1Certified: true
            });

            listOfAllB1Certificates.push(_B1Certificate);

            ManufacturersToB1Certifications[_manufacturerId][
                _consignmentId
            ] = true;

            emit B1CertificateGiven(
                _manufacturerName,
                _fertilizerId,
                _consignmentId,
                _quantity
            );
        }

        return true;
    }

    /////////////////
    // GETTERS //////
    /////////////////

    function numberOfManufacturers() public view returns (uint256) {
        return listOfAllManufacturers.length;
    }

    function getManufacturerIdByManufacturerName(
        string memory _manufacturerName
    ) private view returns (uint256 manufacturerId) {
        uint256 _uniqueManufacturerIdentifier = uint256(
            keccak256(bytes(_manufacturerName))
        );

        for (uint256 i = 0; i < listOfAllManufacturers.length; i++) {
            if (
                listOfAllManufacturers[i].uniqueManufacturerIdentifier ==
                _uniqueManufacturerIdentifier
            ) {
                return listOfAllManufacturers[i].manufacturerId;
            }
        }

        revert ManufacturerNotFound();
    }

    function getB2CertificateInfoByCertificateId(
        uint256 _certificateId
    ) private view returns (B2Certificate memory) {
        require(
            _certificateId < listOfAllB2Certificates.length,
            "Invalid certificateID entered"
        );
        B2Certificate memory _B2Certificate = listOfAllB2Certificates[
            _certificateId
        ];
        return _B2Certificate;
    }

    function getB1CertificateInfoByCertificateId(
        uint256 _certificateId
    ) private view returns (B1Certificate memory) {
        require(
            _certificateId < listOfAllB1Certificates.length,
            "Invalid certificateID entered"
        );
        B1Certificate memory _B1Certificate = listOfAllB1Certificates[
            _certificateId
        ];
        return _B1Certificate;
    }

    function checkIfFertilizerIsB2Certified(
        uint256 _manufacturerId,
        uint256 _fertilizerId
    ) private view returns (bool) {
        require(
            _manufacturerId < listOfAllManufacturers.length,
            "Incorrect manufacturerID entered"
        );
        return ManufacturersToB2Certifications[_manufacturerId][_fertilizerId];
    }

    function checkIfConsignmentIsB1Certified(
        uint256 _manufacturerId,
        uint256 _consignmentId
    ) private view returns (bool) {
        require(
            _manufacturerId < listOfAllManufacturers.length,
            "Incorrect manufacturerID entered"
        );
        return ManufacturersToB1Certifications[_manufacturerId][_consignmentId];
    }
}
