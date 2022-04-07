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
func content_contract() -> (contract : felt):
end

@storage_var
func content_counter() -> (token_id : felt):
end


#
# Getters
#

func Content_getContent{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    token_id : Uint256) -> (
    content_len: felt,
    content: felt*,
    tags_len: felt,
    tags: felt*,
    authors_len: felt,
    authors: felt*,
    comments_len: felt,
    comments: felt*,
    liked_by_len: felt,
    liked_by: felt*,
    likes: felt,
    views: felt,
    public: felt,
    created_at: felt,
    creator: felt):
    alloc_locals

    let (contract) = content_contract.read()

    let (views: felt) = IStorage.getPropertyFelt(contract, 'views', token_id)
    IStorage.setPropertyFelt(contract, 'views', token_id, views + 1)

    let names : felt* = alloc()
    assert [names] = 'content'
    assert [names + 1] = 'tags'
    assert [names + 2] = 'authors'
    assert [names + 3] = 'comments'
    assert [names + 4] = 'liked_by'
    assert [names + 5] = 'likes'
    assert [names + 6] = 'views'
    assert [names + 7] = 'public'
    assert [names + 8] = 'created_at'
    assert [names + 9] = 'creator'

    let (offsets_len, offsets, properties_len, properties) = IStorage.getProperties(contract, 10, names, token_id)
    let (data_len: felt, data: Array*) = deserialize(offsets_len, offsets, properties_len, properties)

    return (data[0].len, data[0].arr,
            data[1].len, data[1].arr,
            data[2].len, data[2].arr,
            data[3].len, data[3].arr,
            data[4].len, data[4].arr,
            data[5].arr[0],
            data[6].arr[0],
            data[7].arr[0],
            data[8].arr[0],
            data[9].arr[0])
end


#
# Externals
#

func Content_createContent{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    content_len: felt,
    content: felt*,
    tags_len: felt,
    tags: felt*,
    authors_len: felt,
    authors: felt*,
    public: felt,
    creator: felt,
    nonce: felt) -> (token_id: Uint256):
    alloc_locals

    let (caller) = get_caller_address()
    let inputs : felt* = alloc()
    inputs[0] = content_len
    inputs[1] = tags_len
    inputs[2] = authors_len
    inputs[3] = public
    inputs[4] = nonce
    verify_inputs_by_signature(caller, 5, inputs)

    let (counter) = content_counter.read()
    let (contract) = content_contract.read()
    let (timestamp) = get_block_timestamp()
    let token_id: Uint256 = felt_to_Uint256(counter + 1)

    IERC721.mint(contract, caller, token_id)

    let (local names: felt*) = alloc()
    assert [names] = 'content'
    assert [names + 1] = 'tags'
    assert [names + 2] = 'authors'
    assert [names + 3] = 'public'
    assert [names + 4] = 'created_at'
    assert [names + 5] = 'creator'
    assert [names + 6] = 'likes'
    assert [names + 7] = 'views'

    let (local offsets: felt*) = alloc()
    assert [offsets] = content_len
    assert [offsets + 1] = offsets[0] + tags_len
    assert [offsets + 2] = offsets[1] + authors_len
    assert [offsets + 3] = offsets[2] + 1
    assert [offsets + 4] = offsets[3] + 1
    assert [offsets + 5] = offsets[4] + 1
    assert [offsets + 6] = offsets[5] + 1
    assert [offsets + 7] = offsets[6] + 1

    let (local public_arr: felt*) = alloc()
    assert [public_arr] = public

    let (local timestamp_arr: felt*) = alloc()
    assert [timestamp_arr] = timestamp

    let (local creator_arr: felt*) = alloc()
    assert [creator_arr] = creator

    let (local empty_arr: felt*) = alloc()
    assert [empty_arr] = 0

    let (values_len, values) = concat_arr(content_len, content, tags_len, tags)
    let (values_len, values) = concat_arr(values_len, values, authors_len, authors)
    let (values_len, values) = concat_arr(values_len, values, 1, public_arr)
    let (values_len, values) = concat_arr(values_len, values, 1, timestamp_arr)
    let (values_len, values) = concat_arr(values_len, values, 1, creator_arr)
    let (values_len, values) = concat_arr(values_len, values, 1, empty_arr)
    let (values_len, values) = concat_arr(values_len, values, 1, empty_arr)

    IStorage.setProperties(contract, 8, names, token_id, 8, offsets, values_len, values)

    content_counter.write(counter + 1)
    return (token_id)
end

func Content_updateContent{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    token_id: Uint256,
    public: felt,
    nonce: felt):
    alloc_locals

    let (caller) = get_caller_address()
    let inputs : felt* = alloc()
    inputs[0] = public
    inputs[1] = nonce
    verify_inputs_by_signature(caller, 2, inputs)

    let (contract) = content_contract.read()

    IStorage.setPropertyFelt(contract, 'public', token_id, public)

    return ()
end

func Content_updateComments{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    token_id: Uint256,
    comment_token_id: Uint256):
    alloc_locals

    let (contract) = content_contract.read()

    let (comment_token_id_felt: felt) = Uint256_to_felt(comment_token_id)
    let (comments_len: felt, comments: felt*) = IStorage.getPropertyArray(contract, 'comments', token_id)
    assert comments[comments_len] = comment_token_id_felt
    IStorage.setPropertyArray(contract, 'comments', token_id, comments_len + 1, comments)

    return ()
end

func Content_like{
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

    let (contract) = content_contract.read()
    let (user_token_id_felt: felt) = Uint256_to_felt(user_token_id)

    let (liked_by_len: felt, liked_by: felt*) = IStorage.getPropertyArray(contract, 'liked_by', token_id)
    assert_array_includes(liked_by_len, liked_by, user_token_id_felt, 1)
    assert liked_by[liked_by_len] = user_token_id_felt
    IStorage.setPropertyArray(contract, 'liked_by', token_id, liked_by_len + 1, liked_by)

    let (likes: felt) = IStorage.getPropertyFelt(contract, 'likes', token_id)
    IStorage.setPropertyFelt(contract, 'likes', token_id, likes + 1)

    return ()
end

func Content_dislike{
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

    let (contract) = content_contract.read()
    let (user_token_id_felt: felt) = Uint256_to_felt(user_token_id)

    let (liked_by_len: felt, liked_by: felt*) = IStorage.getPropertyArray(contract, 'liked_by', token_id)
    assert_array_includes(liked_by_len, liked_by, user_token_id_felt, 1)
    array_remove_element(liked_by_len, liked_by, user_token_id_felt)
    IStorage.setPropertyArray(contract, 'liked_by', token_id, liked_by_len - 1, liked_by)
    
    let (likes: felt) = IStorage.getPropertyFelt(contract, 'likes', token_id)
    IStorage.setPropertyFelt(contract, 'likes', token_id, likes - 1)

    return ()
end

func Content_setContract{
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

    content_contract.write(contract)

    return ()
end