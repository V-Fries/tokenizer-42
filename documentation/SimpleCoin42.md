# SimpleCoin42

Simple ERC-20 compliant token

## Constants

### decimals

```solidity
uint8 public immutable decimals;
```

**Returns**

| Name         | Type    | Description                                                                       |
| ------------ | ------- | --------------------------------------------------------------------------------- |
| &lt;none&gt; | `uint8` | Number of decimals the token uses. Tokens are displayed as `tokens / 10^decimals` |

## State Variables

### name

```solidity
string public name;
```

**Returns**

| Name         | Type     | Description       |
| ------------ | -------- | ----------------- |
| &lt;none&gt; | `string` | Name of the token |

### symbol

```solidity
string public symbol;
```

**Returns**

| Name         | Type     | Description         |
| ------------ | -------- | ------------------- |
| &lt;none&gt; | `string` | Symbol of the token |

### totalSupply

```solidity
uint256 public totalSupply;
```

**Returns**

| Name         | Type      | Description                                     |
| ------------ | --------- | ----------------------------------------------- |
| &lt;none&gt; | `uint256` | Total number of tokens currently in circulation |

### balanceOf

```solidity
mapping(address _owner => uint256 balance) public balanceOf;
```

**Returns**

| Name         | Type                                         | Description                                                     |
| ------------ | -------------------------------------------- | --------------------------------------------------------------- |
| &lt;none&gt; | `mapping(address _owner => uint256 balance)` | balance Number of tokens owned by the wallet at address \_owner |

### allowance

```solidity
mapping(address _owner => mapping(address _spender => uint256 remaining))
        public allowance;
```

**Returns**

| Name         | Type                                                                        | Description                                                                         |
| ------------ | --------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| &lt;none&gt; | `mapping(address _owner => mapping(address _spender => uint256 remaining))` | remaining Number of tokens which \_spender is allowed to spend on behalf of \_owner |

## Functions

<a id="calleriscontractcreator"></a>

### constructor

```solidity
constructor(
        string memory contractName,
        string memory contractSymbol,
        uint8 contractDecimals
    );
```

**Parameters**

| Name             | Type     | Description |
| ---------------- | -------- | ----------- |
| contractName     | `string` |             |
| contractSymbol   | `string` |             |
| contractDecimals | `uint8`  |             |

<a id="minttokens-address-uint256"></a>

### mintTokens

<i>

Mint (create) new tokens and give them to receiver

</i>

<i>

Only the contract creator may mint new tokens

</i>

<i>

Emits Transfer(address(0), receiver, value) on success (even if value is 0)

</i>

```solidity
function mintTokens(
        address receiver,
        uint256 value
    ) external callerIsContractCreator isValidTokenReceiver(receiver);
```

**Parameters**

| Name     | Type      | Description                                    |
| -------- | --------- | ---------------------------------------------- |
| receiver | `address` | Address to which the new tokens should be sent |
| value    | `uint256` | Number of tokens to mint                       |

<a id="burntokens-uint256"></a>

### burnTokens

<i>

Burns (destroy) value tokens belonging to the caller

</i>

<i>

Emits Transfer(msg.sender, address(0), value) on success (even if value is 0)

</i>

```solidity
function burnTokens(
        uint256 value
    ) external hasRequiredBalance(msg.sender, value);
```

**Parameters**

| Name  | Type      | Description              |
| ----- | --------- | ------------------------ |
| value | `uint256` | Number of tokens to burn |

<a id="burntokensfrom-address-uint256"></a>

### burnTokensFrom

<i>

Burns (destroy) value tokens belonging to from

</i>

<i>

Emits Transfer(from, address(0), value) on success (even if value is 0)

</i>

<i>

When \_from is not the caller, \_from must have allowed the caller to used \_value tokens with approve(\_spender, \_value)

</i>

```solidity
function burnTokensFrom(
        address from,
        uint256 value
    )
        external
        hasRequiredAllowance(from, msg.sender, value)
        hasRequiredBalance(from, value);
```

**Parameters**

| Name  | Type      | Description                                   |
| ----- | --------- | --------------------------------------------- |
| from  | `address` | Address from which the tokens should be taken |
| value | `uint256` | Number of tokens to burn                      |

<a id="transfer-address-uint256"></a>

### transfer

<i>

Transfers \_value tokens to the `_to` wallet from the caller's wallet.

</i>

<i>

Emits Transfer(msg.sender, \_to, \_value) on success (even if \_value is 0)

</i>

```solidity
function transfer(
        address _to,
        uint256 _value
    )
        external
        isValidTokenReceiver(_to)
        hasRequiredBalance(msg.sender, _value)
        returns (bool success);
```

**Parameters**

| Name    | Type      | Description                                |
| ------- | --------- | ------------------------------------------ |
| \_to    | `address` | Address to which the tokens should be sent |
| \_value | `uint256` | Number of tokens to send                   |

**Returns**

| Name    | Type   | Description                       |
| ------- | ------ | --------------------------------- |
| success | `bool` | true on success, error on failure |

<a id="transferfrom-address-address-uint256"></a>

### transferFrom

<i>

Transfers \_value amount of tokens from address \_from to address \_to

</i>

<i>

Emits Transfer(\_fom, \_to, \_value) on success (even if \_value is 0)

</i>

<i>

When \_from is not the caller, \_from must have allowed the caller to used \_value tokens with approve(\_spender, \_value)

</i>

```solidity
function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        isValidTokenReceiver(_to)
        hasRequiredAllowance(_from, msg.sender, _value)
        hasRequiredBalance(_from, _value)
        returns (bool success);
```

**Parameters**

| Name    | Type      | Description                                   |
| ------- | --------- | --------------------------------------------- |
| \_from  | `address` | Address from which the tokens should be taken |
| \_to    | `address` | Address to which the tokens should be sent    |
| \_value | `uint256` | Number of tokens to send                      |

**Returns**

| Name    | Type   | Description                       |
| ------- | ------ | --------------------------------- |
| success | `bool` | true on success, error on failure |

<a id="approve-address-uint256"></a>

### approve

<i>

Allows spender to spend value tokens belonging to caller

</i>

<i>

Emits Approval(msg.sender, \_spender, \_value) on success (even if \_value is 0)

</i>

```solidity
function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);
```

**Parameters**

| Name      | Type      | Description                                                                             |
| --------- | --------- | --------------------------------------------------------------------------------------- |
| \_spender | `address` | Address to which we give permission to spend at most \_value tokens belonging to caller |
| \_value   | `uint256` | Number of tokens belonging to caller we allow \_spender to spend                        |

**Returns**

| Name    | Type   | Description |
| ------- | ------ | ----------- |
| success | `bool` | always true |

<a id="_burntokensunchecked-address-uint256"></a>

## Events

### Transfer

<i>

Triggered whenever tokens are transferred (includes zero value transfers)

</i>

```solidity
event Transfer(address indexed _from, address indexed _to, uint256 _value);
```

**Parameters**

| Name    | Type      | Description                                              |
| ------- | --------- | -------------------------------------------------------- |
| \_from  | `address` | Address of the wallet from which the tokens were removed |
| \_to    | `address` | Address of the wallet to which the tokens were added     |
| \_value | `uint256` | Number of the tokens that were transferred               |

### Approval

<i>

Triggered on each successful call to approve(address \_spender, uint256 \_value)

</i>

```solidity
event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
```

**Parameters**

| Name      | Type      | Description                                                                  |
| --------- | --------- | ---------------------------------------------------------------------------- |
| \_owner   | `address` | Address of the owner of the tokens that are allowed to be spend by \_spender |
| \_spender | `address` | Address the wallet allowed to use tokens belonging to \_owner                |
| \_value   | `uint256` | Number of tokens belonging to \_owner that \_spender is allowed to spend     |

## Errors

### InsufficientBalance

<i>

Error that triggers when an operation requires a higher balance then available

</i>

```solidity
error InsufficientBalance(
        uint256 requiredBalance,
        uint256 availableBalance
    );
```

**Parameters**

| Name             | Type      | Description                                                         |
| ---------------- | --------- | ------------------------------------------------------------------- |
| requiredBalance  | `uint256` | Number of the token that were required for the operation to succeed |
| availableBalance | `uint256` | Number of the token that are available in the balance               |

### InsufficientAllowance

<i>

Error that triggers when an operation requires a higher allowance then available

</i>

```solidity
error InsufficientAllowance(
        uint256 requiredAllowance,
        uint256 availableAllowance
    );
```

**Parameters**

| Name               | Type      | Description                                                         |
| ------------------ | --------- | ------------------------------------------------------------------- |
| requiredAllowance  | `uint256` | Number of the token that were required for the operation to succeed |
| availableAllowance | `uint256` | Number of the token that the caller is currently allowed to use     |
