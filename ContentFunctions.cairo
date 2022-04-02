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
func erc721_contract() -> (contract : felt):
end

@storage_var
func content_token_id(address : felt) -> (token_id : Uint256):
end

@storage_var
func content_counter() -> (token_id : felt):
end


#
# Getters
#

func Content_getContentTokenId{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    address : felt) -> (
    token_id : Uint256):
    return content_token_id.read(address=address)
end

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
    liked_by_len: felt,
    liked_by: felt*,
    likes: felt,
    views: felt,
    public: felt,
    created_at: felt):
    alloc_locals

    let (contract) = erc721_contract.read()

    let (views: felt) = IStorage.getPropertyFelt(contract, 'views', token_id)
    IStorage.setPropertyFelt(contract, 'views', token_id, views + 1)

    let names : felt* = alloc()
    assert [names] = 'content'
    assert [names + 1] = 'tags'
    assert [names + 2] = 'authors'
    assert [names + 4] = 'liked_by'
    assert [names + 3] = 'likes'
    assert [names + 5] = 'views'
    assert [names + 6] = 'public'
    assert [names + 7] = 'created_at'

    let (offsets_len, offsets, properties_len, properties) = IStorage.getProperties(contract, 8, names, token_id)
    let (data_len: felt, data: Array*) = deserialize(offsets_len, offsets, properties_len, properties)

    return (data[0].len, data[0].arr,
            data[1].len, data[1].arr,
            data[2].len, data[2].arr,
            data[3].len, data[3].arr,
            data[4].arr[0],
            data[5].arr[0],
            data[6].arr[0],
            data[7].arr[0])
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
    creator_token_id: Uint256,
    nonce: felt):
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
    let (contract) = erc721_contract.read()
    let (timestamp) = get_block_timestamp()
    let token_id: Uint256 = felt_to_Uint256(counter + 1)

    IERC721.mint(contract, caller, token_id)

    let (local names: felt*) = alloc()
    assert [names] = 'content'
    assert [names + 1] = 'tags'
    assert [names + 2] = 'authors'
    assert [names + 3] = 'public'
    assert [names + 4] = 'created_at'

    let (local offsets: felt*) = alloc()
    assert [offsets] = content_len
    assert [offsets + 1] = offsets[0] + tags_len
    assert [offsets + 2] = offsets[1] + authors_len
    assert [offsets + 3] = offsets[2] + 1
    assert [offsets + 4] = offsets[3] + 1

    let (local public_arr: felt*) = alloc()
    assert [public_arr] = public

    let (local timestamp_arr: felt*) = alloc()
    assert [timestamp_arr] = timestamp

    let (values_len, values) = concat_arr(content_len, content, tags_len, tags)
    let (values_len, values) = concat_arr(values_len, values, authors_len, authors)
    let (values_len, values) = concat_arr(values_len, values, 1, public_arr)
    let (values_len, values) = concat_arr(values_len, values, 1, timestamp_arr)

    IStorage.setProperties(contract, 5, names, token_id, 5, offsets, values_len, values)

    let (token_id_felt: felt) = Uint256_to_felt(token_id)
    let (user_contents_len: felt, user_contents: felt*) = IStorage.getPropertyArray(contract, 'contents', creator_token_id)
    assert user_contents[user_contents_len] = token_id_felt
    IStorage.setPropertyArray(contract, 'contents', creator_token_id, user_contents_len + 1, user_contents)

    content_counter.write(counter + 1)
    return ()
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

    let (contract) = erc721_contract.read()

    IStorage.setPropertyFelt(contract, 'public', token_id, public)

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

    let (token_id_felt: felt) = Uint256_to_felt(token_id)

    let (caller) = get_caller_address()
    let inputs : felt* = alloc()
    assert inputs[0] = token_id_felt
    assert inputs[1] = nonce
    verify_inputs_by_signature(caller, 2, inputs)

    let (contract) = erc721_contract.read()
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

    let (token_id_felt: felt) = Uint256_to_felt(token_id)

    let (caller) = get_caller_address()
    let inputs : felt* = alloc()
    assert inputs[0] = token_id_felt
    assert inputs[1] = nonce
    verify_inputs_by_signature(caller, 2, inputs)

    let (contract) = erc721_contract.read()
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

    erc721_contract.write(contract)

    return ()
end