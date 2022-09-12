%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from openzeppelin.token.erc20.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_le, uint256_sub, uint256_eq
from src.IReceiver import IReceiver
from src.wad_ray_math import WadRayMath

@storage_var
func account_shares(account_id : felt, token_address : felt) -> (shares : Uint256):
end

@storage_var
func pool_shares(token_address : felt) -> (shares : Uint256):
end

@storage_var
func share_price(token_address : felt) -> (price : Uint256):
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
func sharePrice{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_address : felt
) -> (price : Uint256):
    alloc_locals

    let (local share_price_value) = share_price.read(token_address)
    let (is_share_price_zero) = uint256_eq(share_price_value, Uint256(0, 0))
    if is_share_price_zero == 1:
        let (a) = WadRayMath.wad()
        return (a)
    end
    return (share_price_value)
end

@external
func shares{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    account_id : felt, token_address : felt
) -> (shares : Uint256):
    let (account_shares_value) = account_shares.read(account_id, token_address)
    return (account_shares_value)
end

@external
func deposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amount : Uint256, token_address : felt
) -> (minted_shares : Uint256):
    alloc_locals

    let (account_id) = get_caller_address()
    let (pool_address) = get_contract_address()

    let (local account_shares_value) = account_shares.read(account_id, token_address)

    IERC20.transferFrom(token_address, account_id, pool_address, amount)

    let (share_price_value) = sharePrice(token_address)
    let (minted_shares) = WadRayMath.wad_div(amount, share_price_value)

    let (new_account_shares_value, _) = uint256_add(account_shares_value, minted_shares)
    account_shares.write(account_id, token_address, new_account_shares_value)

    let (pool_shares_value) = pool_shares.read(token_address)
    let (new_pool_shares_value, _) = uint256_add(pool_shares_value, minted_shares)
    pool_shares.write(token_address, new_pool_shares_value)

    return (minted_shares)
end

@external
func withdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    shares : Uint256, token_address : felt
) -> (amount_returned : Uint256):
    alloc_locals

    let (local account_id) = get_caller_address()
    let (local pool_address) = get_contract_address()

    let (local account_shares_value) = account_shares.read(account_id, token_address)

    let (res) = uint256_le(shares, account_shares_value)
    with_attr error_message("not enough shares"):
        assert res = 1
    end

    let (share_price_value) = sharePrice(token_address)
    let (amount) = WadRayMath.wad_mul(shares, share_price_value)

    IERC20.transfer(token_address, account_id, amount)

    let (new_account_shares_value) = uint256_sub(account_shares_value, shares)
    account_shares.write(account_id, token_address, new_account_shares_value)

    let (pool_shares_value) = pool_shares.read(token_address)
    let (new_pool_shares_value) = uint256_sub(pool_shares_value, shares)
    pool_shares.write(token_address, new_pool_shares_value)

    return (amount)
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

    let (local pool_balance_value_end) = IERC20.balanceOf(token_address, pool_address)
    let (pool_balance_value_expected, _) = uint256_add(pool_balance_value, flashloan_price_value)

    let (res_end) = uint256_le(pool_balance_value_expected, pool_balance_value_end)
    with_attr error_message("not enough has been returned"):
        assert res_end = 1
    end

    let (ratio) = WadRayMath.wad_div(pool_balance_value_end, pool_balance_value)
    let (share_price_value) = sharePrice(token_address)
    let (new_share_price_value) = WadRayMath.wad_mul(ratio, share_price_value)

    share_price.write(token_address, new_share_price_value)

    return ()
end

@external
func flashloanPrice{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    balance : Uint256
):
    let (flashloan_price_value) = flashloan_price.read()

    return (flashloan_price_value)
end
