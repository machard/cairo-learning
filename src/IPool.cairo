%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IPool:
    func sharePrice(token_address : felt) -> (price : Uint256):
    end

    func shares(account_id : felt, token_address : felt) -> (shares : Uint256):
    end

    func deposit(amount : Uint256, token_address : felt) -> (minted_shares : Uint256):
    end

    func withdraw(shares : Uint256, token_address : felt) -> (amount_returned : Uint256):
    end

    func flashloanPrice() -> (res : Uint256):
    end

    func flashloan(amount : Uint256, token_address : felt, receiver_address : felt) -> ():
    end
end
