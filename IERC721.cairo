%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC721:
    func mint(
        to: felt,
        tokenId: Uint256):
    end
end