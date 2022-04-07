%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_tx_signature, get_contract_address, get_block_timestamp, get_caller_address
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.math import assert_nn

from utils.Array import concat_arr, assert_array_includes, array_remove_element
from utils.DecentralMediaHelper import deserialize, Array, Uint256_to_felt, felt_to_Uint256
from utils.utils import verify_inputs_by_signature
from starknet_erc721_storage.IStorage import IStorage
from IERC721 import IERC721


#
# Storage
#

@storage_var
func comment_contract() -> (contract : felt):
end

@storage_var
func comment_counter() -> (token_id : felt):
end


#
# Getters
#

func Comment_getComment{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    token_id : Uint256) -> (
    comment_len: felt,
    comment: felt*,
    liked_by_len: felt,
    liked_by: felt*,
    likes: felt,
    created_at: felt,
    creator: felt,
    content: felt):
    alloc_locals

    let (contract) = comment_contract.read()

    let names : felt* = alloc()
    assert [names] = 'comment'
    assert [names + 1] = 'liked_by'
    assert [names + 2] = 'likes'
    assert [names + 3] = 'created_at'
    assert [names + 4] = 'creator'
    assert [names + 5] = 'content'

    let (offsets_len, offsets, properties_len, properties) = IStorage.getProperties(contract, 6, names, token_id)
    let (data_len: felt, data: Array*) = deserialize(offsets_len, offsets, properties_len, properties)

    return (data[0].len, data[0].arr,
            data[1].len, data[1].arr,
            data[2].arr[0],
            data[3].arr[0],
            data[4].arr[0],
            data[5].arr[0])
end


#
# Externals
#

func Comment_createComment{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    comment_len: felt,
    comment: felt*,
    creator: felt,
    content: felt,
    nonce: felt) -> (token_id: Uint256):
    alloc_locals

    let (caller) = get_caller_address()
    let inputs : felt* = alloc()
    inputs[0] = comment_len
    inputs[1] = nonce
    verify_inputs_by_signature(caller, 2, inputs)

    let (counter) = comment_counter.read()
    let (contract) = comment_contract.read()
    let (timestamp) = get_block_timestamp()
    let token_id: Uint256 = felt_to_Uint256(counter + 1)

    IERC721.mint(contract, caller, token_id)

    let (local names: felt*) = alloc()
    assert [names] = 'comment'
    assert [names + 1] = 'created_at'
    assert [names + 2] = 'creator'
    assert [names + 3] = 'likes'
    assert [names + 4] = 'content'

    let (local offsets: felt*) = alloc()
    assert [offsets] = comment_len
    assert [offsets + 1] = offsets[0] + 1
    assert [offsets + 2] = offsets[1] + 1
    assert [offsets + 3] = offsets[2] + 1
    assert [offsets + 4] = offsets[3] + 1

    let (local timestamp_arr: felt*) = alloc()
    assert [timestamp_arr] = timestamp

    let (local creator_arr: felt*) = alloc()
    assert [creator_arr] = creator

    let (local content_arr: felt*) = alloc()
    assert [content_arr] = content

    let (local empty_arr: felt*) = alloc()
    assert [empty_arr] = 0

    let (values_len, values) = concat_arr(comment_len, comment, 1, timestamp_arr)
    let (values_len, values) = concat_arr(values_len, values, 1, creator_arr)
    let (values_len, values) = concat_arr(values_len, values, 1, empty_arr)
    let (values_len, values) = concat_arr(values_len, values, 1, content_arr)

    IStorage.setProperties(contract, 5, names, token_id, 5, offsets, values_len, values)

    comment_counter.write(counter + 1)
    return (token_id)
end

func Comment_like{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    token_id: Uint256,
    user_token_id: Uint256,
    nonce: felt):
    alloc_locals

    let (caller) = get_caller_address()
    let inputs : felt* = alloc()
    assert inputs[0] = nonce
    verify_inputs_by_signature(caller, 1, inputs)

    let (contract) = comment_contract.read()
    let (user_token_id_felt: felt) = Uint256_to_felt(user_token_id)

    let (liked_by_len: felt, liked_by: felt*) = IStorage.getPropertyArray(contract, 'liked_by', token_id)
    assert_array_includes(liked_by_len, liked_by, user_token_id_felt, 1)
    assert liked_by[liked_by_len] = user_token_id_felt
    IStorage.setPropertyArray(contract, 'liked_by', token_id, liked_by_len + 1, liked_by)

    let (likes: felt) = IStorage.getPropertyFelt(contract, 'likes', token_id)
    IStorage.setPropertyFelt(contract, 'likes', token_id, likes + 1)

    return ()
end

func Comment_dislike{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    token_id: Uint256,
    user_token_id: Uint256,
    nonce: felt):
    alloc_locals

    let (caller) = get_caller_address()
    let inputs : felt* = alloc()
    assert inputs[0] = nonce
    verify_inputs_by_signature(caller, 1, inputs)

    let (contract) = comment_contract.read()
    let (user_token_id_felt: felt) = Uint256_to_felt(user_token_id)

    let (liked_by_len: felt, liked_by: felt*) = IStorage.getPropertyArray(contract, 'liked_by', token_id)
    assert_array_includes(liked_by_len, liked_by, user_token_id_felt, 1)
    array_remove_element(liked_by_len, liked_by, user_token_id_felt)
    IStorage.setPropertyArray(contract, 'liked_by', token_id, liked_by_len - 1, liked_by)
    
    let (likes: felt) = IStorage.getPropertyFelt(contract, 'likes', token_id)
    IStorage.setPropertyFelt(contract, 'likes', token_id, likes - 1)

    return ()
end

func Comment_setContract{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    adm : felt,
    contract : felt,
    nonce : felt):
    alloc_locals

    let inputs : felt* = alloc()
    inputs[0] = contract
    inputs[1] = nonce
    verify_inputs_by_signature(adm, 2, inputs)

    comment_contract.write(contract)

    return ()
end