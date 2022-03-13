%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256

from token.ERC721_base import (_exists)
from token.ERC165_base import (ERC165_register_interface)
from utils.ShortString import uint256_to_ss
from utils.Array import concat_arr

struct Array:
    member len: felt
    member arr: felt*
end

#
# Storage
#

@storage_var
func properties(name: felt, token_id: felt) -> (property: Array):
end


#
# Events
#

@event
func SetProperty(name: felt, tokenId: Uint256, property: Array):
end

#
# Constructor
#

func ERC721_Storage_initializer{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr}():
    # register IERC721_Storage
    #TODO calculate correct interface identifier
    ERC165_register_interface(0x5b5e139f)
    return ()
end

#
# Getters
#

@view
func ERC721_getPropertyFelt{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    name: felt,
    token_id: Uint256) -> (property : felt):

    let (prop) = properties.read(name, token_id)

    return prop.arr[0]
end

@view
func ERC721_getPropertyArray{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    name: felt,
    token_id: Uint256) -> (property : Array):
    return properties.read(name, token_id)
end

@view
func ERC721_getProperties{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    names: felt*,
    names_len: felt,
    token_id: Uint256) -> (properties : Array*):

    let (properties: Array*) =  loop_read_properties(names, names_len, 0, token_id)
    return (properties)
end

#
# Externals
#

func ERC721_setPropertyFelt{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    name: felt,
    token_id: Uint256,
    value: felt):

    let (prop) = Array(1,[value])
    properties.write(name, token_id, prop)
    SetProperty.emit(name=name, token_id=token_id, property=prop)
    return ()
end

func ERC721_setPropertyArray{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    name: felt,
    token_id: Uint256,
    value: felt*
    value_len: felt):
    
    let (prop) = Array(value_len, value)
    properties.write(name, token_id, Array(value_len, value))
    SetProperty.emit(name=name, token_id=token_id, property=prop)
    return ()
end

func ERC721_setProperties{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    names: felt*,
    n: felt,
    values: Array*,
    token_id: Uint256):
    
    loop_set_properties(names, n, values, token_id)
    return ()
end

#
# Internals
#

func loop_read_properties{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    names: felt*,
    names_len: felt,
    n: felt,
    token_id: Uint256) -> (result : Array*):
    
    let (property) = properties.read(names[n], token_id)

    if names_len-1 == n:
        let inputs : Array* = alloc()
        inputs[n] = property
        return (result=inputs)
    end

    let (res) = loop_read_properties(names + 1, names_len, n + 1, token_id)
    res[n] = property
    
    return (result=res)
end


func loop_set_properties{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    names: felt*,
    n: felt,
    values: Array*
    token_id: Uint256):
    
    properties.write(names[n-1], token_id, values[n-1])
    SetProperty.emit(name=names[n-1], token_id=token_id, property=values[n-1])

    if n == 1:
        return ()
    end

    loop_set_properties(names, n-1, values, token_id)
    
    return ()
end
