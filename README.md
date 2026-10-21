# Aegis IP Registry

A decentralized intellectual property and copyright management protocol built on the Base L2 network. Aegis provides creators with an immutable ledger to register digital assets via cryptographic hashes and automatically monetize them through trustless on-chain licensing.

## Core Mechanics
* **Automated Royalty Routing:** When an enterprise or user purchases an IP license, the smart contract instantly splits the payment, routing the creator's share directly to their wallet while retaining a micro-fee for the platform treasury.
* **Cryptographic IP Anchoring:** Creators secure their work by logging `bytes32` hashes (e.g., IPFS CIDs or SHA-256 file hashes) into the contract state, creating a timestamped, tamper-proof proof of origin.
* **License Verification:** The protocol maintains a strict `hasLicense` mapping, allowing external dApps, games, or media platforms to cryptographically verify if a user's wallet holds the rights to utilize a specific asset.

## Architecture
Compiled utilizing Solidity `0.8.37`. The protocol strictly isolates state mutations from ether transfers, utilizing the Checks-Effects-Interactions pattern during license purchases to completely eliminate reentrancy vulnerabilities.
