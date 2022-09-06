%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IReceiver:
    func processAndReturnFlashLoan(
        token_address : felt, amount : Uint256, flashloan_price_value : Uint256
    ) -> ():
    end
end
