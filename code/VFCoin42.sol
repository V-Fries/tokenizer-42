// SPDX-License-Identifier: MIT
pragma solidity ^0.8.37;

/// @notice Simple ERC-20 compliant token
contract VFCoin42 {
    // ------------------------------------- State ------------------------------------------------

    /// @return Name of the token
    string public constant name = "VFCoin42";

    /// @return Symbol of the token
    string public constant symbol = "VFC42";

    /// @return Number of decimals the token uses. Tokens are displayed as `tokens / 10^decimals`
    uint8 public constant decimals = 18;

    /// @return Total number of tokens currently in circulation
    uint256 public totalSupply;

    /// @return balance Number of tokens owned by the wallet at address _owner
    mapping(address _owner => uint256 balance) public balanceOf;

    /// @return remaining Number of tokens which _spender is allowed to spend on behalf of _owner
    mapping(address _owner => mapping(address _spender => uint256 remaining))
        public allowance;

    /// @dev Used to ensure only the contract's creator may mint new tokens. Is set in the constructor()
    address immutable _contractCreator;

    // ------------------------------------- Events -----------------------------------------------

    /// @dev Triggered whenever tokens are transferred (includes zero value transfers)
    /// @param _from Address of the wallet from which the tokens were removed
    /// @param _to Address of the wallet to which the tokens were added
    /// @param _value Number of the tokens that were transferred
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// @dev Triggered on each successful call to approve(address _spender, uint256 _value)
    /// @param _owner Address of the owner of the tokens that are allowed to be spend by _spender
    /// @param _spender Address the wallet allowed to use tokens belonging to _owner
    /// @param _value Number of tokens belonging to _owner that _spender is allowed to spend
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // ------------------------------------- Errors -----------------------------------------------

    /// @dev Error that triggers when an operation requires a higher balance then available
    /// @param requiredBalance Number of the token that were required for the operation to succeed
    /// @param availableBalance Number of the token that are available in the balance
    error InsufficientBalance(
        uint256 requiredBalance,
        uint256 availableBalance
    );

    /// @dev Error that triggers when an operation requires a higher allowance then available
    /// @param requiredAllowance Number of the token that were required for the operation to succeed
    /// @param availableAllowance Number of the token that the caller is currently allowed to use
    error InsufficientAllowance(
        uint256 requiredAllowance,
        uint256 availableAllowance
    );

    // ------------------------------------- Modifiers --------------------------------------------

    /// @dev Checks that the caller is the contract creator
    modifier callerIsContractCreator() {
        require(
            msg.sender == _contractCreator,
            "Requires caller to be the contract creator"
        );
        _;
    }

    /// @dev Checks that the address is allowed to own tokens
    /// @param addr Address for which to check permissions
    modifier isValidTokenReceiver(address addr) {
        require(addr != address(0), "token receiver may not be 0");
        _;
    }

    /// @dev Checks that balanceOwner has at least requiredBalance tokens in their balance
    /// @param balanceOwner Address of the wallet that needs to contain requiredBalance tokens
    /// @param requiredBalance Number of tokens that balanceOwner needs to own
    modifier hasRequiredBalance(address balanceOwner, uint256 requiredBalance) {
        require(
            balanceOf[balanceOwner] >= requiredBalance,
            InsufficientBalance(requiredBalance, balanceOf[balanceOwner])
        );
        _;
    }

    /// @dev Checks that owner allowed spender to spend at least requiredAllowance tokens
    /// @dev Owner can allow spender to spend tokens with approve(_spender, _value)
    /// @param owner Address that owns the tokens spender may be allowed to spend
    /// @param spender Address that needs to have been allowed by owner to spend tokens on their behalf
    /// @param requiredAllowance Number of tokens that owner needs to have allowed spender to spend
    modifier hasRequiredAllowance(
        address owner,
        address spender,
        uint256 requiredAllowance
    ) {
        require(
            owner == spender || allowance[owner][spender] >= requiredAllowance,
            InsufficientAllowance(requiredAllowance, allowance[owner][spender])
        );
        _;
    }

    // ------------------------------------ Constructor -------------------------------------------

    // constructor is called only when the contract is created
    constructor() {
        _contractCreator = msg.sender;
    }

    // --------------------------------- External Functions ---------------------------------------

    /// @dev Mint (create) new tokens and give them to receiver
    /// @dev Only the contract creator may mint new tokens
    /// @dev Emits Transfer(address(0), receiver, value) on success (even if value is 0)
    /// @param receiver Address to which the new tokens should be sent
    /// @param value Number of tokens to mint
    function mint_tokens(
        address receiver,
        uint256 value
    ) external callerIsContractCreator isValidTokenReceiver(receiver) {
        balanceOf[receiver] += value;
        totalSupply += value;
        emit Transfer(address(0), receiver, value);
    }

    /// @dev Burns (destroy) value tokens belonging to the caller
    /// @dev Emits Transfer(msg.sender, address(0), value) on success (even if value is 0)
    /// @param value Number of tokens to burn
    function burn_tokens(
        uint256 value
    ) external hasRequiredBalance(msg.sender, value) {
        _burnTokensUnchecked(msg.sender, value);
    }

    /// @dev Burns (destroy) value tokens belonging to from
    /// @dev Emits Transfer(from, address(0), value) on success (even if value is 0)
    /// @dev When _from is not the caller, _from must have allowed the caller to used _value tokens with approve(_spender, _value)
    /// @param from Address from which the tokens should be taken
    /// @param value Number of tokens to burn
    function burn_tokens_from(
        address from,
        uint256 value
    )
        external
        hasRequiredAllowance(from, msg.sender, value)
        hasRequiredBalance(from, value)
    {
        _burnTokensUnchecked(from, value);
        _decrementAllowance(from, msg.sender, value);
    }

    /// @dev Transfers _value tokens to the `_to` wallet from the caller's wallet.
    /// @dev Emits Transfer(msg.sender, _to, _value) on success (even if _value is 0)
    /// @param _to Address to which the tokens should be sent
    /// @param _value Number of tokens to send
    /// @return success true on success, error on failure
    function transfer(
        address _to,
        uint256 _value
    )
        external
        isValidTokenReceiver(_to)
        hasRequiredBalance(msg.sender, _value)
        returns (bool success)
    {
        _transferFromUnchecked(msg.sender, _to, _value);
        return true;
    }

    /// @dev Transfers _value amount of tokens from address _from to address _to
    /// @dev Emits Transfer(_fom, _to, _value) on success (even if _value is 0)
    /// @dev When _from is not the caller, _from must have allowed the caller to used _value tokens with approve(_spender, _value)
    /// @param _from Address from which the tokens should be taken
    /// @param _to Address to which the tokens should be sent
    /// @param _value Number of tokens to send
    /// @return success true on success, error on failure
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        isValidTokenReceiver(_to)
        hasRequiredAllowance(_from, msg.sender, _value)
        hasRequiredBalance(_from, _value)
        returns (bool success)
    {
        _transferFromUnchecked(_from, _to, _value);
        _decrementAllowance(_from, msg.sender, _value);
        return true;
    }

    /// @dev Allows spender to spend value tokens belonging to caller
    /// @dev Emits Approval(msg.sender, _spender, _value) on success (even if _value is 0)
    /// @param _spender Address to which we give permission to spend at most _value tokens belonging to caller
    /// @param _value Number of tokens belonging to caller we allow _spender to spend
    /// @return success always true
    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // ---------------------------------- Public Functions ----------------------------------------

    // --------------------------------- Internal Functions ---------------------------------------

    // ---------------------------------- Private Functions ---------------------------------------

    /// @dev Removes value tokens from `from`'s balance
    /// @dev Reduces the totalSupply by value
    /// @dev Emits Transfer(from, address(0), value)
    /// @param from Address from which to burn tokens
    /// @param value Number of tokens to burn
    function _burnTokensUnchecked(address from, uint256 value) private {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    /// @dev Removes value tokens from `from`'s balance
    /// @dev Adds value tokens to `to`'s balance
    /// @dev Emits Transfer(from, to, value)
    /// @param from Address from which to take tokens
    /// @param to Address to which to give tokens
    /// @param value Number of tokens to add to `to` and remove from `from`
    function _transferFromUnchecked(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    /// @dev Decreases how many tokens belonging to owner spender is allowed to spend
    /// @dev Does nothing if owner == spender
    /// @param owner Address of the wallet that allowed spender to spend it's tokens
    /// @param spender Address of the wallet that is allowed to spend owner's tokens
    /// @param value Number of owner tokens to remove from spender's allowance
    function _decrementAllowance(
        address owner,
        address spender,
        uint256 value
    ) private {
        if (owner != spender) {
            allowance[owner][spender] -= value;
        }
    }
}
