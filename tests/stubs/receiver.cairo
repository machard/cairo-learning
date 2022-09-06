%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.starknet.common.syscalls import get_caller_address
from openzeppelin.token.erc20.IERC20 import IERC20

@external
func processAndReturnFlashLoan{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_address : felt, amount : Uint256, flashloan_price_value : Uint256
):
    let (pool_address) = get_caller_address()
    let (amount_to_return, _) = uint256_add(amount, flashloan_price_value)

    IERC20.transfer(token_address, pool_address, amount_to_return)

    return ()
end
