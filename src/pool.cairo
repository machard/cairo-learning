%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from openzeppelin.token.erc20.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_le, uint256_sub
from src.IReceiver import IReceiver

@storage_var
func account_balance(account_id : felt, token_address : felt) -> (balance : Uint256):
end

@storage_var
func flashloan_price() -> (price : Uint256):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    flashloan_price_value : Uint256
):
    flashloan_price.write(flashloan_price_value)
    return ()
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

@external
func flashloan{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amount : Uint256, token_address : felt, receiver_address : felt
):
    alloc_locals

    let (local pool_address) = get_contract_address()
    let (local flashloan_price_value) = flashloan_price.read()
    let (local pool_balance_value) = IERC20.balanceOf(token_address, pool_address)

    let (res) = uint256_le(amount, pool_balance_value)
    with_attr error_message("not enough balance"):
        assert res = 1
    end

    IERC20.transfer(token_address, receiver_address, amount)

    IReceiver.processAndReturnFlashLoan(
        receiver_address, token_address, amount, flashloan_price_value
    )

    let (pool_balance_value_end) = IERC20.balanceOf(token_address, pool_address)
    let (pool_balance_value_expected, _) = uint256_add(pool_balance_value, flashloan_price_value)

    let (res_end) = uint256_le(pool_balance_value_expected, pool_balance_value_end)
    with_attr error_message("not enough has been returned"):
        assert res = 1
    end

    return ()
end

@external
func flashloanPrice{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    balance : Uint256
):
    let (flashloan_price_value) = flashloan_price.read()

    return (flashloan_price_value)
end
