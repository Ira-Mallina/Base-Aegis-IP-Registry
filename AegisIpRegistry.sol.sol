// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

contract AegisIpRegistry {
    struct IntellectualProperty {
        address payable creator;
        uint256 licenseFeeWei;
        uint256 licensesSold;
        bool isActive;
        bytes32 ipHash;
    }

    address payable public immutable registryAdmin;
    string public registryDescriptor;
    uint256 public platformFeeBps; // 250 = 2.5%
    uint256 public ipCounter;
    uint256 public accumulatedFees;
    bool public isRegistryHalted;

    mapping(address => bool) public verifiedRegistrars;
    mapping(uint256 => IntellectualProperty) public registeredIp;
    mapping(uint256 => mapping(address => bool)) public hasLicense;

    event RegistrarAdded(address indexed registrar);
    event LicensePurchased(uint256 indexed ipId, address indexed buyer, uint256 fee);
    event IpCanceled(uint256 indexed ipId);
    event TreasuryDeposited(address indexed funder, uint256 amount);
    event ReservesEmptied(address indexed admin, uint256 amount);
    event FeesGathered(address indexed admin, uint256 amount);
    event RegistryHaltToggled(bool isHalted);
    event IpRegistered(uint256 indexed ipId, address indexed creator, bytes32 ipHash, uint256 fee);
    event RegistrarRevoked(address indexed registrar);
    event DescriptorUpdated(string newDescriptor);

    modifier onlyAdmin() {
        require(msg.sender == registryAdmin, "AegisIP: Access denied");
        _;
    }

    modifier whenNotHalted() {
        require(!isRegistryHalted, "AegisIP: Registry is halted");
        _;
    }

    constructor() {
        registryAdmin = payable(msg.sender);
        registryDescriptor = "Aegis Base IP Registry v1";
        platformFeeBps = 250; // 2.5%
        isRegistryHalted = false;
        verifiedRegistrars[msg.sender] = true;
    }

    // 1. addVerifiedRegistrar
    function addVerifiedRegistrar(address registrar) external onlyAdmin {
        require(!verifiedRegistrars[registrar], "AegisIP: Already verified");
        verifiedRegistrars[registrar] = true;
        emit RegistrarAdded(registrar);
    }

    // 2. buyIpLicense
    function buyIpLicense(uint256 ipId) external payable whenNotHalted {
        IntellectualProperty storage ip = registeredIp[ipId];
        require(ipId > 0 && ipId <= ipCounter, "AegisIP: Invalid ID");
        require(ip.isActive, "AegisIP: IP inactive");
        require(!hasLicense[ipId][msg.sender], "AegisIP: Already licensed");
        require(msg.value >= ip.licenseFeeWei, "AegisIP: Insufficient payment");

        uint256 fee = (msg.value * platformFeeBps) / 10000;
        uint256 creatorShare = msg.value - fee;

        accumulatedFees += fee;
        ip.licensesSold += 1;
        hasLicense[ipId][msg.sender] = true;

        if (creatorShare > 0) {
            (bool sent, ) = ip.creator.call{value: creatorShare}("");
            require(sent, "AegisIP: Payout failed");
        }

        emit LicensePurchased(ipId, msg.sender, msg.value);
    }

    // 3. cancelIpRegistration
    function cancelIpRegistration(uint256 ipId) external {
        IntellectualProperty storage ip = registeredIp[ipId];
        require(ipId > 0 && ipId <= ipCounter, "AegisIP: Invalid ID");
        require(msg.sender == ip.creator || msg.sender == registryAdmin, "AegisIP: Unauthorized");
        require(ip.isActive, "AegisIP: Already inactive");

        ip.isActive = false;
        emit IpCanceled(ipId);
    }

    // 4. depositPlatformTreasury
    function depositPlatformTreasury() external payable whenNotHalted {
        require(msg.value > 0, "AegisIP: Zero deposit");
        accumulatedFees += msg.value;
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    // 5. emptyPlatformReserves
    function emptyPlatformReserves() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "AegisIP: Zero balance");

        accumulatedFees = 0;
        (bool sent, ) = registryAdmin.call{value: balance}("");
        require(sent, "AegisIP: Sweep failed");

        emit ReservesEmptied(registryAdmin, balance);
    }

    // 6. gatherPlatformFees
    function gatherPlatformFees() external onlyAdmin {
        uint256 amount = accumulatedFees;
        require(amount > 0, "AegisIP: Zero fees");

        accumulatedFees = 0;
        (bool sent, ) = registryAdmin.call{value: amount}("");
        require(sent, "AegisIP: Harvest failed");

        emit FeesGathered(registryAdmin, amount);
    }

    // 7. haltIpRegistry
    function haltIpRegistry(bool isHalted) external onlyAdmin {
        isRegistryHalted = isHalted;
        emit RegistryHaltToggled(isHalted);
    }

    // 8. registerNewIp
    function registerNewIp(uint256 licenseFeeWei, bytes32 ipHash) external whenNotHalted returns (uint256) {
        require(verifiedRegistrars[msg.sender], "AegisIP: Not a verified registrar");

        ipCounter++;
        registeredIp[ipCounter] = IntellectualProperty({
            creator: payable(msg.sender),
            licenseFeeWei: licenseFeeWei,
            licensesSold: 0,
            isActive: true,
            ipHash: ipHash
        });

        emit IpRegistered(ipCounter, msg.sender, ipHash, licenseFeeWei);
        return ipCounter;
    }

    // 9. revokeRegistrarStatus
    function revokeRegistrarStatus(address registrar) external onlyAdmin {
        require(verifiedRegistrars[registrar], "AegisIP: Not verified");
        require(registrar != msg.sender, "AegisIP: Cannot revoke self");
        verifiedRegistrars[registrar] = false;
        emit RegistrarRevoked(registrar);
    }

    // 10. updateRegistryDescriptor
    function updateRegistryDescriptor(string calldata newDescriptor) external onlyAdmin {
        require(bytes(newDescriptor).length > 0, "AegisIP: Empty string");
        registryDescriptor = newDescriptor;
        emit DescriptorUpdated(newDescriptor);
    }
}