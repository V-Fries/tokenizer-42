# Deployment

- Copy the code into into the src folder (The code is in ../code/ because it is imposed by the 42
  school subject):
  ```sh
  cp ../code/* src/
  ```
- Compile the code:
  ```sh
  forge build
  ```
- Make sure the tests pass:
  ```sh
  forge test
  forge test --brutalize
  forge test --mutate
  ```
- Run the deploy script (Make sure to note down the contract address outputed by this command):
  ```sh
  forge script script/DeployContract.s.sol --broadcast --rpc-url $RPC_URL --private-key $WALLET_PRIVATE_KEY
  ```

# Etherscan links

Replace CONTRACT_ADDRESS in the links with the contract address you got on deployment.

- Contract address:
  https://sepolia.etherscan.io/address/CONTRACT_ADDRESS
- Token page:
  https://sepolia.etherscan.io/token/CONTRACT_ADDRESS

# Manual testing

Once published, you can use `script/Testing.s.sol` to test the contract manually.
Make sure to update the addresses inside to the contract address you got when deploying and to the address of your wallet.

Feel free to modify the contents to run your own tests.

The script is ran with this command:

```sh
forge script script/Testing.s.sol --broadcast --rpc-url $RPC_URL --private-key $WALLET_PRIVATE_KEY
```
