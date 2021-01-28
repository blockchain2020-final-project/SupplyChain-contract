pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

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
        int256 id;
        uint256 amount;
        uint256 createTime;
        uint256 deadline;
        uint256 tMode;
        int256 oriReceiptId;
        uint256 requestStatus;
        string info;
        uint256 isFinance;
    }

    struct Receipt {
        address payeeAddr; // payeeAddr
        address payerAddr; // payerAddr
        int256 id;
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
    uint256 certCount;
    uint256 normalCount;
    uint256 coreCount;
    uint256 bankCount;
    mapping(uint256 => address) addrs;
    mapping(address => bool) isAddrAppeared;
    mapping(address => bool) isCertifier;
    mapping(address => bool) isCTypeNormal;
    mapping(address => bool) isCTypeCore;
    mapping(address => bool) isCTypeBank;
    mapping(address => uint256) outCreditPerBank;

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
        int256 id,
        uint256 amount,
        string rType
    );
    event NewRespond(
        address payeeAddr, // 收款人
        string payeeName,
        address payerAddr, // 付款人
        string payerName,
        int256 id,
        uint256 amount,
        uint256 respond,
        string rType
    );
    event NewTransaction(
        address payeeAddr, // 收款人
        address payerAddr, // 付款人
        int256 id,
        uint256 amount,
        string tType
    );
    event NewReceipt(
        address payeeAddr, // 收款人
        address payerAddr, // 付款人
        int256 id,
        uint256 oriAmount,
        string tType
    );
    event UpdateReceipt(
        address payeeAddr, // 收款人
        address payerAddr, // 付款人
        int256 id,
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

    function toString(address x) private pure returns (string) {
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

    function equal(string a, string b) private pure returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(bytes(a)) == keccak256(bytes(b));
        }
    }

    constructor(address adminAddr, string suffix) public {
        // require(
        //     msg.sender == adminAddr,
        //     "Only administrator can deploy this contract."
        // );
        admin.addr = adminAddr;
        addrs[0] = adminAddr;
        isAddrAppeared[adminAddr] = true;
        emit NewRegistration(adminAddr, "admin", "Administrator");

        addrCount = 1;
        certCount = 0;
        normalCount = 0;
        coreCount = 0;
        bankCount = 0;

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

    function getAllCertifier() public returns (Certifier[] memory) {
        Certifier[] memory ret = new Certifier[](certCount);
        uint256 cnt = 0;
        for (uint256 i = 0; i < addrCount; i++) {
            if (isCertifier[addrs[i]]) {
                findCertifier(addrs[i]);
                ret[cnt++] = certifier;
            }
        }
        return ret;
    }

    function __getAllCompany(uint256 flag, uint256 count)
        private
        returns (Company[] memory)
    {
        Company[] memory ret = new Company[](count);
        uint256 cnt = 0;
        for (uint256 i = 0; i < addrCount; i++) {
            if (
                (flag == 0 &&
                    (isCTypeNormal[addrs[i]] || isCTypeCore[addrs[i]])) ||
                (flag == 1 && isCTypeNormal[addrs[i]]) ||
                (flag == 2 && isCTypeCore[addrs[i]])
            ) {
                findCompany(addrs[i], false);
            } else if (flag == 3 && isCTypeBank[addrs[i]]) {
                findCompany(addrs[i], true);
            }
            Company storage tmp = company;
            ret[cnt++] = tmp;
        }
        return ret;
    }

    function getAllCompany() public returns (Company[] memory) {
        return __getAllCompany(0, normalCount + coreCount);
    }

    function getAllNormalCompany() public returns (Company[] memory) {
        return __getAllCompany(1, normalCount);
    }

    function getAllCoreCompany() public returns (Company[] memory) {
        return __getAllCompany(2, coreCount);
    }

    function getAllBank() public returns (Company[] memory) {
        return __getAllCompany(3, bankCount);
    }

    function getAllRole(address addr) public view returns (string) {
        string memory result = "";

        if (addr == admin.addr) {
            result = concat(result, "Administrator ");
        }
        if (isCTypeBank[addr] == true) {
            result = concat(result, "Bank ");
        }
        if (isCertifier[addr] == true) {
            result = concat(result, "Certifier ");
        }
        if (isCTypeNormal[addr] == true) {
            result = concat(result, "Company(Normal) ");
        }
        if (isCTypeCore[addr] == true) {
            result = concat(result, "Company(Core) ");
        }
        return result;
    }

    function getAdmin(address addr) public view returns (Administrator memory) {
        require(addr == admin.addr, "The address isn't admin.");
        return admin;
    }

    function getCertifier(address addr) public returns (Certifier memory) {
        findCertifier(addr);
        return certifier;
    }

    function getBank(address addr) public returns (Company memory) {
        findCompany(addr, true);
        return company;
    }

    function getCompany(address addr) public returns (Company memory) {
        findCompany(addr, false);
        return company;
    }

    function getNormalCompany(address addr) public returns (Company memory) {
        findCompany(addr, false);
        require(
            company.cType == cType_normal,
            "The address is not normal company."
        );
        return company;
    }

    function getCoreCompany(address addr) public returns (Company memory) {
        findCompany(addr, false);
        require(
            company.cType == cType_core,
            "The address is not core company."
        );
        return company;
    }

    function __getAllTransactionRequest(address addr)
        private
        returns (Transaction[] memory)
    {
        Table t_transaction = openTable(TransactionTable);
        Condition cond = t_transaction.newCondition();
        Entries entries = t_transaction.select(toString(addr), cond);
        uint256 size = uint256(entries.size());
        Transaction[] memory ret = new Transaction[](size);
        Entry entry;
        for (uint256 i = 0; i < size; i++) {
            entry = entries.get(int256(i));
            transaction.payeeAddr = entry.getAddress("payeeAddr");
            transaction.payerAddr = entry.getAddress("payerAddr");
            transaction.id = entry.getInt("id");
            transaction.amount = entry.getUInt("amount");
            transaction.createTime = entry.getUInt("createTime");
            transaction.deadline = entry.getUInt("deadline");
            transaction.tMode = entry.getUInt("tMode");
            transaction.oriReceiptId = entry.getInt("oriReceiptId");
            transaction.requestStatus = entry.getUInt("requestStatus");
            transaction.info = entry.getString("info");
            transaction.isFinance = entry.getUInt("isFinance");
            ret[i] = transaction;
        }
        return ret;
    }

    // 查询某公司为收款方的所有交易(即该公司为交易请求的接收者)
    function getAllTransactionRequest(address addr)
        public
        returns (Transaction[] memory)
    {
        findCompany(addr, false);
        return __getAllTransactionRequest(addr);
    }

    // 查询某银行为收款方的所有贷款(即该银行为贷款请求的接收者)
    function getAllFinanceRequest(address addr)
        public
        returns (Transaction[] memory)
    {
        findCompany(addr, true);
        return __getAllTransactionRequest(addr);
    }

    function __getAllUnsettedReceipt(address addr, bool isFinance)
        private
        returns (Receipt[] memory)
    {
        findCompany(addr, isFinance);

        Table t_receipt = openTable(ReceiptTable);
        Condition cond = t_receipt.newCondition();
        if (isFinance == true) {
            cond.EQ("isFinance", 1);
        } else {
            cond.EQ("isFinance", 0);
        }
        cond.EQ("receiptStatus", int256(ReceiptStatus_paying));
        Entries entries = t_receipt.select(toString(addr), cond);

        uint256 size = uint256(entries.size());
        Receipt[] memory ret = new Receipt[](size);

        Entry entry;
        for (uint256 i = 0; i < size; i++) {
            entry = entries.get(int256(i));
            receipt.payeeAddr = entry.getAddress("payeeAddr");
            receipt.payerAddr = entry.getAddress("payerAddr");
            receipt.id = entry.getInt("id");
            receipt.paidAmount = entry.getUInt("paidAmount");
            receipt.oriAmount = entry.getUInt("oriAmount");
            receipt.createTime = entry.getUInt("createTime");
            receipt.deadline = entry.getUInt("deadline");
            receipt.receiptStatus = entry.getUInt("receiptStatus");
            receipt.bankSignature = entry.getString("bankSignature");
            receipt.coreCompanySignature = entry.getString(
                "coreCompanySignature"
            );
            receipt.info = entry.getString("info");
            receipt.isFinance = entry.getUInt("isFinance");

            ret[i] = receipt;
        }
        return ret;
    }

    // 查询所有以某公司为收款方的未还清的交易账单
    function getAllUnsettedReceipt(address addr)
        public
        returns (Receipt[] memory)
    {
        return __getAllUnsettedReceipt(addr, false);
    }

    // 查询所有以某银行为收款方的未还清贷款
    function getAllUnsettedFinance(address addr)
        public
        returns (Receipt[] memory)
    {
        return __getAllUnsettedReceipt(addr, true);
    }

    /** database insert and update */

    function openTable(string tableName) private view returns (Table) {
        TableFactory tf = TableFactory(0x1001);
        return tf.openTable(tableName);
    }

    // function getAdmin() public view returns (address) {
    //     return admin.addr;
    // }

    /** 查询管理员分发的credit总数 */
    function getAdminOutCredit() public view returns (uint256) {
        return admin.outCredit;
    }

    /** 查询管理员分给某一银行的credit总数 */
    function getAdminOutCredit2Bank(address bankAddr)
        public
        view
        returns (uint256)
    {
        return outCreditPerBank[bankAddr];
    }

    /***** handle certifier *****/

    function insertCertifier(address addr, string name) private {
        Table t_certifier = openTable(CertifierTable);
        Entries entries =
            t_certifier.select(toString(addr), t_certifier.newCondition());
        require(entries.size() == 0, "Certifier already exists.");
        Entry entry = t_certifier.newEntry();
        entry.set("name", name);
        t_certifier.insert(toString(addr), entry);
        if (isAddrAppeared[addr] == false) {
            addrs[addrCount++] = addr;
            isAddrAppeared[addr] = true;
        }
        isCertifier[addr] = true;
        certCount++;
        emit NewRegistration(addr, name, "Certifier");
    }

    function findCertifier(address addr) private {
        Table t_certifier = openTable(CertifierTable);
        Entries entries =
            t_certifier.select(toString(addr), t_certifier.newCondition());
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
        Entries entries =
            t_company.select(toString(addr), t_company.newCondition());
        require(entries.size() == 0, "Company or bank already exists.");
        Entry entry = t_company.newEntry();
        entry.set("name", name);
        entry.set("cType", cType);
        entry.set("creditAmount", creditAmount);
        entry.set("cashAmount", cashAmount);
        t_company.insert(toString(addr), entry);
        string memory rType;

        if (isAddrAppeared[addr] == false) {
            addrs[addrCount++] = addr;
            isAddrAppeared[addr] = true;
        }

        if (cType == cType_bank) {
            rType = "Bank";
            isCTypeBank[addr] = true;
            bankCount++;
        } else {
            rType = "Company(Normal)";
            isCTypeNormal[addr] = true;
            normalCount++;
        }
        emit NewRegistration(addr, name, rType);
    }

    function getCTypeString(uint256 cType) private returns (string) {
        if (cType == cType_bank) return "Bank";
        if (cType == cType_core) return "Company(Core)";
        if (cType == cType_normal) return "Company(Normal)";
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

        if (equal(field, "cType") && value == cType_core) {
            isCTypeNormal[addr] = false;
            normalCount--;
            isCTypeCore[addr] = true;
            coreCount++;
            emit NewRegistration(
                addr,
                entry.getString("name"),
                "Company(Core)"
            );
        } else {
            emit UpdateCompany(
                addr,
                entry.getString("name"),
                field,
                value,
                getCTypeString(entry.getUInt("cType"))
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
            cond.EQ("cType", int256(cType_bank));
        } else {
            cond.NE("cType", int256(cType_bank));
        }
        Entries entries = t_company.select(toString(addr), cond);
        // emit find_debug(CompanyTable, addr, entries.size());
        require(entries.size() > 0, "Company or bank should exist.");
        require(entries.size() < 2, "Company or bank should be unique.");
        Entry entry = entries.get(0);
        company.addr = addr;
        company.name = entry.getString("name");
        company.cType = entry.getUInt("cType");
        company.creditAmount = entry.getUInt("creditAmount");
        company.cashAmount = entry.getUInt("cashAmount");
    }

    /** 查询公司的type, credit余额, cash余额 */
    // function queryCompanyField(address addr, string field)
    //     public
    //     returns (uint256)
    // {
    //     require(
    //         (equal(field, "cType") ||
    //             equal(field, "creditAmount") ||
    //             equal(field, "cashAmount")),
    //         "Field should be cType, creditAmount or cashAmount."
    //     );
    //     findCompany(addr, false);
    //     if (field == "cType") return company.cType;
    //     if (field == "creditAmount") return company.creditAmount;
    //     return company.cashAmount;
    // }

    /***** handle transaction *****/

    function getTTypeString(uint256 isFinance) private returns (string) {
        if (isFinance == 1) return "Finance";
        return "Transaction";
    }

    function insertTransaction(
        address payeeAddr,
        address payerAddr,
        int256 id,
        uint256 amount,
        uint256 createTime,
        uint256 deadline,
        uint256 tMode,
        int256 oriReceiptId,
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
        emit NewTransaction(
            payeeAddr,
            payerAddr,
            id,
            amount,
            getTTypeString(isFinance)
        );
    }

    function findTransaction(string key, int256 id) private {
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
        transaction.oriReceiptId = entry.getInt("oriReceiptId");
        transaction.requestStatus = entry.getUInt("requestStatus");
        transaction.info = entry.getString("info");
        transaction.isFinance = entry.getUInt("isFinance");
    }

    function updateTransactionUInt1(
        string key,
        int256 id,
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
        int256 id,
        uint256 paidAmount,
        uint256 oriAmount,
        uint256 createTime,
        uint256 deadline,
        uint256 receiptStatus,
        string bankSignature,
        string coreCompanySignature,
        string info,
        uint256 isFinance
    ) private {
        Table t_receipt = openTable(ReceiptTable);
        Entry entry = t_receipt.newEntry();
        entry.set("payerAddr", payerAddr);
        entry.set("id", id);
        entry.set("paidAmount", paidAmount);
        entry.set("oriAmount", oriAmount);
        entry.set("createTime", createTime);
        entry.set("deadline", deadline);
        entry.set("receiptStatus", receiptStatus);
        entry.set("bankSignature", bankSignature);
        entry.set("coreCompanySignature", coreCompanySignature);
        entry.set("info", info);
        entry.set("isFinance", isFinance);
        string memory key = toString(payeeAddr);
        t_receipt.insert(key, entry);

        emit NewReceipt(
            payeeAddr,
            payerAddr,
            id,
            oriAmount,
            getTTypeString(isFinance)
        );
    }

    function findReceipt(string key, int256 id) private {
        Table t_receipt = openTable(ReceiptTable);
        Condition cond = t_receipt.newCondition();
        cond.EQ("id", id);
        Entries entries = t_receipt.select(key, cond);
        require(entries.size() > 0, "Receipt should exist.");
        require(entries.size() < 2, "Receipt should be unique.");
        Entry entry = entries.get(0);
        receipt.payeeAddr = entry.getAddress("payeeAddr");
        receipt.payerAddr = entry.getAddress("payerAddr");
        receipt.id = entry.getInt("id");
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
        int256 id,
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
        if (equal(field, "paidAmount") && value >= entry.getUInt("oriAmount")) {
            entry.set("receiptStatus", ReceiptStatus_settled);
        }
        t_receipt.update(key, entry, cond);
        emit UpdateReceipt(
            entry.getAddress("payeeAddr"),
            entry.getAddress("payerAddr"),
            id,
            entry.getUInt("paidAmount"),
            entry.getUInt("oriAmount"),
            getTTypeString(entry.getUInt("isFinance"))
        );
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
        insertCompany(companyAddr, name, cType_normal, 0, 0);
    }

    /** 只有certifier能将normal公司认证为core公司 */
    function registerCoreCompany(address senderAddr, address companyAddr)
        public
    {
        findCertifier(senderAddr);
        findCompany(companyAddr, false);
        require(
            company.cType != cType_core,
            "This company is already a core company"
        );
        updateCompanyUInt1(companyAddr, "cType", cType_core);
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
        outCreditPerBank[bankAddr] += amount;
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
        outCreditPerBank[bankAddr] -= amount;
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

        findCompany(coreAddr, false);
        require(
            company.cType == cType_core,
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
        findCompany(coreAddr, false);
        require(
            company.cType == cType_core,
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
            company.creditAmount - amount
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
        int256 oriReceiptId,
        string memory info,
        string memory tType
    ) private {
        require(amount > 0, "Amount <= 0 is not allowed.");
        require(
            tMode == 0 || tMode == 1,
            "tMode should be 0 or 1: 0 stands for making new receipt, 1 stands for transfering origin receipt"
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
        if (isPayeeBank == true) {
            require(
                company.cashAmount >= amount,
                "Bank doesn't have enough cash."
            );
        }

        if (tMode == TransactionMode_transfer) {
            findReceipt(toString(payerAddr), oriReceiptId);
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

        int256 transactionId = int256(keccak256(abi.encodePacked(now)));
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
            transactionId,
            amount,
            tType
        );
    }

    function _transactionRespond(
        address payeeAddr, // hub
        bool isPayeeBank,
        address payerAddr, // bank
        bool isPayerBank,
        int256 transactionId,
        uint256 respond,
        string memory tType
    ) private {
        require(
            respond == 0 || respond == 1,
            "Respond is 0 or 1: 0 stands for refusing, 1 stands for accepting."
        );

        findTransaction(toString(payeeAddr), transactionId);
        uint256 amount = transaction.amount;
        int256 oriReceiptId = transaction.oriReceiptId;

        findCompany(payeeAddr, isPayeeBank);
        if (isPayeeBank == true) {
            require(
                company.cashAmount >= amount,
                "Bank doesn't have enough cash."
            );
        }

        if (respond == 0) {
            updateTransactionUInt1(
                toString(payeeAddr),
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

            address newReceiptPayerAddr;
            // address newReceiptPayeeAddr;
            if (transaction.tMode == TransactionMode_transfer) {
                // split receipt
                findReceipt(toString(payerAddr), oriReceiptId);
                require(
                    receipt.oriAmount - receipt.paidAmount >= amount,
                    "Not enough unpaid money in origin receipt."
                );
                updateReceiptUInt1(
                    toString(payerAddr),
                    oriReceiptId,
                    "oriAmount",
                    receipt.oriAmount - amount
                );
                newReceiptPayerAddr = receipt.payerAddr;
            } else {
                // new receipt
                newReceiptPayerAddr = payerAddr;
            }
            // payer
            findCompany(payerAddr, isPayerBank);
            string memory payerName = company.name;
            if (isPayeeBank == false) {
                updateCompanyUInt1(
                    payerAddr,
                    "creditAmount",
                    company.creditAmount - amount
                );
            } else {
                updateCompanyUInt2(
                    payerAddr,
                    "creditAmount",
                    company.creditAmount - amount,
                    "cashAmount",
                    company.cashAmount + amount
                );
            }

            // payee
            findCompany(payeeAddr, isPayeeBank);
            if (isPayeeBank == false) {
                updateCompanyUInt1(
                    payeeAddr,
                    "creditAmount",
                    company.creditAmount + amount
                );
            } else {
                updateCompanyUInt2(
                    payeeAddr,
                    "creditAmount",
                    company.creditAmount + amount,
                    "cashAmount",
                    company.cashAmount - amount
                );
            }

            int256 receiptId = int256(keccak256(abi.encodePacked(now)));
            insertReceipt(
                payeeAddr,
                newReceiptPayerAddr,
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
                toString(payeeAddr),
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
        int256 oriReceiptId,
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
        int256 oriReceiptId,
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
        int256 transactionId,
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
        int256 financeId,
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

    /** admin才能同意bank存钱；bank才能同意company存钱 */
    function depositCash(
        address senderAddr,
        address addr,
        uint256 amount
    ) public {
        if (isCTypeBank[addr] == true) {
            require(
                senderAddr == admin.addr,
                "Only admin can deposit cash to bank."
            );
            findCompany(addr, true); // bank
        } else {
            findCompany(senderAddr, true); // bank
            findCompany(addr, false); // company
        }
        updateCompanyUInt1(addr, "cashAmount", company.cashAmount + amount);
    }

    /** admin才能同意bank取钱；bank才能同意company取钱 */
    function withdrawCash(
        address senderAddr, // admin or bank
        address addr, // bank or company
        uint256 amount
    ) public {
        if (isCTypeBank[addr] == true) {
            require(
                senderAddr == admin.addr,
                "Only admin can deposit cash to bank."
            );
            findCompany(addr, true); // bank
        } else {
            findCompany(senderAddr, true); // bank
            findCompany(addr, false); // company
        }
        require(company.cashAmount >= amount, "Doesn't have enough cash.");
        updateCompanyUInt1(addr, "cashAmount", company.cashAmount - amount);
    }

    function __payReceipt(
        address payerAddr,
        address payeeAddr,
        bool isPayeeBank,
        int256 receiptId,
        uint256 amount
    ) private {
        findCompany(payerAddr, false);
        uint256 payerCashAmount = company.cashAmount;
        uint256 payerCreditAmount = company.creditAmount;
        require(
            company.cashAmount >= amount,
            "Payer doesn't have enough cash to pay."
        );
        findCompany(payeeAddr, isPayeeBank);
        require(
            company.creditAmount >= amount,
            "Payee doesn't have enough credit to return."
        );
        findReceipt(toString(payeeAddr), receiptId);
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
            company.cashAmount + amount,
            "creditAmount",
            company.creditAmount - amount
        );
        updateReceiptUInt1(
            toString(payeeAddr),
            receiptId,
            "paidAmount",
            receipt.paidAmount + amount
        );
    }

    function payReceipt(
        address senderAddr,
        address payeeAddr,
        int256 receiptId,
        uint256 amount,
        bool isFinance
    ) public {
        __payReceipt(senderAddr, payeeAddr, isFinance, receiptId, amount);
    }
}
