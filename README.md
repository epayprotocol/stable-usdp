# USD.P (USDP) Stablecoin Contract — E-Pay Protocol

This repository contains the USD.P stablecoin smart contract used by the E-Pay Protocol. The on-chain token uses the symbol USD.P and implements an ERC-20–compatible interface suitable for EVM chains. The core stablecoin is defined in the single source file [USDP.sol](USDP.sol). This document is [README.md](README.md).

## What is E-Pay

Founded in 2024, E-Pay is a leading innovator in Real World Assets (RWA) that modernizes financial instruments and offers access to premium RWA through advanced tokenization technology and Proof of Reserves through attested assets by independent auditing firms. As the creator of USD.P (E-Pay Dollar / Bridged Tether E-Pay Dollar), a tokenized short-term treasury bill product backed by +$500 million in Treasury bills and a $500 million liquid cash deposit, E-Pay has rapidly emerged as a trusted provider of stable digital assets for the entertainment industry and cryptocurrency community.

In 2024, E-Pay introduced USDP, an BEP-20 token fully backed by cash, treasury notes and crypto assets. The reserves backing USDP are securely held in high-security, fully insured vaults, enabling physical redemption.

E-Pay is dedicated to becoming the gateway for clients seeking blue-chip RWA investments. With a steadfast focus on building a trusted and secure RWA ecosystem for crypto and entertainment applications, E-Pay provides diversified investment opportunities while setting new standards for trust and governance in the digital asset space.

## Token and contract summary

- Source file: [USDP.sol](USDP.sol)
- On-chain token name: E-Pay Dollar USD
- Token symbol: USD.P
- Decimals: 18
- Standard compliance: ERC-20–compatible implementation (custom, non-OpenZeppelin; no permit signatures).

Core capabilities observed in the implementation:
- Standard ERC-20 token mechanics (balance tracking, allowances, and transfers).
- Supply management is centralized under a single manager address; only the manager can mint new tokens and burn tokens.
- Initial supply: 5,000,000,000 tokens are minted at deployment to the initial manager (amounts use 18-decimal units).
- The manager address can be reassigned by the current manager.
- Not implemented in the core token: pausing, blocklists, fee mechanics, supply caps, or EIP-2612 permit signatures.

Admin and auxiliary components:
- Single-manager model for administration; no multi-role access control framework is included.
- An auxiliary collateral manager contract is present in the same source file. It can hold a collateral token (assumed 6 decimals), track per-account deposits and minted balances, read a price from an oracle (assumed 8 decimals), enforce a minimum per-account collateral ratio of 1.0 in 18‑decimal fixed point for mints and withdrawals, and allow third-party liquidation when an account falls below the threshold. To operate end‑to‑end, this auxiliary contract must be set as the manager of the stablecoin.

## Security and compliance notes

- The core stablecoin limits supply changes to a single manager address. There is no pause functionality or blocklist logic in the core implementation.
- When the auxiliary manager is used as the stablecoin’s manager, on-chain minting and redemption flows become conditional on per-account collateralization that depends on the configured collateral token and oracle data.
- Proof of Reserves is an organizational assurance process. Unless explicitly implemented on-chain, it is not enforced by this code. In this repository, PoR attestations are handled off-chain by E-Pay and independent auditors.

## Development information

- Solidity compiler version: 0.8.13 (as declared in the source).
- External libraries: none; the ERC-20 implementation and oracle interface are defined inline in [USDP.sol](USDP.sol).
- Tooling: use any standard EVM toolchain (for example, Hardhat or Foundry) configured for the compiler version above. Ensure your compiler settings and optimizer configuration match your verification target.
- Source layout: a single file, [USDP.sol](USDP.sol), containing both the stablecoin and an optional collateral manager.

## Licensing

SPDX license: MIT, as declared in the source header of [USDP.sol](USDP.sol).

## Disclaimers

- This repository and its documentation are provided for technical information about the smart contract codebase and do not constitute financial, legal, or investment advice.
- Operational reserves, audits, and off-chain assurances are managed by E-Pay and its external partners and are outside the scope of the core smart contract unless explicitly implemented in code.# stable-usdp

