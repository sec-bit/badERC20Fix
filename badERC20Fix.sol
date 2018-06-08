pragma solidity ^0.4.24;

contract TokenStd {
    function transfer(address _to, uint256 _value) public returns (bool success) {
        return true;
    }
}

contract TokenNoStd {
    function transfer(address _to, uint256 _value) public {
    }
}

library ERC20AsmTransfer {    
    function asmTransfer(address _erc20Addr, address _to, uint256 _value) internal returns (bool result) {

        // Must be a contract addr first!
        assembly {
            if iszero(extcodesize(_erc20Addr)) { revert(0, 0) }
        }
        
        // call return false when something wrong
        require(_erc20Addr.call(bytes4(keccak256("transfer(address,uint256)")), _to, _value));
        
        // handle returndata
        assembly {
            switch returndatasize()
            case 0 { // not a std erc20
                result := 1
            }
            case 32 { // std erc20
                returndatacopy(0, 0, 32)
                result := mload(0)
            }
            default { // anything else, should revert for safety
                revert(0, 0)
            }
        }
        return result;
    }
}

interface ERC20 {
    function transfer(address _to, uint256 _value) returns (bool success);
}

contract TestERC20AsmTransfer {
    using ERC20AsmTransfer for ERC20;
    function dexTest(address _token, address _to, uint _amount) public {
        require(ERC20(_token).asmTransfer(_to, _amount));
    }
}

