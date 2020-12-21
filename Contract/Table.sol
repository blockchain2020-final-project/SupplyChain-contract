pragma solidity ^0.4.24;

contract TableFactory {
    function openTable(string) public constant returns (Table); // 打开表

    function createTable(
        string,
        string,
        string
    ) public returns (int256); // 创建表
}

// 查询条件
contract Condition {
    //等于
    function EQ(string, int256) public;

    function EQ(string, string) public;

    //不等于
    function NE(string, int256) public;

    function NE(string, string) public;

    //大于
    function GT(string, int256) public;

    //大于或等于
    function GE(string, int256) public;

    //小于
    function LT(string, int256) public;

    //小于或等于
    function LE(string, int256) public;

    //限制返回记录条数
    function limit(int256) public;

    function limit(int256, int256) public;
}

// 单条数据记录
contract Entry {
    function getInt(string) public constant returns (int256);

    function getAddress(string) public constant returns (address);

    function getBytes64(string) public constant returns (bytes1[64]);

    function getBytes32(string) public constant returns (bytes32);

    function getString(string) public constant returns (string);

    function set(string, int256) public;

    function set(string, string) public;

    function set(string, address) public;
}

// 数据记录集
contract Entries {
    function get(int256) public constant returns (Entry);

    function size() public constant returns (int256);
}

// Table主类
contract Table {
    // 查询接口
    function select(string, Condition) public constant returns (Entries);

    // 插入接口
    function insert(string, Entry) public returns (int256);

    // 更新接口
    function update(
        string,
        Entry,
        Condition
    ) public returns (int256);

    // 删除接口
    function remove(string, Condition) public returns (int256);

    function newEntry() public constant returns (Entry);

    function newCondition() public constant returns (Condition);
}
