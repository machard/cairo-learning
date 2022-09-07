# https://github.com/aave-starknet-project/aave-starknet-core

from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_lt, uint256_check
from starkware.cairo.common.bool import FALSE, TRUE

namespace SafeUint256Cmp:
    func le{range_check_ptr}(a : Uint256, b : Uint256) -> (res : felt):
        uint256_check(a)
        uint256_check(b)
        let (res) = uint256_le(a, b)
        return (res)
    end

    func lt{range_check_ptr}(a : Uint256, b : Uint256) -> (res : felt):
        uint256_check(a)
        uint256_check(b)
        let (res) = uint256_lt(a, b)
        return (res)
    end
end
