%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from openzeppelin.token.erc20.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_le, uint256_sub

@storage_var
func account_balance(account_id : felt, token_address : felt) -> (balance : Uint256):
end

@external
func deposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amount : Uint256, token_address : felt
):
    let (account_id) = get_caller_address()
    let (pool_address) = get_contract_address()

    let (account_balance_value) = account_balance.read(account_id, token_address)

    IERC20.transferFrom(token_address, account_id, pool_address, amount)

    let (new_account_balance_value, _) = uint256_add(account_balance_value, amount)
    account_balance.write(account_id, token_address, new_account_balance_value)

    return ()
end

@external
func withdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amount : Uint256, token_address : felt
):
    alloc_locals

    let (local account_id) = get_caller_address()
    let (local pool_address) = get_contract_address()

    let (account_balance_value) = account_balance.read(account_id, token_address)

    let (res) = uint256_le(amount, account_balance_value)
    with_attr error_message("not enough balance"):
        assert res = 1
    end

    IERC20.transfer(token_address, account_id, amount)

    let (new_account_balance_value) = uint256_sub(account_balance_value, amount)
    account_balance.write(account_id, token_address, new_account_balance_value)

    return ()
end

@external
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_address : felt, account_id : felt
) -> (balance : Uint256):
    let (account_balance_value) = account_balance.read(account_id, token_address)

    return (account_balance_value)
end
