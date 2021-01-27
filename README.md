# SupplyChain

A blockchain application based on FISCO-BCOS.

现状：这个合约刚写完就push上来了，不能运行ing

修改：
- Bank 和 Company 合并成 Company，用cType区分：cType_normal, cType_core, cType_bank
- Finance 直接用 Transaction 实现，但是函数实现分成了不同的接口，所以没太大影响
- Transaction 和 Receipt 加了 info、isFinance
- 所有的buyer、debtee用payer（付款人）代替， 所有的seller、debtor用payee（收款人）代替
