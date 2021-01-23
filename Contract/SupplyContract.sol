pragma solidity ^0.4.25;

import "./Table.sol";

contract Supply0 {
    /** Table don't accept enum type. Use int256 instead */

    // enum CompanyType {core, normal}
    // enum RequestStatus {sent, accepted, refused}
    // enum TranscationMode {new, transfer}

    /** 
        Entity 
        Administrator: register banks, register certifiers, distribute & force return credits
        Bank: 
        Certifier: trusted third-party certifier
        Company:
        Transaction:
        Receipt: 
    */

    struct Administrator {
        address addr;
        uint256 outCredit;
        mapping(address => uint256) outCreditPerBank;
    }

    struct Bank {
        address addr;
        string name;
        uint256 inCredit;
        uint256 outCredit;
    }

    struct Certifier {
        address addr;
        string name;
    }

    struct Company {
        address addr;
        string name;
        uint256 cType;
        uint256 inCredit; // 获得的尚未返还的信用凭证总量
        uint256 outCredit; // 签发的尚未收回的信用凭证总量
    }

    struct Transaction {
        string id;
        address sellerAddr;
        address buyerAddr;
        uint256 amount;
        uint256 createTime;
        uint256 deadline;
        uint256 tMode;
        string oriReceiptId;
        uint256 requestStatus;
        // string info;
    }

    struct Receipt {
        string id;
        address debtorAddr;
        address debteeAddr;
        uint256 curAmount;
        uint256 oriAmount;
        uint256 createTime;
        uint256 deadline;
        string bankSignature;
        string coreCompanySignature;
        // string info;
    }

    struct RelatedTracsactionReceipt {
        uint256 transactionId;
        uint256 receiptId;
    }

    // struct Fraction {
    //     int256 numerator;
    //     int256 denominator;
    // }

    // enum LoadStatus {notSettled, settled}

    struct Finance {
        uint256 id;
        string oriReceiptId;
        address debtorAddr;
        address debteeAddr;
        uint256 paidAmount;
        uint256 oriAmount;
        uint256 interestAmount; // from createTime to lastPaidTime
        uint256 createTime;
        uint256 deadline;
        uint256 lastPaidTime;
        // Fraction annualInterestRate;
        uint256 annualInterestRate; // x / 10000
        uint256 status;
    }

    Administrator admin;
    Bank bank;
    Certifier certifier;
    Company company;
    Transaction transaction;
    Receipt receipt;
    string BankTable;
    string CertifierTable;
    string CompanyTable;
    string TransactionTable;
    string ReceiptTable;
    string RelatedTable;

    /** Constants */
    uint256 CompanyType_normal = 0;
    uint256 CompanyType_core = 1;
    uint256 RequestStatus_sent = 0;
    uint256 RequestStatus_accepted = 1;
    uint256 RequestStatus_refused = 2;
    uint256 TransactionMode_new = 0;
    uint256 TransactionMode_transfer = 1;
    uint256 FinanceStatus_requestSent = 0;
    uint256 FinanceStatus_refused = 1;
    uint256 FinanceStatus_accepted = 2;
    uint256 FinanceStatus_settled = 3;

    event BankRegistration(address addr, string name);
    event CertifierRegistration(address addr, string name);
    event CompanyRegistration(address addr, string name);
    event CoreCompanyRegistration(address addr, string name);
    event NewTransactionRequest(
        address sellerAddr,
        address buyerAddr,
        string transactionId,
        uint256 amount
    );
    event NewTransactionRespond(
        address sellerAddr,
        address buyerAddr,
        string transactionId,
        uint256 amount,
        uint256 respond
    );
    event NewReceipt(
        address debtorAddr,
        address debteeAddr,
        string receiptId,
        uint256 amount,
        uint256 deadline
    );
    event ReceiptCurAmountUpdated(string receiptId, uint256 curAmount);

    event find_debug(string table, address addr, int256 size);
    event print_debug(string message);

    function concat(string _base, string _value)
        internal
        pure
        returns (string)
    {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);
        string memory _tmpValue =
            new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);
        uint256 i;
        uint256 j;
        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }
        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }
        return string(_newValue);
    }

    function toString(address x) public pure returns (string) {
        bytes32 value = bytes32(uint256(x));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint256(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint256(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    constructor(address adminAddr, string suffix) public {
        require(
            msg.sender == adminAddr,
            "Only administrator can deploy this contract."
        );
        admin.addr = adminAddr;

        BankTable = concat("Bank", suffix);
        CertifierTable = concat("Certifier", suffix);
        CompanyTable = concat("Company", suffix);
        TransactionTable = concat("Transaction", suffix);
        ReceiptTable = concat("Receipt", suffix);
        RelatedTable = concat("RelatedTransactionReceipt", suffix);

        TableFactory tf = TableFactory(0x1001);
        tf.createTable(BankTable, "addr", "name,inCredit,outCredit");
        tf.createTable(CertifierTable, "addr", "name");
        tf.createTable(CompanyTable, "addr", "name,cType,inCredit,outCredit");
        tf.createTable(
            TransactionTable,
            "id",
            "sellerAddr,buyerAddr,amount,createTime,requestStatus"
        );
        tf.createTable(
            ReceiptTable,
            "id",
            "oriReceiptId,debtorAddr,debteeAddr,curAmount,oriAmount,createTime,deadline,requestStatus,bankSignature,coreCompanySignature"
        );
        tf.createTable(RelatedTable, "id", "transactionId,receiptId");
    }

    function openTable(string tableName) public view returns (Table) {
        TableFactory tf = TableFactory(0x1001);
        return tf.openTable(tableName);
    }

    function queryAdminOutCredit() public view returns (uint256) {
        return admin.outCredit;
    }

    function insertBank(
        address addr,
        string name,
        uint256 inCredit,
        uint256 outCredit
    ) public {
        Table t_bank = openTable(BankTable);
        Entry entry = t_bank.newEntry();
        entry.set("name", name);
        entry.set("inCredit", inCredit);
        entry.set("outCredit", outCredit);
        t_bank.insert(toString(addr), entry);
    }

    function updateBankCredit(
        address addr,
        uint256 inCredit,
        uint256 outCredit
    ) public {
        Table t_bank = openTable(BankTable);
        Entries entries = t_bank.select(toString(addr), t_bank.newCondition());
        require(entries.size() > 0, "Bank should exist.");
        require(entries.size() < 2, "Bank should be unique.");
        Entry entry = entries.get(0);
        entry.set("inCredit", inCredit);
        entry.set("outCredit", outCredit);
        t_bank.update(toString(addr), entry, t_bank.newCondition());
    }

    function findBank(address addr) public {
        Table t_bank = openTable(BankTable);
        Entries entries = t_bank.select(toString(addr), t_bank.newCondition());
        require(entries.size() > 0, "Bank should exist.");
        require(entries.size() < 2, "Bank should be unique.");
        Entry entry = entries.get(0);
        bank.addr = addr;
        bank.name = entry.getString("name");
        bank.inCredit = entry.getUInt("inCredit");
        bank.outCredit = entry.getUInt("outCredit");
    }

    function queryBankCredit(address addr) public returns (uint256) {
        findBank(addr);
        return bank.inCredit - bank.outCredit;
    }

    function insertCertifier(address addr, string name) public {
        Table t_certifier = openTable(CertifierTable);
        Entry entry = t_certifier.newEntry();
        entry.set("name", name);
        t_certifier.insert(toString(addr), entry);
    }

    function findCertifier(address addr) public {
        Table t_certifier = openTable(CertifierTable);
        Entries entries =
            t_certifier.select(toString(addr), t_certifier.newCondition());
        emit find_debug(CertifierTable, addr, entries.size());
        require(entries.size() > 0, "Certifier should exist.");
        require(entries.size() < 2, "Certifier should be unique.");
        Entry entry = entries.get(0);
        certifier.addr = addr;
        certifier.name = entry.getString("name");
    }

    function insertCompany(
        address addr,
        string name,
        uint256 cType,
        uint256 inCredit,
        uint256 outCredit
    ) public {
        Table t_company = openTable(CompanyTable);
        Entry entry = t_company.newEntry();
        entry.set("name", name);
        entry.set("cType", cType);
        entry.set("inCredit", inCredit);
        entry.set("outCredit", outCredit);
        t_company.insert(toString(addr), entry);
    }

    function updateCompanyType(address addr, uint256 cType) public {
        Table t_company = openTable(CompanyTable);
        Entries entries =
            t_company.select(toString(addr), t_company.newCondition());
        require(entries.size() > 0, "Company should exist.");
        require(entries.size() < 2, "Company should be unique.");
        Entry entry = entries.get(0);
        entry.set("cType", cType);
        t_company.update(toString(addr), entry, t_company.newCondition());
    }

    function updateCompanyCredit(
        address addr,
        uint256 inCredit,
        uint256 outCredit
    ) public {
        Table t_company = openTable(CompanyTable);
        Entries entries =
            t_company.select(toString(addr), t_company.newCondition());
        require(entries.size() > 0, "Company should exist.");
        require(entries.size() < 2, "Company should be unique.");
        // require(entries.size() == 1, "Bank should exist and be unique");
        Entry entry = entries.get(0);
        entry.set("inCredit", inCredit);
        entry.set("outCredit", outCredit);
        t_company.update(toString(addr), entry, t_company.newCondition());
    }

    function findCompany(address addr) public {
        Table t_company = openTable(CompanyTable);
        Entries entries =
            t_company.select(toString(addr), t_company.newCondition());
        emit find_debug(CompanyTable, addr, entries.size());
        require(entries.size() > 0, "Company should exist.");
        require(entries.size() < 2, "Company should be unique.");
        Entry entry = entries.get(0);
        company.addr = addr;
        company.name = entry.getString("name");
        company.cType = entry.getUInt("cType");
        company.inCredit = entry.getUInt("inCredit");
        company.outCredit = entry.getUInt("outCredit");
    }

    function queryCompanyCredit(address addr) public returns (uint256) {
        findCompany(addr);
        return company.inCredit - company.outCredit;
    }

    function insertTransaction(
        string id,
        address sellerAddr,
        address buyerAddr,
        uint256 amount,
        uint256 createTime,
        uint256 deadline,
        uint256 tMode,
        string oriReceiptId,
        uint256 requestStatus
    ) public {
        Table t_transaction = openTable(TransactionTable);
        Entry entry = t_transaction.newEntry();
        entry.set("sellerAddr", sellerAddr);
        entry.set("buyerAddr", buyerAddr);
        entry.set("amount", amount);
        entry.set("createTime", createTime);
        entry.set("deadline", deadline);
        entry.set("tMode", tMode);
        entry.set("oriReceiptId", oriReceiptId);
        entry.set("requestStatus", requestStatus);
        t_transaction.insert(id, entry);
    }

    function findTransaction(string id) public {
        Table t_transaction = openTable(TransactionTable);
        Entries entries =
            t_transaction.select(id, t_transaction.newCondition());
        require(entries.size() > 0, "Transaction should exist.");
        require(entries.size() < 2, "Transaction should be unique.");
        Entry entry = entries.get(0);
        transaction.id = id;
        transaction.sellerAddr = entry.getAddress("sellerAddr");
        transaction.buyerAddr = entry.getAddress("buyerAddr");
        transaction.amount = entry.getUInt("amount");
        transaction.createTime = entry.getUInt("createTime");
        transaction.deadline = entry.getUInt("deadline");
        transaction.tMode = entry.getUInt("tMode");
        transaction.oriReceiptId = entry.getString("oriReceiptId");
        transaction.requestStatus = entry.getUInt("requestStatus");
    }

    function updateTransactionStatus(string id, uint256 requestStatus) public {
        Table t_transaction = openTable(TransactionTable);
        Entries entries =
            t_transaction.select(id, t_transaction.newCondition());
        require(entries.size() > 0, "Transaction should exist.");
        require(entries.size() < 2, "Transaction should be unique.");
        Entry entry = entries.get(0);
        entry.set("requestStatus", requestStatus);
        t_transaction.update(id, entry, t_transaction.newCondition());
    }

    function insertReceipt(
        string id,
        address debtorAddr,
        address debteeAddr,
        uint256 curAmount,
        uint256 oriAmount,
        uint256 createTime,
        uint256 deadline,
        string bankSignature,
        string coreCompanySignature
    ) public {
        Table t_receipt = openTable(ReceiptTable);
        Entry entry = t_receipt.newEntry();
        entry.set("debtorAddr", debtorAddr);
        entry.set("debteeAddr", debteeAddr);
        entry.set("curAmount", curAmount);
        entry.set("oriAmount", oriAmount);
        entry.set("createTime", createTime);
        entry.set("deadline", deadline);
        entry.set("bankSignature", bankSignature);
        entry.set("coreCompanySignature", coreCompanySignature);
        t_receipt.insert(id, entry);
    }

    function findReceipt(string id) public {
        Table t_receipt = openTable(ReceiptTable);
        Entries entries = t_receipt.select(id, t_receipt.newCondition());
        require(entries.size() > 0, "Receipt should exist.");
        require(entries.size() < 2, "Receipt should be unique.");
        Entry entry = entries.get(0);
        receipt.id = id;
        receipt.debtorAddr = entry.getAddress("debtorAddr");
        receipt.debteeAddr = entry.getAddress("debteeAddr");
        receipt.curAmount = entry.getUInt("curAmount");
        receipt.oriAmount = entry.getUInt("oriAmount");
        receipt.createTime = entry.getUInt("createTime");
        receipt.deadline = entry.getUInt("deadline");
        receipt.bankSignature = entry.getString("bankSignature");
        receipt.coreCompanySignature = entry.getString("coreCompanySignature");
    }

    function updateReceiptAmount(string id, uint256 curAmount) public {
        Table t_receipt = openTable(ReceiptTable);
        Entries entries = t_receipt.select(id, t_receipt.newCondition());
        require(entries.size() > 0, "Receipt should exist.");
        require(entries.size() < 2, "Receipt should be unique.");
        Entry entry = entries.get(0);
        entry.set("curAmount", curAmount);
        t_receipt.update(id, entry, t_receipt.newCondition());
    }

    function registerBank(address addr, string name) public {
        require(
            msg.sender == admin.addr,
            "Only administrator can register banks"
        );
        insertBank(addr, name, 0, 0);
        emit BankRegistration(addr, name);
    }

    function registerCertifier(address addr, string name) public {
        require(
            msg.sender == admin.addr,
            "Only administrator can register certifiers"
        );
        insertCertifier(addr, name);
        emit CertifierRegistration(addr, name);
    }

    function registerCompany(address addr, string name) public {
        // Only certifier can register certifiers.
        // Administrator can register itself to be a certifier.
        findCertifier(msg.sender);
        insertCompany(addr, name, CompanyType_normal, 0, 0);
        emit CompanyRegistration(addr, name);
    }

    function registerCoreCompany(address addr) public {
        findCertifier(msg.sender);
        findCompany(addr);
        require(
            company.cType != CompanyType_core,
            "This company is already a core company"
        );
        updateCompanyType(addr, CompanyType_core);
        emit CoreCompanyRegistration(addr, company.name);
    }

    function creditDistributionToBank(address bankAddr, uint256 amount) public {
        require(
            msg.sender == admin.addr,
            "Only administrator can distribute credit to banks"
        );
        findBank(bankAddr);
        bank.inCredit += amount;
        admin.outCredit += amount;
        admin.outCreditPerBank[bankAddr] += amount;
        updateBankCredit(bankAddr, bank.inCredit, bank.outCredit);
    }

    // called by admin. force return
    function creditReturnFromBank(address bankAddr, uint256 amount) public {
        require(
            msg.sender == admin.addr,
            "Only administrator can force banks to return credit."
        );
        findBank(bankAddr);
        require(
            bank.inCredit - bank.outCredit >= amount,
            "The bank doesn't have enough credit points."
        );
        bank.inCredit -= amount;
        admin.outCredit -= amount;
        admin.outCreditPerBank[bankAddr] -= amount;
        updateBankCredit(bankAddr, bank.inCredit, bank.outCredit);
    }

    function creditDistributionToCore(address coreAddr, uint256 amount) public {
        findBank(msg.sender);
        findCompany(coreAddr);
        require(
            company.cType == CompanyType_core,
            "Must distribute credit to core company."
        );
        // findBank(bankAddr);
        company.inCredit += amount;
        bank.outCredit += amount;
        updateCompanyCredit(coreAddr, company.inCredit, company.outCredit);
        updateBankCredit(bank.addr, bank.inCredit, bank.outCredit);
    }

    // called by bank. force return
    function creditReturnFromCore(address coreAddr, uint256 amount) public {
        findBank(msg.sender);
        findCompany(coreAddr);
        require(
            company.cType == CompanyType_core,
            "Must force credit return from core company."
        );
        require(
            company.inCredit - company.outCredit >= amount,
            "The company doesn't have enough credit points."
        );
        company.inCredit -= amount;
        bank.outCredit -= amount;
        updateCompanyCredit(coreAddr, company.inCredit, company.outCredit);
        updateBankCredit(bank.addr, bank.inCredit, bank.outCredit);
    }

    function transactionRequest(
        address sellerAddr,
        uint256 amount,
        uint256 deadline,
        uint256 tMode,
        string memory oriReceiptId
    ) public {
        require(amount > 0, "Amount <= 0 is not allowed.");
        require(
            tMode == 0 || tMode == 1,
            "tMode should be 0 or 1: 0 stands for making new receipt, 1 stands for transfering origin receipt"
        );
        address buyerAddr = msg.sender;
        findCompany(buyerAddr);
        Company memory buyer = company;
        findCompany(sellerAddr);
        // Company memory seller = company;
        require(
            buyer.inCredit - buyer.outCredit >= amount,
            "Buyer doesn't have enough credit points."
        );
        if (tMode == TransactionMode_transfer) {
            require(
                buyer.cType == CompanyType_core,
                "Buyer should be core company if the transaction isn't paid by transfer extant receipt."
            );
            findReceipt(oriReceiptId);
            require(
                receipt.curAmount >= amount,
                "Not enough amount in origin receipt."
            );
        } else {
            oriReceiptId = new string(0);
        }

        string memory transactionId =
            new string(
                uint256(
                    keccak256(
                        abi.encodePacked(sellerAddr, buyerAddr, amount, now)
                    )
                )
            );
        insertTransaction(
            transactionId,
            sellerAddr,
            buyerAddr,
            amount,
            now,
            deadline,
            tMode,
            oriReceiptId,
            RequestStatus_sent
        );
        emit NewTransactionRequest(
            sellerAddr,
            buyerAddr,
            transactionId,
            amount
        );
    }

    function transactionRespond(string transactionId, uint256 respond) public {
        require(
            respond == 0 || respond == 1,
            "Respond is 0 or 1: 0 stands for refusing, 1 stands for accepting."
        );
        findTransaction(transactionId);
        // address sellerAddr = transaction.sellerAddr;
        // address buyerAddr = transaction.buyerAddr;
        // uint256 amount = transaction.amount;
        // uint256 deadline = transaction.deadline;
        // uint256 tMode = transaction.tMode;
        // string memory oriReceiptId = transaction.oriReceiptId;
        // Company memory buyer = company;
        // Company memory seller = company;

        if (respond == 0) {
            updateTransactionStatus(transactionId, RequestStatus_refused);
        } else {
            if (transaction.tMode == TransactionMode_transfer) {
                // split receipt
                findReceipt(transaction.oriReceiptId);
                // Receipt memory oriReceipt = receipt;
                require(
                    receipt.curAmount >= transaction.amount,
                    "Not enough amount in origin receipt."
                );
                receipt.curAmount -= transaction.amount;
                updateReceiptAmount(receipt.id, receipt.curAmount);
                emit ReceiptCurAmountUpdated(receipt.id, receipt.curAmount);
            }
            // seller
            findCompany(transaction.sellerAddr);
            company.inCredit += transaction.amount;
            updateCompanyCredit(
                company.id,
                company.inCredit,
                company.outCredit
            );
            // buyer
            findCompany(transaction.buyerAddr);
            company.outCredit += transaction.amount;
            updateCompanyCredit(
                company.id,
                company.inCredit,
                company.outCredit
            );
            string memory receiptId =
                new string(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                transaction.sellerAddr,
                                transaction.buyerAddr,
                                transaction.amount,
                                transaction.deadline,
                                now
                            )
                        )
                    )
                );
            insertReceipt(
                receiptId,
                transaction.sellerAddr,
                transaction.buyerAddr,
                transaction.amount,
                transaction.amount,
                now,
                transaction.deadline,
                transaction.bankSignature,
                transaction.coreCompanySignature
            );
            emit NewReceipt(
                transaction.sellerAddr,
                transaction.buyerAddr,
                receiptId,
                transaction.amount,
                transaction.deadline
            );
            updateTransactionStatus(transactionId, RequestStatus_accepted);
        }
        emit NewTransactionRespond(
            transaction.sellerAddr,
            transaction.buyerAddr,
            transaction.id,
            transaction.amount,
            respond
        );
    }

    function financeRequest(
        address bankAddr,
        string oriReceiptId,
        uint256 amount,
        uint256 annualInterestRate
    ) {
        findCompany(msg.sender);
        findBank(bankAddr);
        findReceipt(oriReceiptId);
        require(amount > 0, "Amount <= 0 is not allowed.");
        require(
            company.inCredit - company.outCredit >= amount,
            "Company doesn't have enough credit points."
        );
        require(
            receipt.curAmount >= amount,
            "There isn't enough money in this receipt."
        );
        string memory financeId =
            new string(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            receipt.sellerAddr,
                            receipt.buyerAddr,
                            receipt.amount,
                            now
                        )
                    )
                )
            );
        insertFinance(
            financeId,
            bankAddr,
            company.addr,
            0,
            amount,
            0,
            now,
            deadline,
            now,
            annualInterestRate,
            FinanceStatus_requestSent
        );
        emit NewFinanceRequest(bankAddr, company.addr, financeId, amount);
    }

    function financeRespond(string financeId, uint256 respond) public {
        require(
            respond == 0 || respond == 1,
            "Respond is 0 or 1: 0 stands for refusing, 1 stands for accepting."
        );
        findFinance(financeId);

        if (respond == 0) {
            updateFinanceStatus(financeId, FinanceStatus_refused);
        } else {
            findReceipt(finance.oriReceiptId);
            require(
                receipt.curAmount >= finance.oriAmount,
                "Not enough amount in origin receipt."
            );
            receipt.curAmount -= finance.amount;
            updateReceiptAmount(receipt.id, receipt.curAmount);
            emit ReceiptCurAmountUpdated(receipt.id, receipt.curAmount);
            // company
            findCompany(finance.debteeAddr);
            company.outCredit += amount;
            updateCompanyCredit(
                company.addr,
                company.inCredit,
                company.outCredit
            );
            // bank
            findBank(finance.debtorAddr);
            bank.inCredit += amount;
            updateBankCredit(bank.addr, bank.inCredit, bank.outCredit);

            updateFinanceStatus(financeId, FinanceStatus_accepted);
        }

        emit NewFinanceRespond(
            finance.debtorAddr,
            finance.debteeAddr,
            finance.id,
            finance.oriReceiptId,
            finance.oriAmount,
            respond
        );
    }
}
