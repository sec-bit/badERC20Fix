# badERC20Fix

大量 ERC20 Token 合约没有遵守 EIP20 [规范](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md)，这些非标准合约将会对 DAPP 的开发生态造成严重影响。

特别是自从今年4月17日，以太坊的智能合约语言编译器 Solidity 升级至 0.4.22 版本后，编译产生的合约代码将会[无法兼容](https://github.com/ethereum/solidity/issues/4116)一些非标准的智能合约，这会对 DAPP 开发带来很大的[困扰](https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca)。

## 标准代码

```js
contract TokenStd {
    function transfer(address _to, uint256 _value) public returns (bool success) {
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        return true;
    } 
    function approve(address _spender, uint256 _value) public returns (bool success) {
        return true;
    }
}
```

## 不符合标准的代码

```js
// NEVER USE THIS
contract TokenNoStd {
    function transfer(address _to, uint256 _value) public {
    }
    function transferFrom(address _from, address _to, uint256 _value) public {
    }
    function approve(address _spender, uint256 _value) public {
    }
}
```

## 影响对象

- 去中心化交易所(DEX)
- 使用 ERC20 Token 的 DAPP

## 影响后果

- 一些非标准 Token 可能无法正常完成交易/转账

## 影响的 ERC20 Token 数量估算

根据 SECBIT（安比）实验室[不完全统计](https://medium.com/loopring-chinese/%E6%95%B0%E5%8D%83%E4%BB%A5%E5%A4%AA%E5%9D%8A%E4%BB%A3%E5%B8%81%E5%90%88%E7%BA%A6%E4%B8%8D%E5%85%BC%E5%AE%B9%E9%97%AE%E9%A2%98%E6%B5%AE%E5%87%BA%E6%B0%B4%E9%9D%A2-%E4%B8%A5%E9%87%8D%E5%BD%B1%E5%93%8Ddapp%E7%94%9F%E6%80%81-a6a9432b1796)，存在这种不兼容问题的 ERC20 合约**至少 2603 份**。

## 问题代码来源

问题代码主要受权威模板影响：

- openzeppelin-solidity 2017 年 3 月 -- 2017 年 7 月间的 StandardToken [实现](https://github.com/OpenZeppelin/openzeppelin-solidity/blob/52120a8c428de5e34f157b7eaed16d38f3029e66/contracts/token/BasicToken.sol#L16-L20)（源码公开可验证的已知 292 份）
- 以太坊官网提供的 Token [合约模板](https://github.com/ethereum/ethereum-org/pull/859/commits/3b392422ec7ed7ffc2c94babdc851ec3130ffc12)（已知 1703 份）

其中：

- 受 openzeppelin 影响的合约不兼容函数包括 `transfer`、`transferFrom` 以及 `approve`
- 受 ethereum-org 影响的合约不兼容函数包括 `transfer`

受以太坊官网模版代码影响的代码数量巨大，已提交 PRs [[1]](https://github.com/ethereum/ethereum-org/pull/859) [[2]](https://github.com/ethereum/ethereum-org/pull/862) [[3]](https://github.com/ethereum/ethereum-org/pull/863) 修复并被合并。

## 面向 DApp 和 DEX 的解决方案

call 方法手动直接调用 transfer()函数，并使用内联 assembly code 手动获取 returndatasize() 进行判断
 
- 如果为 0，则表明被调用 ERC20 合约正常执行完毕，但没有返回值，即转账成功
 
- 如果为 32，则表明ERC20合约符合标准，直接进行 returndatacopy() 操作，调用 mload() 拿到返回值进行判断即可
 
- 如果为其他值则 revert

具体实现可参考本 repo 中的[代码](badERC20Fix.sol)，欢迎测试讨论。

此外，[Lukas Cremer](https://gist.github.com/lukas-berlin/0f7005301f29e3881ad15449e68c2486#file-gistfile1-txt)和[BrendanChou](https://gist.github.com/BrendanChou/88a2eeb80947ff00bcf58ffdafeaeb61)的修复方案直接利用了非标准的`function transfer(address to, uint value) external`接口来进行函数调用。

我们认为应该尽量避免此种写法，社区理应推广符合 ERC20 标准的接口。
