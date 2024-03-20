//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Manufacturer} from "./Manufacturer.sol";

contract DepartmentOfFertilizer {
    Manufacturer manufacturer;

    struct ManufacturerInformation {
        uint256 manufacturerId;
        string manufacturerName;
        uint256 uniqueManufacturerIdentifier;
        address manufacturerAddress;
    }
    ManufacturerInformation[] public manufacturerInformation;

    struct ManufacturerInvoices {
        string nameOfFertilizer;
        uint256 fertilizerQuantity;
        uint256 fertilizerManufacturingCost;
        uint256 fertilizerSubsidisedCost;
    }
    mapping(uint256 manufacturerId => ManufacturerInvoices[]) manufacturerIdToInvoices;

    struct Claims {
        uint256 claimId;
        string fertilizerName;
        uint256 fertilizerQuantity;
        uint256 fertilizerManufacturiingPrice;
        uint256 fertilizerSubsidisedPrice;
    }
    Claims[] public listOfAllClaims;

    address immutable owner;

    event NewManufacturerAdded(uint256 manufacturerId, string manufacturerName);
    event ClaimAmountPaid();

    error ManufacturerAlreadyAdded();
    error ManufacturerNotAdded();

    modifier onlyOwner() {
        require(msg.sender == owner, "can be called only by the owner");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function addManufacturer(
        string memory _manufacturerName,
        address _manufacturerAddress
    ) private {
        require(
            _manufacturerAddress != address(0),
            "Manufacturer address can not be equal to address(0)"
        );

        uint256 _uniqueManufacturerIdentifier = uint256(
            keccak256(bytes(_manufacturerName))
        );

        for (uint256 i = 0; i < manufacturerInformation.length; i++) {
            if (
                manufacturerInformation[i].uniqueManufacturerIdentifier ==
                _uniqueManufacturerIdentifier
            ) {
                revert ManufacturerAlreadyAdded();
            }
        }

        ManufacturerInformation
            memory _manufacturerInformation = ManufacturerInformation({
                manufacturerId: manufacturerInformation.length,
                manufacturerName: _manufacturerName,
                uniqueManufacturerIdentifier: _uniqueManufacturerIdentifier,
                manufacturerAddress: _manufacturerAddress
            });
        manufacturerInformation.push(_manufacturerInformation);

        emit NewManufacturerAdded(
            _manufacturerInformation.manufacturerId,
            _manufacturerName
        );
    }

    function claimPayment(
        string memory _nameOfManufacturer,
        Manufacturer.ProductsSold[] memory _invoices
    ) public {
        uint256 _uniqueManufacturerIdentifier = uint256(
            keccak256(bytes(_nameOfManufacturer))
        );

        uint256 _manufacturerId = 0;
        for (uint256 i = 0; i < manufacturerInformation.length; i++) {
            if (
                manufacturerInformation[i].uniqueManufacturerIdentifier ==
                _uniqueManufacturerIdentifier
            ) {
                _manufacturerId = i;
            }
            if (i == manufacturerInformation.length - 1) {
                revert ManufacturerNotAdded();
            }
        }

        uint256 claimAmountToBePaid = 0;
        for (uint256 i = 0; i < _invoices.length; i++) {
            uint256 _manufacturerPrice = _invoices[i]
                .fertilizerManufacturingPrice;
            uint256 _subsidisedPrice = _invoices[i].fertilizerPrice;
            uint256 _quantity = _invoices[i].fertilizerQuantity;

            claimAmountToBePaid +=
                _quantity *
                (_manufacturerPrice - _subsidisedPrice);

            Claims memory _claim = Claims({
                claimId: listOfAllClaims.length,
                fertilizerName: _invoices[i].nameOfFerilizer,
                fertilizerQuantity: _quantity,
                fertilizerManufacturiingPrice: _manufacturerPrice,
                fertilizerSubsidisedPrice: _subsidisedPrice
            });
            listOfAllClaims.push(_claim);
        }

        address _manufacturerAddress = manufacturerInformation[_manufacturerId]
            .manufacturerAddress;

        (bool success, ) = _manufacturerAddress.call{
            value: claimAmountToBePaid
        }("");
        require(success, "Claim payment failed");

        emit ClaimAmountPaid();
    }

    /////////////////
    // GETTERS //////
    /////////////////

    function getClaimInformationByClaimId(
        uint256 _claimId
    ) public view returns (Claims memory) {
        Claims memory _claim = listOfAllClaims[_claimId];
        return _claim;
    }

    function getManufacturerInformationUsingManufacturerName(
        string memory _name
    )
        public
        view
        returns (ManufacturerInformation memory _manufacturerInformation)
    {
        uint256 _uniqueManufacturerIdentifier = uint256(
            keccak256(bytes(_name))
        );
        for (uint256 i = 0; i < manufacturerInformation.length; i++) {
            if (
                manufacturerInformation[i].uniqueManufacturerIdentifier ==
                _uniqueManufacturerIdentifier
            ) {
                _manufacturerInformation = manufacturerInformation[i];
                return _manufacturerInformation;
            }

            if (i == manufacturerInformation.length - 1) {
                revert ManufacturerNotAdded();
            }
        }
    }

    function getManufacturerInformationUsingId(
        uint256 _manufacturerId
    )
        public
        view
        returns (ManufacturerInformation memory _manufacturerInformation)
    {
        require(_manufacturerId < manufacturerInformation.length);
        return
            _manufacturerInformation = manufacturerInformation[_manufacturerId];
    }

    function getManufacturerInvoicesUsingManufacturerId(
        uint256 _manufacturerId
    )
        public
        view
        returns (ManufacturerInvoices[] memory _manufacturerInvoices)
    {
        require(_manufacturerId < manufacturerInformation.length);
        return
            _manufacturerInvoices = manufacturerIdToInvoices[_manufacturerId];
    }
}
