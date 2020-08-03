pragma solidity  ^0.5.2;

import "./Register.sol";

contract Marktpartner {
    // Events ERC-725
    event DataChanged(bytes32 indexed key, bytes value);
    event ContractCreated(address indexed contractAddress);
    event OwnerChanged(address indexed ownerAddress);

    // Attributes ERC-725
    address public owner;
    mapping(bytes32 => bytes) public data;
    mapping(bytes32 => bool) reservedDataField;

    // Other attributes
    Register public register;
    bytes public certificate;
    bool public verified;
    
    modifier onlyRegister {
        require(msg.sender == address(register));
        _;
    }
    
    constructor(address _owner, Register _register) public {
        owner = _owner;
        register = _register;
        
        reservedDataField[bytes32("headquartersAddress")] = true;
        reservedDataField[bytes32("webAddress")] = true;
        reservedDataField[bytes32("vatId")] = true;
        reservedDataField[bytes32("marktpartnerId")] = true;
        reservedDataField[bytes32("sector")] = true;
        reservedDataField[bytes32("marketRole")] = true;
    }
    
    // Functions ERC-725
        // Modifiers ERC-725
    modifier onlyOwner {
        require(msg.sender == owner || msg.sender == address(this));
        _;
    }
    
    // Functions ERC-725
    function changeOwner(address _owner) public onlyOwner {
        owner = _owner;
        emit OwnerChanged(_owner);
    }
    
    function getData(bytes32 _key) external view returns (bytes memory _value) {
        return data[_key];
    }
    
    function setData(bytes32 _key, bytes calldata _value) external onlyOwner {
        // Don't allow storing data to reserved data fields.
        require(!reservedDataField[_key]);
        
        data[_key] = _value;
        emit DataChanged(_key, _value);
    }
    
    function execute(uint256 _operationType, address _to, uint256 _value, bytes calldata _data) external onlyOwner {
        if(_operationType == 0) {
            (bool success, ) = _to.call.value(_value)(_data);
            if(!success)
                require(false);
            return;
        }
        
        // Copy calldata to memory so it can easily be accessed via assembly.
        bytes memory dataMemory = _data;
        
        if(_operationType == 1) {
            address newContract;
            assembly {
                newContract := create(0, add(dataMemory, 0x20), mload(dataMemory))
            }
            emit ContractCreated(newContract);
            return;
        }
        
        require(false);
    }

    // Other functions
    function setCertificate(bytes memory _certificate, string memory _companyName) public onlyRegister {
        certificate = _certificate;
        data[bytes32("companyName")] = bytes(_companyName);
        verified = true;
    }
    
    function setContactInformation(string memory _headquartersAddress, string memory _webAddress, string memory _vatId,
    string memory _marktpartnerId, string memory _sector, string memory _marketRole) public onlyOwner {
        data[bytes32("headquartersAddress")] = bytes(_headquartersAddress);
        data[bytes32("webAddress")] = bytes(_webAddress);
        data[bytes32("vatId")] = bytes(_vatId);
        data[bytes32("marktpartnerId")] = bytes(_marktpartnerId);
        data[bytes32("sector")] = bytes(_sector);
        data[bytes32("marketRole")] = bytes(_marketRole);
    }
    
    function getContactInformation() public view returns(string memory __companyName, string memory __headquartersAddress,
    string memory __webAddress, string memory __vatId, string memory __marktpartnerId, string memory __sector, string memory __marketRole) {
        require(verified);
        
        __companyName = string(data[bytes32("companyName")]);
        __headquartersAddress = string(data[bytes32("headquartersAddress")]);
        __webAddress = string(data[bytes32("webAddress")]);
        __vatId = string(data[bytes32("vatId")]);
        __marktpartnerId = string(data[bytes32("marktpartnerId")]);
        __sector = string(data[bytes32("sector")]);
        __marketRole = string(data[bytes32("marketRole")]);
    }
}