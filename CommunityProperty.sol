pragma solidity ^0.4.18;

contract SafeMath {
  function safeMul(uint a, uint b) pure internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) pure internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) pure internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

//name this contract whatever you'd like
contract CommunityPropertyToken is StandardToken {

    function () {
        //if ether is sent to this address, send it back.
        throw;
    }

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It's like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = 'H1.0';       //human 0.1 standard. Just an arbitrary versioning scheme.

//
// CHANGE THESE VALUES FOR YOUR TOKEN
//

//make sure this function name matches the contract name above. So if you're token is called TutorialToken, make sure the //contract name above is also TutorialToken instead of ERC20Token

    function CommunityPropertyToken() {
        balances[msg.sender] = 100000000000000000000;               // Give the creator all initial tokens (100000 for example)
        totalSupply = 100000000000000000000;                        // Update total supply (100000 for example)
        name = "Community Property Token";                                   // Set the name for display purposes
        decimals = 18;                            // Amount of decimals for display purposes
        symbol = "CPT";                               // Set the symbol for display purposes
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}

contract CommunityProperty is SafeMath {

    event Deposit(address _who, uint amount);
    event Withdraw(address _who, uint amount);
    event WithdrawAllowedAmount(address _who, uint amount);
    event WithdrawTotal(address _who, uint amount);
    event WithdrawTimeout(address _who, uint amount);
    event WithdrawNotAllowed(address _who, uint amount);
    event AllowTransfer(uint amount, uint _timeLimit);
    event UpdateBalance(address _who, uint amount);
    event RegisterWith(address _who, uint _timeLimit);
    event PromiseTo(address _who);
    event ProposeBreakDown();
    event AllowBreakDown();

    struct RelationshipInfo {
        address partner;
        bool built;
        bool allowBreakdown;
        uint initTime;
        uint timeLimit;
    }

    struct TransferInfo {
        bool allowed;
        uint amount;
        uint allowedTime;
        uint timeLimit;
    }

    struct Member {
        uint balance;
        RelationshipInfo relationshipInfo;
        TransferInfo transferInfo;
    }

    mapping(address => Member) relations;

    /**
     * @dev Register with who
     */
    function registerWith(address _who, uint _timeLimit) external {
        // @dev only allowed to build the relationship once
        assert(_who != address(0));
        Member storage requestSender = relations[msg.sender];
        Member storage requestReceiver = relations[_who];
        if (requestSender.relationshipInfo.built == false && requestReceiver.relationshipInfo.built == false) {
            requestSender.relationshipInfo.partner = _who;
            requestSender.relationshipInfo.initTime = now;
            requestSender.relationshipInfo.timeLimit = _timeLimit;
            RegisterWith(_who, _timeLimit);
        }
    }

    /**
     * @dev Cancel register 
     */
    function cancelRegisterWith(address _who) external {
        assert(_who != address(0));
        Member storage requestSender = relations[msg.sender];
        Member storage requestReceiver = relations[_who];
        if (requestSender.relationshipInfo.built == false && requestReceiver.relationshipInfo.built == false) {
            requestSender.relationshipInfo.partner = address(0);
        }
    }

    /**
     * @dev Promise who's register
     */
    function promiseTo(address _who) external {
        assert(_who != address(0));
        Member storage requestSender = relations[msg.sender];
        Member storage requestReceiver = relations[_who];
        if (requestReceiver.relationshipInfo.partner == msg.sender && requestReceiver.relationshipInfo.built == false) {
            if (now <= requestReceiver.relationshipInfo.initTime + requestReceiver.relationshipInfo.timeLimit * 1 hours) {
                requestReceiver.relationshipInfo.built = true;
                requestSender.relationshipInfo.built = true;
                requestSender.relationshipInfo.partner = _who;
                PromiseTo(_who);
            }
        }
    }

    function updateBalance(address _who, uint amount) private {
        assert(_who != address(0));
        require(getBalance(_who) >= amount);
        Member storage who = relations[_who];
        if (who.balance >= amount) {
            who.balance = safeSub(who.balance, amount);
        } else {
            uint left = safeSub(amount, who.balance);
            who.balance = 0;
            relations[who.relationshipInfo.partner].balance = safeSub(relations[who.relationshipInfo.partner].balance, left);
        }
        UpdateBalance(_who, amount);
    }

    /**
     * @dev deposit to account
     */
    function deposit() payable public {
        Member storage who = relations[msg.sender];
        uint value = msg.value;
        who.balance = safeAdd(who.balance, value);
        Deposit(msg.sender, value);
    }

    /**
     * @dev withdraw from account
     */
    function withdraw(uint _amount) payable public {
        Member storage sender = relations[msg.sender];
        // has relations, need allowance
        uint totalBalance = getBalance(msg.sender);
        if (sender.relationshipInfo.built == true) {
            Member storage partner = relations[sender.relationshipInfo.partner];
            if (partner.transferInfo.allowed == true) {
                if (now <= partner.transferInfo.allowedTime + partner.transferInfo.timeLimit * 1 hours) {
                    if (_amount <= partner.transferInfo.amount && _amount <= totalBalance) {
                        updateBalance(msg.sender, _amount);
                        partner.transferInfo.amount = safeSub(partner.transferInfo.amount, _amount);
                        msg.sender.transfer(_amount);
                        Withdraw(msg.sender, _amount);
                    }
                    else if (_amount > partner.transferInfo.amount && _amount <= totalBalance) {
                        updateBalance(msg.sender, partner.transferInfo.amount);
                        partner.transferInfo.allowed = false;
                        partner.transferInfo.amount = 0;
                        msg.sender.transfer(partner.transferInfo.amount);
                        WithdrawAllowedAmount(msg.sender, partner.transferInfo.amount);
                    }
                    else {
                        updateBalance(msg.sender, totalBalance);
                        partner.transferInfo.allowed = false;
                        partner.transferInfo.amount = 0;
                        msg.sender.transfer(totalBalance);
                        WithdrawTotal(msg.sender, totalBalance);
                    }
                }
                else {
                    //time out
                    WithdrawTimeout(msg.sender, _amount);
                }
            } else {
                //Not allowed
                WithdrawNotAllowed(msg.sender, _amount);
            }
        }
        //no relations, withdraw directly
        else {
            if (sender.balance >= _amount) {
                sender.balance = safeSub(sender.balance, _amount);
                msg.sender.transfer(_amount);
                Withdraw(msg.sender, _amount);
            }
            else {
                sender.balance = 0;
                msg.sender.transfer(sender.balance);
                WithdrawTotal(msg.sender, sender.balance);
            }
        }
    }

    function allowTransfer(uint _amount, uint _timeLimit) external {
        Member storage sender = relations[msg.sender];
        require(sender.relationshipInfo.built == true);
        sender.transferInfo.allowed = true;
        sender.transferInfo.amount = _amount;
        sender.transferInfo.allowedTime = now;
        sender.transferInfo.timeLimit = _timeLimit;
        AllowTransfer(_amount, _timeLimit);
    }

    function cancelAllowTransfer() external {
        Member storage sender = relations[msg.sender];
        require(sender.relationshipInfo.built == true);
        if (sender.transferInfo.allowed == true) {
            sender.transferInfo.allowed = false;
        }
    }

    function allowBreadDown() external {
        Member storage sender = relations[msg.sender];
        require(sender.relationshipInfo.built == true);
        Member storage partner = relations[sender.relationshipInfo.partner];
        uint totalBalance = getBalance(msg.sender);
        if (partner.relationshipInfo.allowBreakdown == true) {
            sender.relationshipInfo.allowBreakdown = false;
            sender.relationshipInfo.built = false;
            partner.relationshipInfo.allowBreakdown = false;
            partner.relationshipInfo.built = false;
            uint left = 0;
            if (sender.balance >= totalBalance / 2) {
                left = safeSub(sender.balance, totalBalance / 2);
                sender.balance = safeSub(sender.balance, left);
                partner.balance = safeAdd(partner.balance, left);
            }
            else {
                left = safeSub(totalBalance / 2, sender.balance);
                sender.balance = safeAdd(sender.balance, left);
                partner.balance = safeSub(partner.balance, left);
            }
            AllowBreakDown();
        }
    }

    function proposeBreakDown() external  {
        Member storage sender = relations[msg.sender];
        require(sender.relationshipInfo.built == true);
        sender.relationshipInfo.allowBreakdown = true;
        ProposeBreakDown();
    }

    function cancelBreakDown() external {
        Member storage sender = relations[msg.sender];
        require(sender.relationshipInfo.built == true);
        sender.relationshipInfo.allowBreakdown = false;
    }

    function showRelation() external view returns(address) {
        if (relations[msg.sender].relationshipInfo.built == true) {
            return relations[msg.sender].relationshipInfo.partner;
        }
    }

    function getBalance(address _who) public view returns(uint) {
        assert(_who != address(0));
        Member storage who = relations[_who];
        if (who.relationshipInfo.built == false) {
            return who.balance;
        }
        else {
            return safeAdd(who.balance, relations[who.relationshipInfo.partner].balance);
        }
    }

    function showAllInfo() external view returns(address, uint, address, bool, bool, uint, uint, bool, uint, uint, uint) {
        Member storage sender = relations[msg.sender];
        uint balance = getBalance(msg.sender);
        return (msg.sender,
                balance,
                sender.relationshipInfo.partner,
                sender.relationshipInfo.built,
                sender.relationshipInfo.allowBreakdown,
                sender.relationshipInfo.initTime,
                sender.relationshipInfo.timeLimit,
                sender.transferInfo.allowed,
                sender.transferInfo.amount,
                sender.transferInfo.allowedTime,
                sender.transferInfo.timeLimit);
    }

}
