# How to use the SimpleCoin42 contract

## Creating an Ethereum wallet

In order to publish a smart-contract on Ethereum, we need an Ethereum wallet.
You can create one a platform like `MetaMask` (which ever platform you use, make sure they let you
access your wallet's private key.)

Take note of your wallet's private key, it will be used during the deployment commands.

## Getting your first Ether

Ether is the main currency of the Ethereum blockchain. Every operation that writes state to the
blockchain costs Ether.

For testing purposes, we can use a test chain like Sepolia in order to not have to buy any Ether.
This is what we will do.
Even on a test chain, operation still require Ether, so we will use a faucet to get some for free.
Go to https://sepolia-faucet.pk910.de/ and enter your wallet's address to get free Sepolia Ether.

## Getting access to a Sepolia node

- Create an account on [Alchemy](https://login.alchemy.com/u/signup).
- Create a new app and choose Ethereum as the chain.
- Get your Sepolia RPC endpoint (for example: https://eth-sepolia.g.alchemy.com/v2/xxxxxxxxxxxxxxxxxxxxxxxx).

This endpoint will be used by the deployment commands.

(There are other platforms besides Alchemy that support Sepolia.)

## Deployment

The deployment procedure is described at ../deployment/README.md
