%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256

from token.ERC721_base import (_exists)
from token.ERC165_base import (ERC165_register_interface)
from utils.ShortString import uint256_to_ss
from utils.Array import concat_arr
from utils.DecentralMediaHelper import (Rating, String, Array, User)

#
# Storage
#



#
# Events
#


#
# Constructor
#

func ERC721_Content_initializer{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    # register IERC721_Content
    #TODO calculate correct interface identifier
    ERC165_register_interface(0x5b5e139f)
    return ()
end


#
# Getters
#





#
# Externals
#




#
# Internals
#


