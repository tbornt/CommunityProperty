pragma solidity ^0.4.18;

contract CommunityProperty {

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
            who.balance -= amount;
        } else {
            uint left = amount - who.balance;
            who.balance = 0;
            relations[who.relationshipInfo.partner].balance -= left;
        }
        UpdateBalance(_who, amount);
    }

    /**
     * @dev deposit to account
     */
    function deposit() payable public {
        Member storage who = relations[msg.sender];
        uint value = msg.value;
        who.balance += value;
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
                        partner.transferInfo.amount -= _amount;
                        msg.sender.transfer(_amount);
                        Withdraw(msg.sender, _amount);
                    }
                    else if (_amount > partner.transferInfo.amount && _amount <= totalBalance) {
                        updateBalance(msg.sender, partner.transferInfo.amount);
                        partner.transferInfo.allowed = false;
                        msg.sender.transfer(partner.transferInfo.amount);
                        WithdrawAllowedAmount(msg.sender, partner.transferInfo.amount);
                    }
                    else {
                        updateBalance(msg.sender, totalBalance);
                        msg.sender.transfer(totalBalance);
                        partner.transferInfo.amount -= _amount;
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
                sender.balance = sender.balance - _amount;
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
                left = sender.balance - totalBalance / 2;
                sender.balance -= left;
                partner.balance += left;
            }
            else {
                left = totalBalance / 2 - sender.balance;
                sender.balance += left;
                partner.balance -= left;
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
            return who.balance + relations[who.relationshipInfo.partner].balance;
        }
    }

    function showAllInfo() external view {
        Member storage sender = relations[msg.sender];
        balance = getBalance(msg.sender);
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
                sender.transferInfo.timeLimit)
    }

}
