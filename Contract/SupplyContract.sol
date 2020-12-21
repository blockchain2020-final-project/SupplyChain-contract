pragma solidity ^0.4.25;

contract SupplyContract {
    enum CompanyType {core, normal}

    struct Company {
        address addr;
        string name;
        CompanyType cType;
        uint256 inCredit; // 获得的尚未返还的信用凭证总量
        uint256 outCredit; // 签发的尚未收回的信用凭证总量
    }

    struct Bank {
        address addr;
        string name;
        uint256 inCredit;
        uint256 outCredit;
    }

    struct Administrator {
        address addr;
        uint256 outCredit;
        mapping(address => uint256) outCreditPerBank;
    }

    // trusted third-party certifier
    struct Certifier {
        address addr;
        string name;
    }

    struct Transaction {
        uint256 id;
        address seller;
        address buyer;
        uint256 amount;
        uint256 createTime;
    }

    enum PaymentStatus{notSettled, requestSent, requestAccepted, requestRefused, settled}

    struct Receipt {
        uint256 id;
        address debtor;
        address debtee;
        uint256 curAmount;
        uint256 oriAmount;
        uint256 createTime;
        uint256 deadline;
        PaymentStatus status;
        string bankSignature;
        string coreCompanySignature;
    }

    struct Fraction {
        int256 numerator;
        int256 denominator;
    }

    struct Loan{
        uint256 id;
        address debtor;
        address debtee;
        uint256 paidAmount;
        uint256 principleAmount;
        uint256 createTime;
        uint256 deadline;
        Fraction annualInterestRate;
        PaymentStatus status;
    }

    

}
