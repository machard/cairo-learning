%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IPool:
    func deposit(amount : Uint256, token_address : felt) -> ():
    end

    func withdraw(amount : Uint256, token_address : felt) -> ():
    end

    func balanceOf(token_address : felt, account_id : felt) -> (res : Uint256):
    end

    func flashloanPrice() -> (res : Uint256):
    end

    func flashloan(amount : Uint256, token_address : felt, receiver_address : felt) -> ():
    end
end
