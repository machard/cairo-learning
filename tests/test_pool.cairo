%lang starknet

from starkware.cairo.common.math import split_felt
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from openzeppelin.token.erc20.IERC20 import IERC20
from src.IPool import IPool
from src.IReceiver import IReceiver

func uint256_from_felt{syscall_ptr : felt*, range_check_ptr}(f : felt) -> (f_uint : Uint256):
    alloc_locals

    let (high, low) = split_felt(f)
    local f_uint : Uint256
    f_uint.high = high
    f_uint.low = low

    return (f_uint)
end

@external
func __setup__{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    %{
        context.initial_value = 300

        context.user1_address = deploy_contract("./tests/stubs/account.cairo", [1]).contract_address
        context.user2_address = deploy_contract("./tests/stubs/account.cairo", [2]).contract_address
        context.user3_address = deploy_contract("./tests/stubs/account.cairo", [3]).contract_address

        context.token_address = deploy_contract("./tests/stubs/token.cairo", {
            "name": "Token",
            "symbol": "TKN",
            "decimals": 18,
            "initial_supply": context.initial_value * 3,
            "recipient": context.user3_address
        }).contract_address

        context.pool_address = deploy_contract("./src/pool.cairo", {
            "flashloan_price_value": 10
        }).contract_address
        context.receiver_address = deploy_contract("./tests/stubs/receiver.cairo", []).contract_address

        def setup_ids(context, ids):
            ids.token_address = context.token_address
            ids.pool_address = context.pool_address
            ids.receiver_address = context.receiver_address
            ids.initial_value = context.initial_value
            ids.user1_address = context.user1_address
            ids.user2_address = context.user2_address
            ids.user3_address = context.user2_address

        context.setup_ids = setup_ids
    %}

    local token_address : felt
    local pool_address : felt
    local receiver_address : felt
    local user1_address : felt
    local user2_address : felt
    local user3_address : felt
    local initial_value : felt
    %{ context.setup_ids(context, ids) %}
    let (local initial_value_uint) = uint256_from_felt(initial_value)

    %{ stop_prank_callable = start_prank(context.user3_address, context.token_address) %}

    let (res_transfer1) = IERC20.transfer(token_address, user1_address, initial_value_uint)
    let (res_transfer2) = IERC20.transfer(token_address, user2_address, initial_value_uint)

    let (flashloan_price_value) = IPool.flashloanPrice(pool_address)
    let (res_transfer_receiver) = IERC20.transfer(
        token_address, receiver_address, flashloan_price_value
    )

    %{ stop_prank_callable() %}

    return ()
end

func deposit_into_pool{syscall_ptr : felt*, range_check_ptr}(
    pool_address : felt, token_address : felt, user_address : felt, amount : Uint256
):
    let (res_balanceOfPool_start) = IERC20.balanceOf(token_address, pool_address)
    let (res_balanceOfUser_start) = IERC20.balanceOf(token_address, user_address)
    let (res_balanceOfUserInPool_start) = IPool.balanceOf(pool_address, token_address, user_address)

    %{ stop_prank_callable = start_prank(ids.user_address, ids.token_address) %}

    IERC20.approve(token_address, pool_address, amount)

    %{ stop_prank_callable() %}

    %{ stop_prank_callable = start_prank(ids.user_address, ids.pool_address) %}

    IPool.deposit(pool_address, amount, token_address)

    %{ stop_prank_callable() %}

    let (expected_pool_value, _) = uint256_add(res_balanceOfPool_start, amount)
    let (res_balanceOfPool_end) = IERC20.balanceOf(token_address, pool_address)
    assert res_balanceOfPool_end.low = expected_pool_value.low
    assert res_balanceOfPool_end.high = expected_pool_value.high

    let (expected_user_value) = uint256_sub(res_balanceOfUser_start, amount)
    let (res_balanceOfUser_end) = IERC20.balanceOf(token_address, user_address)
    assert res_balanceOfUser_end.low = expected_user_value.low
    assert res_balanceOfUser_end.high = expected_user_value.high

    let (expected_userinpool_value, _) = uint256_add(res_balanceOfUserInPool_start, amount)
    let (res_balanceOfUserInPool_end) = IPool.balanceOf(pool_address, token_address, user_address)
    assert res_balanceOfUserInPool_end.low = expected_userinpool_value.low
    assert res_balanceOfUserInPool_end.high = expected_userinpool_value.high

    return ()
end

func withdraw_from_pool{syscall_ptr : felt*, range_check_ptr}(
    pool_address : felt, token_address : felt, user_address : felt, amount : Uint256
):
    let (res_balanceOfPool_start) = IERC20.balanceOf(token_address, pool_address)
    let (res_balanceOfUser_start) = IERC20.balanceOf(token_address, user_address)
    let (res_balanceOfUserInPool_start) = IPool.balanceOf(pool_address, token_address, user_address)

    %{ stop_prank_callable = start_prank(ids.user_address, ids.pool_address) %}

    IPool.withdraw(pool_address, amount, token_address)

    %{ stop_prank_callable() %}

    let (expected_pool_value) = uint256_sub(res_balanceOfPool_start, amount)
    let (res_balanceOfPool_end) = IERC20.balanceOf(token_address, pool_address)
    assert res_balanceOfPool_end.low = expected_pool_value.low
    assert res_balanceOfPool_end.high = expected_pool_value.high

    let (expected_user_value, _) = uint256_add(res_balanceOfUser_start, amount)
    let (res_balanceOfUser_end) = IERC20.balanceOf(token_address, user_address)
    assert res_balanceOfUser_end.low = expected_user_value.low
    assert res_balanceOfUser_end.high = expected_user_value.high

    let (expected_userinpool_value) = uint256_sub(res_balanceOfUserInPool_start, amount)
    let (res_balanceOfUserInPool_end) = IPool.balanceOf(pool_address, token_address, user_address)
    assert res_balanceOfUserInPool_end.low = expected_userinpool_value.low
    assert res_balanceOfUserInPool_end.high = expected_userinpool_value.high

    return ()
end

func flashloan_from_pool{syscall_ptr : felt*, range_check_ptr}(
    receiver_address : felt, pool_address : felt, token_address : felt, amount : Uint256
):
    let (res_balanceOfPool_start) = IERC20.balanceOf(token_address, pool_address)
    let (flashloan_price_value) = IPool.flashloanPrice(pool_address)

    IPool.flashloan(pool_address, amount, token_address, receiver_address)

    let (expected_pool_value, _) = uint256_add(res_balanceOfPool_start, flashloan_price_value)
    let (res_balanceOfPool_end) = IERC20.balanceOf(token_address, pool_address)
    assert res_balanceOfPool_end.low = expected_pool_value.low
    assert res_balanceOfPool_end.high = expected_pool_value.high

    return ()
end

@external
func test_pool{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local token_address : felt
    local pool_address : felt
    local receiver_address : felt
    local user1_address : felt
    local user2_address : felt
    local user3_address : felt
    local initial_value : felt
    %{ context.setup_ids(context, ids) %}
    let (local initial_value_uint) = uint256_from_felt(initial_value)

    deposit_into_pool(pool_address, token_address, user1_address, initial_value_uint)
    deposit_into_pool(pool_address, token_address, user2_address, initial_value_uint)

    let (flashloan_value, _) = uint256_add(initial_value_uint, initial_value_uint)

    flashloan_from_pool(receiver_address, pool_address, token_address, flashloan_value)

    withdraw_from_pool(pool_address, token_address, user1_address, initial_value_uint)
    withdraw_from_pool(pool_address, token_address, user2_address, initial_value_uint)

    return ()
end
