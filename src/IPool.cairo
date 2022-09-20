%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IPool {
    func sharePrice(token_address: felt) -> (price: Uint256) {
    }

    func shares(account_id: felt, token_address: felt) -> (shares: Uint256) {
    }

    func deposit(amount: Uint256, token_address: felt) -> (minted_shares: Uint256) {
    }

    func withdraw(shares: Uint256, token_address: felt) -> (amount_returned: Uint256) {
    }

    func flashloanPrice() -> (res: Uint256) {
    }

    func flashloan(amount: Uint256, token_address: felt, receiver_address: felt) -> () {
    }
}
