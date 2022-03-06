%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256

from token.ERC721_base import (_exists)
from token.ERC165_base import (ERC165_register_interface)
from utils.ShortString import uint256_to_ss
from utils.Array import concat_arr
from DecentralMediaHelper import (Rating, String, Array, User)

#
# Storage
#

@storage_var
func ERC721_tokens(token_id: felt) -> (balance: User):
end

#
# Events
#

@event
func Create(tokenId: Uint256, user: User):
end

@event
func Update(tokenId: Uint256, user: User):
end

#
# Constructor
#

func ERC721_User_initializer{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    # register IERC721_User
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

func ERC721_createMetadata{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(token_id: Uint256,
    username: String,
    image: String,
    background_image: String,
    description: String,
    social_links_len: felt,
    social_links: String*
    ):
    alloc_locals
    let (created_at) = get_block_timestamp()
    let (user) = User(
        username=username,
        image=image,
        background_image=background_image,
        description=description,
        social_links_len=social_links_len,
        social_links=social_links,
        following=Array(0, []),
        followers=Array(0, []),
        rating=Rating(0, 0),
        contents=Array(0, []),
        created_at=created_at
    )

    ERC721_tokens.write(token_id, user)

    # Emit Create event
    Create.emit(tokenId=token_id, user=user)
    return ()
end


#
# Internals
#


