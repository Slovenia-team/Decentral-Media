%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256

from utils.ShortString import uint256_to_ss
from utils.Array import concat_arr


#
# Storage
#

@storage_var
func storage_properties(name: felt, token_id: Uint256) -> (property_id: felt):
end

@storage_var
func storage_property_id() -> (id: felt):
end

@storage_var
func storage_property(property_id: felt, element_id: felt) -> (element: felt):
end

@storage_var
func storage_property_len(property_id: felt) -> (len: felt):
end


#
# Constructor
#

@constructor
func constructor{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}():
    
    return ()
end


#
# Getters
#

@view
func get_property_felt{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    name: felt,
    token_id: Uint256) -> (property : felt):

    let (property_id) = storage_properties.read(name, token_id)
    let (property) = storage_property.read(property_id, 0)

    return (property)
end

@view
func get_property_array{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    name: felt,
    token_id: Uint256) -> (property_len: felt, property: felt*):
    alloc_locals
    
    let (property_id) = storage_properties.read(name, token_id)
    let (property_len) = storage_property_len.read(property_id)

    let (local property: felt*) = alloc()
    let (property_len, property) = read_property_as_array(property_id, property_len, 0, property)

    return (property_len=property_len, property=property)
end

@view
func get_properties{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    names_len: felt,
    names: felt*,
    token_id: Uint256) -> (offsets_len: felt, offsets: felt*, properties_len: felt, properties: felt*):

    let offsets : felt* = alloc()
    let properties : felt* = alloc()
    let (offsets_len, offsets, properties_len, properties) = read_multiple_properties_as_array(names_len, names, 0, offsets, 0, properties, token_id)

    return (offsets_len, offsets, properties_len, properties)
end


#
# Externals
#

@external
func set_property_felt{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    name: felt,
    token_id: Uint256,
    value: felt):

    let (property_id) = storage_property_id.read()
    storage_properties.write(name, token_id, property_id)
    storage_property.write(property_id, 0, value)
    storage_property_len.write(property_id, 1)
    storage_property_id.write(property_id + 1)
    return ()
end


#
# Internals
#

func read_property_as_array{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    property_id: felt,
    property_len: felt,
    res_len: felt,
    res: felt*) -> (res_len: felt, res: felt*):
    alloc_locals

    if res_len == property_len:
        return (res_len=res_len, res=res)
    end

    let (local element: felt) = storage_property.read(property_id, res_len)
    let (local new_element: felt*) = alloc()
    new_element[0] = element
    let (new_res_len, new_res) = concat_arr(res_len, res, 1, new_element)
    let (res_len, res) = read_property_as_array(property_id, property_len, new_res_len, new_res)

    return (res_len=res_len, res=res)
end

func read_multiple_properties_as_array{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    names_len: felt,
    names: felt*,
    offsets_len: felt,
    offsets: felt*,
    properties_len: felt,
    properties: felt*,
    token_id: Uint256) -> (offsets_len: felt, offsets: felt*, properties_len: felt, properties: felt*):
    alloc_locals

    if offsets_len == names_len:
        return (offsets_len=offsets_len, offsets=offsets, properties_len=properties_len, properties=properties)
    end

    let (property_id) = storage_properties.read(names[offsets_len], token_id)
    let (property_len) = storage_property_len.read(property_id)

    let (local property: felt*) = alloc()
    let (new_property_len, new_property) = read_property_as_array(property_id, property_len, 0, property)
    let (new_properties_len, new_properties) = concat_arr(properties_len, properties, new_property_len, new_property)

    let (local new_offset: felt*) = alloc()
    new_offset[0] = new_properties_len
    let (new_offsets_len, new_offsets) = concat_arr(offsets_len, offsets, 1, new_offset)

    let (offsets_len, offsets, properties_len, properties) = read_multiple_properties_as_array(names_len, names, new_offsets_len, new_offsets, new_properties_len, new_properties, token_id)

    return (offsets_len=offsets_len, offsets=offsets, properties_len=properties_len, properties=properties)
end