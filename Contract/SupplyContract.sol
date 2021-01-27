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

    struct Certifier {
        address addr;
        string name;
    }

    struct Company {
        address addr;
        string name;
        uint256 cType;
        uint256 creditAmount;
        uint256 cashAmount;
    }

    struct Transaction {
        address payeeAddr; // seller
        address payerAddr; // buyer
        uint256 id;
        uint256 amount;
        uint256 createTime;
        uint256 deadline;
        uint256 tMode;
        uint256 oriReceiptId;
        uint256 requestStatus;
        string info;
        uint256 isFinance;
    }

    struct Receipt {
        address payeeAddr; // payeeAddr
        address payerAddr; // payerAddr
        uint256 id;
        uint256 paidAmount;
        uint256 oriAmount;
        uint256 createTime;
        uint256 deadline;
        uint256 receiptStatus;
        string bankSignature;
        string coreCompanySignature;
        string info;
        uint256 isFinance;
    }

    Administrator admin;
    Certifier certifier;
    Company company;
    Transaction transaction;
    Receipt receipt;
    string CertifierTable;
    string CompanyTable;
    string TransactionTable;
    string ReceiptTable;

    uint256 addrCount;
    mapping(uint256 => address) addrs;
    mapping(address => bool) isCertifier;
    mapping(address => bool) isNormalCompany;
    mapping(address => bool) isCoreCompany;
    mapping(address => bool) isBank;

    /** Constants */
    uint256 cType_normal = 0; // company
    uint256 cType_core = 1; // company
    uint256 cType_bank = 2;

    uint256 RequestStatus_sent = 0;
    uint256 RequestStatus_accepted = 1;
    uint256 RequestStatus_refused = 2;

    uint256 TransactionMode_new = 0;
    uint256 TransactionMode_transfer = 1;

    uint256 ReceiptStatus_paying = 0;
    uint256 ReceiptStatus_settled = 1;

    event NewRegistration(address addr, string name, string rType);
    event UpdateCompany(
        address addr,
        string name,
        string field,
        uint256 value,
        string cType
    );
    event UpdateCompany2(
        address addr,
        string name,
        string field_1,
        uint256 value_1,
        string field_2,
        uint256 value_2,
        string cType
    );
    event NewRequest(
        address payeeAddr, // 收款人
        string payeeName,
        address payerAddr, // 付款人
        string payerName,
        uint256 amount,
        string rType
    );
    event NewRespond(
        address payeeAddr, // 收款人
        string payeeName,
        address payerAddr, // 付款人
        string payerName,
        uint256 amount,
        uint256 respond,
        string rType
    );
    event NewTransaction(
        address payeeAddr, // 收款人
        string payeeName,
        address payerAddr, // 付款人
        string payerName,
        uint256 id,
        uint256 amount,
        string tType
    );
    event NewReceipt(
        address payeeAddr, // 收款人
        string payeeName,
        address payerAddr, // 付款人
        string payerName,
        uint256 id,
        uint256 oriAmount,
        string tType
    );
    event UpdateReceipt(
        address payeeAddr, // 收款人
        string payeeName,
        address payerAddr, // 付款人
        string payerName,
        uint256 id,
        uint256 paidAmount,
        uint256 oriAmount,
        string tType
    );

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

        addrs[0] = adminAddr;
        addrCount = 1;

        CertifierTable = concat("Certifier", suffix);
        CompanyTable = concat("Company", suffix);
        TransactionTable = concat("Transaction", suffix);
        ReceiptTable = concat("Receipt", suffix);

        TableFactory tf = TableFactory(0x1001);
        tf.createTable(CertifierTable, "addr", "name");
        tf.createTable(
            CompanyTable,
            "addr",
            "name,cType,creditAmount,cashAmount"
        );
        tf.createTable(
            TransactionTable,
            "payeeAddr",
            "payerAddr,id,amount,createTime,deadline,tMode,oriReceiptId,requestStatus,info,isFinance"
        );
        tf.createTable(
            ReceiptTable,
            "payeeAddr",
            "payerAddr,id,paidAmount,oriAmount,createTime,deadline,receiptStatus,bankSignature,coreCompanySignature,info,isFinance"
        );
    }

    /** query  */

    function _getAll(uint256 queryType) private returns (string) {
        string memory result = "";
        string memory next = "";
        for (uint256 i = 0; i < addrCount; i++) {
            if (
                (queryType == 0 && isCertifier[addrs[i]]) ||
                (queryType == 2 &&
                    (isNormalCompany[addrs[i]] || isCoreCompany[addrs[i]])) ||
                (queryType == 2 && isNormalCompany[addrs[i]]) ||
                (queryType == 3 && isCoreCompany[addrs[i]]) ||
                (queryType == 4 && isBank[addrs[i]])
            ) {
                next = concat(toString(addrs[i]), " ");
                result = concat(result, next);
            }
        }
        return result;
    }

    function getAllCertifier() public returns (string) {
        return _getAll(0);
    }

    function getAllCompany() public returns (string) {
        return _getAll(1);
    }

    function getAllNormalCompany() public returns (string) {
        return _getAll(2);
    }

    function getAllCoreCompany() public returns (string) {
        return _getAll(3);
    }

    function getAllBank() public returns (string) {
        return _getAll(4);
    }

    function getAllRole(address addr) public returns (string) {
        string memory result = "";
        string memory next = "";

        if (addr == admin.addr) {
            result = concat(result, "Administrator");
        }
        if (isBank[addr] == true) {
            result = concat(result, "Bank ");
        }
        if (isCertifier[addr] == true) {
            result = concat(result, "Certifier ");
        }
        if (isNormalCompany[addr] == true) {
            result = concat(result, "Company(Normal) ");
        }
        if (isCoreCompany[addr] == true) {
            result = concat(result, "Company(Core) ");
        }
        return result;
    }

    /** database insert and update */

    function openTable(string tableName) private view returns (Table) {
        TableFactory tf = TableFactory(0x1001);
        return tf.openTable(tableName);
    }

    function getAdmin() public returns (address) {
        return admin.addr;
    }

    /** 查询管理员分发的credit总数 */
    function queryAdminOutCredit() public view returns (uint256) {
        return admin.outCredit;
    }

    /** 查询管理员分给某一银行的credit总数 */
    function queryAdminOutCredit2Bank(address bankAddr)
        public
        view
        returns (uint256)
    {
        return admin.outCreditPerBank[bankAddr];
    }

    /***** handle certifier *****/

    function insertCertifier(address addr, string name) private {
        Table t_certifier = openTable(CertifierTable);
        Entry entry = t_certifier.newEntry();
        entry.set("name", name);
        t_certifier.insert(toString(addr), entry);
        emit NewRegistration(addr, name, "Certifier");
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

    /***** handle company *****/

    function insertCompany(
        address addr,
        string name,
        uint256 cType,
        uint256 creditAmount,
        uint256 cashAmount
    ) private {
        Table t_company = openTable(CompanyTable);
        Entry entry = t_company.newEntry();
        entry.set("name", name);
        entry.set("cType", cType);
        entry.set("creditAmount", creditAmount);
        entry.set("cashAmount", cashAmount);
        t_company.insert(toString(addr), entry);
        string memory rType;
        if (cType == cType_bank) {
            rType = "Bank";
        } else {
            rType = "Company(Normal)";
        }
        emit NewRegistration(addr, name, rType);
    }

    function updateCompanyUInt1(
        address addr,
        string field,
        uint256 value
    ) private {
        Table t_company = openTable(CompanyTable);
        Entries entries =
            t_company.select(toString(addr), t_company.newCondition());
        require(entries.size() > 0, "Company or bank should exist.");
        require(entries.size() < 2, "Company or bank should be unique.");
        Entry entry = entries.get(0);
        entry.set(field, value);
        t_company.update(toString(addr), entry, t_company.newCondition());

        if (field == "cType" && value == cType_core) {
            emit NewRegistration(
                addr,
                entry.getString("name"),
                "Company(core)"
            );
        } else {
            emit UpdateCompany(
                addr,
                entry.getString("name"),
                field,
                value,
                "Company"
            );
        }
    }

    function updateCompanyUInt2(
        address addr,
        string field_1,
        uint256 value_1,
        string field_2,
        uint256 value_2
    ) private {
        Table t_company = openTable(CompanyTable);
        Entries entries =
            t_company.select(toString(addr), t_company.newCondition());
        require(entries.size() > 0, "Company should exist.");
        require(entries.size() < 2, "Company should be unique.");
        Entry entry = entries.get(0);
        entry.set(field_1, value_1);
        entry.set(field_2, value_2);
        t_company.update(toString(addr), entry, t_company.newCondition());
        emit UpdateCompany2(
            addr,
            entry.getString("name"),
            field_1,
            value_1,
            field_2,
            value_2,
            "Company"
        );
    }

    function findCompany(address addr, bool isBank) private {
        Table t_company = openTable(CompanyTable);
        Condition cond = t_company.newCondition();
        if (isBank == true) {
            cond.EQ(cType_bank);
        } else {
            cond.NE(cType_bank);
        }
        Entries entries = t_company.select(toString(addr), cond);
        emit find_debug(CompanyTable, addr, entries.size());
        require(entries.size() > 0, "Company or bank should exist.");
        require(entries.size() < 2, "Company or bank should be unique.");
        Entry entry = entries.get(0);
        company.addr = addr;
        company.name = entry.getString("name");
        company.cType = entry.getUInt("cType");
        company.creditAmount = entry.getUInt("creditAmount");
        company.cashAmount = entry.getUInt("cashAmount");
    }

    /** 查询公司或银行的type, credit余额, cash余额 */
    function queryCompanyField(address addr, string field)
        public
        returns (uint256)
    {
        require(
            field == "cType" ||
                field == "creditAmount" ||
                field == "cashAmount",
            "Field should be cType, creditAmount or cashAmount."
        );
        findCompany(addr);
        if (field == "cType") return company.cType;
        if (field == "creditAmount") return company.creditAmount;
        return company.cashAmount;
    }

    /***** handle transaction *****/

    function insertTransaction(
        address payeeAddr,
        address payerAddr,
        uint256 id,
        uint256 amount,
        uint256 createTime,
        uint256 deadline,
        uint256 tMode,
        string oriReceiptId,
        uint256 requestStatus,
        string info,
        uint256 isFinance
    ) private {
        Table t_transaction = openTable(TransactionTable);
        Entry entry = t_transaction.newEntry();
        entry.set("payerAddr", payerAddr);
        entry.set("id", id);
        entry.set("amount", amount);
        entry.set("createTime", createTime);
        entry.set("deadline", deadline);
        entry.set("tMode", tMode);
        entry.set("oriReceiptId", oriReceiptId);
        entry.set("requestStatus", requestStatus);
        entry.set("info", info);
        entry.set("isFinance", isFinance);
        t_transaction.insert(toString(payeeAddr), entry);
    }

    function findTransaction(string key, uint256 id) private {
        Table t_transaction = openTable(TransactionTable);
        Condition cond = t_transaction.newCondition();
        cond.EQ("id", id);
        Entries entries = t_transaction.select(key, cond);
        require(entries.size() > 0, "Transaction should exist.");
        require(entries.size() < 2, "Transaction should be unique.");
        Entry entry = entries.get(0);
        transaction.payeeAddr = entry.getAddress("payeeAddr");
        transaction.payerAddr = entry.getAddress("payerAddr");
        transaction.id = id;
        transaction.amount = entry.getUInt("amount");
        transaction.createTime = entry.getUInt("createTime");
        transaction.deadline = entry.getUInt("deadline");
        transaction.tMode = entry.getUInt("tMode");
        transaction.oriReceiptId = entry.getString("oriReceiptId");
        transaction.requestStatus = entry.getUInt("requestStatus");
        transaction.info = entry.getString("info");
        transaction.isFinance = entry.getUInt("isFinance");
    }

    function updateTransactionUInt1(
        string key,
        uint256 id,
        string field,
        uint256 value
    ) private {
        Table t_transaction = openTable(TransactionTable);
        Condition cond = t_transaction.newCondition();
        cond.EQ("id", id);
        Entries entries = t_transaction.select(key, cond);
        require(entries.size() > 0, "Transaction should exist.");
        require(entries.size() < 2, "Transaction should be unique.");
        Entry entry = entries.get(0);
        entry.set(field, value);
        t_transaction.update(key, entry, cond);
    }

    /***** handle receipt *****/

    function insertReceipt(
        address payeeAddr,
        address payerAddr,
        uint256 id,
        uint256 paidAmount,
        uint256 oriAmount,
        uint256 createTime,
        uint256 deadline,
        uint256 receiptStatus,
        string bankSignature,
        string coreCompanySignature,
        string info,
        uint256 isFinance
    ) public {
        Table t_receipt = openTable(ReceiptTable);
        Entry entry = t_receipt.newEntry();
        entry.set("payerAddr", payerAddr);
        entry.set("id", id);
        entry.set("paidAmount", paidAmount);
        entry.set("oriAmount", oriAmount);
        entry.set("createTime", createTime);
        entry.set("deadline", deadline);
        entrt.set("receiptStatus", receiptStatus);
        entry.set("bankSignature", bankSignature);
        entry.set("coreCompanySignature", coreCompanySignature);
        entry.set("info", info);
        entry.set("isFinance", isFinance);
        t_receipt.insert(toString(payeeAddr), entry);
    }

    function findReceipt(string key, uint256 id) public {
        Table t_receipt = openTable(ReceiptTable);
        Condition cond = t_receipt.newCondition();
        cond.EQ("id", id);
        Entries entries = t_receipt.select(key, cond);
        require(entries.size() > 0, "Receipt should exist.");
        require(entries.size() < 2, "Receipt should be unique.");
        Entry entry = entries.get(0);
        receipt.payeeAddr = entry.getAddress("payeeAddr");
        receipt.payerAddr = entry.getAddress("payerAddr");
        receipt.id = entry.getUInt("id");
        receipt.paidAmount = entry.getUInt("paidAmount");
        receipt.oriAmount = entry.getUInt("oriAmount");
        receipt.createTime = entry.getUInt("createTime");
        receipt.deadline = entry.getUInt("deadline");
        receipt.receiptStatus = entry.getUInt("receiptStatus");
        receipt.bankSignature = entry.getString("bankSignature");
        receipt.coreCompanySignature = entry.getString("coreCompanySignature");
        receipt.info = entry.getString("info");
        receipt.isFinance = entry.getUInt("isFinance");
    }

    function updateReceiptUInt1(
        string key,
        uint256 id,
        string field,
        uint256 value
    ) private {
        Table t_receipt = openTable(ReceiptTable);
        Condition cond = t_receipt.newCondition();
        cond.EQ("id", id);
        Entries entries = t_receipt.select(key, cond);
        require(entries.size() > 0, "Receipt should exist.");
        require(entries.size() < 2, "Receipt should be unique.");
        Entry entry = entries.get(0);
        entry.set(field, value);
        if (field == "paidAmount" && value >= entry.getUInt("oriAmount")) {
            entry.set("receiptStatus", ReceiptStatus_settled);
        }
        t_receipt.update(key, entry, cond);
    }

    /***** register *****/

    /** 只有admin能认证bank */
    function registerBank(
        address senderAddr,
        address bankAddr,
        string name
    ) public {
        require(
            senderAddr == admin.addr,
            "Only administrator can register banks"
        );
        insertCompany(bankAddr, name, cType_bank, 0, 0);
    }

    /** 只有admin能认证第三方监管机构certifier */
    function registerCertifier(
        address senderAddr,
        address certifierAddr,
        string name
    ) public {
        require(
            senderAddr == admin.addr,
            "Only administrator can register certifiers"
        );
        insertCertifier(certifierAddr, name);
    }

    /** 只有certifier能认证公司（normal） */
    function registerCompany(
        address senderAddr,
        address companyAddr,
        string name
    ) public {
        // Only certifier can register certifiers.
        // Administrator can register itself to be a certifier.
        findCertifier(senderAddr);
        insertCompany(companyAddr, name, CompanyType_normal, 0, 0);
    }

    /** 只有certifier能将normal公司认证为core公司 */
    function registerCoreCompany(address senderAddr, address companyAddr)
        public
    {
        findCertifier(senderAddr);
        findCompany(companyAddr, false);
        require(
            company.cType != CompanyType_core,
            "This company is already a core company"
        );
        updateCompanyUInt1(companyAddr, "cType", CompanyType_core);
    }

    /***** credit的分发（授信）和 强制回收*****/

    /** admin将credit分发给bank */
    function creditDistributionToBank(
        address senderAddr,
        address bankAddr,
        uint256 amount
    ) public {
        require(
            senderAddr == admin.addr,
            "Only administrator can distribute credit to banks"
        );
        // bank
        findCompany(bankAddr, true);
        updateCompanyUInt1(
            bankAddr,
            "creditAmount",
            company.creditAmount + amount
        );
        // admin
        admin.outCredit += amount;
        admin.outCreditPerBank[bankAddr] += amount;
    }

    /** admin强制要求bank返回credit */
    function creditReturnFromBank(
        address senderAddr,
        address bankAddr,
        uint256 amount
    ) public {
        require(
            senderAddr == admin.addr,
            "Only administrator can force banks to return credit."
        );
        // bank
        findCompany(bankAddr, true);
        require(
            company.creditAmount >= amount,
            "The bank doesn't have enough credit points."
        );
        updateCompanyUInt1(
            bankAddr,
            "creditAmount",
            company.creditAmount - amount
        );
        // admin
        admin.outCredit -= amount;
        admin.outCreditPerBank[bankAddr] -= amount;
    }

    /** bank将credit分发给core company*/
    function creditDistributionToCore(
        address senderAddr, // bankAddr
        address coreAddr,
        uint256 amount
    ) public {
        findCompany(senderAddr, true);
        require(
            company.creditAmount >= amount,
            "Bank doesn't have enough credit."
        );
        uint256 bankCreditAmount = company.creditAmount;

        findCompany(coreAddr);
        require(
            company.cType == CompanyType_core,
            "Must distribute credit to core company."
        );

        updateCompanyUInt1(
            senderAddr,
            "creditAmount",
            bankCreditAmount - amount
        );
        updateCompanyUInt1(
            coreAddr,
            "creditAmount",
            company.creditAmount + amount
        );
    }

    /** bank强制要求core company返回credit */
    function creditReturnFromCore(
        address senderAddr, // bankAddr
        address coreAddr,
        uint256 amount
    ) public {
        findCompany(senderAddr, true);
        uint256 bankCreditAmount = company.creditAmount;
        findCompany(coreAddr);
        require(
            company.cType == CompanyType_core,
            "Must force credit return from core company."
        );
        require(
            company.creditAmount >= amount,
            "The company doesn't have enough credit points."
        );

        updateCompanyUInt1(
            senderAddr,
            "creditAmount",
            bankCreditAmount + amount
        );
        updateCompanyUInt1(
            coreAddr,
            "creditAmount",
            company.creditAmount + amount
        );
    }

    function _transactionRequest(
        address payerAddr,
        bool isPayerBank,
        address payeeAddr,
        bool isPayeeBank,
        uint256 amount,
        uint256 deadline,
        uint256 tMode,
        uint256 oriReceiptId,
        string memory info,
        string memory tType
    ) private {
        require(amount > 0, "Amount <= 0 is not allowed.");
        require(
            tMode == 0 || tMode == 1,
            "tMode should be 0 or 1: "
            "0 stands for making new receipt, "
            "1 stands for transfering origin receipt"
        );
        // payer
        findCompany(payerAddr, isPayerBank);
        string memory payerName = company.name;
        require(
            company.creditAmount >= amount,
            "Payer doesn't have enough credit points."
        );

        // payee
        findCompany(payeeAddr, isPayeeBank);

        if (tMode == TransactionMode_transfer) {
            findReceipt(payerAddr, oriReceiptId);
            require(
                receipt.oriAmount - receipt.paidAmount >= amount,
                "Not enough unpaid money in origin receipt."
            );
            require(
                receipt.deadline >= deadline,
                "Deadline of finance should >= deadline of oriReceipt."
            );
        } else {
            oriReceiptId = 0;
        }

        uint256 transactionId = uint256(keccak256(now));
        insertTransaction(
            payeeAddr,
            payerAddr,
            transactionId,
            amount,
            now,
            deadline,
            tMode,
            oriReceiptId,
            RequestStatus_sent,
            info,
            0
        );
        emit NewRequest(
            payeeAddr,
            company.name,
            payerAddr,
            payerName,
            amount,
            tType
        );
    }

    function _transactionRespond(
        address payeeAddr,
        bool isPayeeBank,
        address payerAddr,
        bool isPayerBank,
        uint256 transactionId,
        uint256 respond,
        string memory tType
    ) private {
        require(
            respond == 0 || respond == 1,
            "Respond is 0 or 1: "
            "0 stands for refusing, "
            "1 stands for accepting."
        );

        findTransaction(payeeAddr, transactionId);
        uint256 amount = transaction.amount;
        uint256 oriReceiptId = transaction.oriReceiptId;

        if (respond == 0) {
            updateTransactionUInt1(
                payeeAddr,
                transactionId,
                "requestStatus",
                RequestStatus_refused
            );
        } else {
            findCompany(payerAddr, isPayerBank);
            require(
                company.creditAmount >= amount,
                "Payer doesn't has enough credit points."
            );

            if (transaction.tMode == TransactionMode_transfer) {
                // split receipt
                findReceipt(payerAddr, oriReceiptId);
                require(
                    receipt.oriAmount - receipt.paidAmount >= amount,
                    "Not enough unpaid money in origin receipt."
                );
                updateReceiptUInt1(
                    payerAddr,
                    oriReceipt,
                    "oriAmount",
                    receipt.oriAmount - amount
                );
            }
            // payer
            findCompany(payerAddr, isPayerBank);
            string memory payerName = company.name;
            updateCompanyUInt1(
                payerAddr,
                "creditAmount",
                company.creditAmount - amount
            );
            // payee
            findCompany(payeeAddr, isPayeeBank);
            updateCompanyUInt1(
                payeeAddr,
                "creditAmount",
                company.creditAmount + amount
            );

            uint256 receiptId = uint256(keccak256(now));
            insertReceipt(
                payeeAddr,
                payerAddr,
                receiptId,
                0,
                amount,
                now,
                transaction.deadline,
                ReceiptStatus_paying,
                "bankSignature",
                "coreCompanySignature",
                transaction.info,
                0
            );
            updateTransactionUInt1(
                payeeAddr,
                transactionId,
                "requestStatus",
                RequestStatus_accepted
            );
        }
        emit NewRespond(
            payeeAddr,
            company.name,
            payerAddr,
            payerName,
            transactionId,
            amount,
            respond,
            tType
        );
    }

    function transactionRequestWithNewReceipt(
        address senderAddr,
        address payeeAddr,
        uint256 amount,
        uint256 deadline,
        string memory info
    ) public {
        _transactionRequest(
            senderAddr,
            false,
            payeeAddr,
            false,
            amount,
            deadline,
            0,
            0,
            info,
            "Transaction"
        );
    }

    function transactionRequestWithOldReceipt(
        address senderAddr,
        address payeeAddr,
        uint256 amount,
        uint256 deadline,
        uint256 oriReceiptId,
        string memory info
    ) public {
        _transactionRequest(
            senderAddr,
            false,
            payeeAddr,
            false,
            amount,
            deadline,
            1,
            oriReceiptId,
            info,
            "Transaction"
        );
    }

    function financeRequest(
        address senderAddr,
        address payeeAddr,
        uint256 amount,
        uint256 deadline,
        uint256 oriReceiptId,
        string memory info
    ) public {
        _transactionRequest(
            senderAddr,
            false,
            payeeAddr,
            true,
            amount,
            deadline,
            1,
            oriReceiptId,
            info,
            "Finance"
        );
    }

    function transactionRespond(
        address senderAddr,
        address payerAddr,
        uint256 transactionId,
        uint256 respond
    ) public {
        _transactionRespond(
            senderAddr,
            false,
            payerAddr,
            false,
            transactionId,
            respond,
            "Transaction"
        );
    }

    function financeRespond(
        address senderAddr,
        address payerAddr,
        uint256 financeId,
        uint256 respond
    ) public {
        _transactionRespond(
            senderAddr,
            true,
            payerAddr,
            false,
            financeId,
            respond,
            "Finance"
        );
    }

    function depositCash(
        address senderAddr, // bankAddr
        address companyAddr,
        uint256 amount
    ) public {
        findCompany(senderAddr, true);
        findCompany(companyAddr, false);
        updateCompanyUInt1(
            companyAddr,
            "cashAmount",
            company.cashAmount + amount
        );
    }

    function withdrawCash(
        address senderAddr, // bankAddr
        address companyAddr,
        uint256 amount
    ) public {
        findCompany(sender, true);
        findCompany(companyAddr, false);
        require(
            company.cashAmount >= amount,
            "Company doesn't have enough cash."
        );
        updateCompanyUInt1(
            companyAddr,
            "cashAmount",
            company.cashAmount - amount
        );
    }

    function _payReceipt(
        address payerAddr,
        address payeeAddr,
        bool isPayeeBank,
        string receiptId,
        uint256 amount
    ) private {
        findCompany(payerAddr, false);
        uint256 payerCashAmount = company.cashAmount;
        uint256 payerCreditAmount = company.creditAmount;
        require(
            payer.cashAmount >= amount,
            "Payer doesn't have enough cash to pay."
        );
        findCompany(payeeAddr, isPayeeBank);
        require(
            company.credit >= amount,
            "Payee doesn't have enough credit to return."
        );
        findReceipt(payeeAddr, receiptId);
        require(receipt.payeeAddr == payeeAddr, "Wrong payee.");

        updateCompanyUInt2(
            payerAddr,
            "cashAmount",
            payerCashAmount - amount,
            "creditAmount",
            payerCreditAmount + amount
        );
        updateCompanyUInt2(
            payeeAddr,
            "cashAmount",
            payee.cashAmount + amount,
            "creditAmount",
            payee.creditAmount - amount
        );
        updateReceiptUInt1(
            payeeAddr,
            receiptId,
            "paidAmount",
            receipt.paidAmount + amount
        );
    }

    function payReceipt(
        address payerAddr,
        address payeeAddr,
        uint256 receiptId,
        uint256 amount,
        bool isFinance
    ) public {
        _payReceipt(senderAddr, payeeAddr, isFinance, receiptId, amount);
    }
}
