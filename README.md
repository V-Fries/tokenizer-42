# Tokenizer

Tokenizer is a project at the 42 School during which the student must write a smart contract and
deploy it on a blockchain.

## Blockchain choice

For this project, I decided to use the [Ethereum](https://ethereum.org/) blockchain.

Ethereum is one of the most widely used blockchain platforms for smart-contract development, with a
large developer ecosystem and extensive tooling. Its support for the Ethereum Virtual Machine (EVM)
and established token standards make it a suitable platform for experimenting with
smart-contract development.

I was already somewhat familiar with the client-side code used to interact with Ethereum smart
contracts, having written a client that interacted with [Aave](https://aave.com/) during an
internship. I therefore chose Ethereum for this project to explore the other side of the
interaction and gain experience writing and deploying a smart contract.

## Token standard

The token I created implements the [ERC-20](https://eips.ethereum.org/EIPS/eip-20) standard,
which defines a common interface for fungible tokens on Ethereum.

The contract therefore provides functionality for managing balances, transfers, allowances, and
token supply.

I also added functions to mint and burn tokens, allowing the token supply to be increased or
decreased.

The API for the contract I wrote is documented here: documentation/SimpleCoin42.md

## Deployment and testing stack

This project uses Foundry for unit testing and deployment. I chose this tool for its impressive
testing capabilities.

Sepolia is the Ethereum test chain I used during my testing.

## How to use the project

See documentation/how-to-use.md
