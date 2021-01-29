# SupplyChain链端

该项目是我们小组实现的供应链系统的链端智能合约。

### 主要功能
- 角色认证
- 管理员宏观调控系统总借贷
- 银行授信核心企业
- 交易
- 融资（贷款）
- 还款：交易、融资

### 辅助功能
- 数字签名
- 电子钱包

### API:

```solidity
    // get all
    function getAllCertifier() public returns (address[] memory) 
    function getAllCompany() public returns (address[] memory) 
    function getAllNormalCompany() public returns (address[] memory) 
    function getAllCoreCompany() public returns (address[] memory) 
    function getAllBank() public returns (address[] memory) 
    // 获取某个地址的所有角色
    function getAllRole(address addr) public view returns (string) 
    
    // get 
    function getAdmin(address addr) public view returns (Administrator memory) 
    function getCertifier(address addr) public returns (Certifier memory) 
    function getBank(address addr) public returns (Company memory) 
    function getCompany(address addr) public returns (Company memory) 
    function getNormalCompany(address addr) public returns (Company memory) 
    function getCoreCompany(address addr) public returns (Company memory) 
    function getTransaction(address payeeAddr, int256 id)
    function getReceipt(address payeeAddr, int256 id)

    // 查询某公司为收款方的所有交易(即该公司为交易请求的接收者)
    function getAllTransactionRequest(address addr)
    // 查询某银行为收款方的所有贷款(即该银行为贷款请求的接收者
    function getAllFinanceRequest(address addr)

    // 查询所有以某公司为收款方的未还清的交易账单
    function getAllUnsettedReceipt(address addr)
    // 查询所有以某银行为收款方的未还清贷款
    function getAllUnsettedFinance(address addr)

    // 查询所有以某公司为付款方的未还清的交易账单
    function getAllUnpaidReceipt(address addr)
    // 查询所有以某公司为付款方的未还清贷款
    function getAllUnpaidFinance(address addr)

    // 查询管理员分发的credit总数
    function getAdminOutCredit() public view returns (uint256) 
    // 查询管理员分给某一银行的credit总数
    function getAdminOutCredit2Bank(address bankAddr)

    // 注册
    function registerBank
    function registerCertifier
    function registerCompany
    function registerCoreCompany(address senderAddr, address companyAddr)

    // admin将credit分发给bank
    function creditDistributionToBank
    // admin强制要求bank返回credit
    function creditReturnFromBank
    // bank将credit分发给core company
    function creditDistributionToCore
    // bank强制要求core company返回credit
    function creditReturnFromCore
    
    // 交易 和 贷款 请求、响应
    function transactionRequestWithNewReceipt
    function transactionRequestWithOldReceipt
    function financeRequest
    function transactionRespond
    function financeRespond

    // 支付
    function depositCash( // 存钱
    function withdrawCash( // 取钱
    function payReceipt( // 还账单
