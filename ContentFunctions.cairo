%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_tx_signature, get_contract_address, get_block_timestamp, get_caller_address
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.math import assert_nn, split_felt

from utils.Array import concat_arr, assert_array_includes, array_remove_element
from utils.DecentralMediaHelper import deserialize, Array, Uint256_to_felt
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
    address : felt) -> (
    content_len: felt,
    content: felt*,
    tags_len: felt,
    tags: felt*,
    authors_len: felt,
    authors: felt*,
    liked_by_len: felt,
    liked_by: felt*,
    likes_len: felt,
    likes: felt*,
    views: felt,
    created_at: felt,
    public: felt):
    alloc_locals

    let (token_id) = content_token_id.read(address=address)
    let (contract) = erc721_contract.read()

    let names : felt* = alloc()
    assert [names] = 'content'
    assert [names + 1] = 'tags'
    assert [names + 2] = 'authors'
    assert [names + 4] = 'liked_by'
    assert [names + 3] = 'likes'
    assert [names + 5] = 'views'
    assert [names + 6] = 'created_at'
    assert [names + 7] = 'public'

    let (offsets_len, offsets, properties_len, properties) = IStorage.getProperties(contract, 8, names, token_id)
    let (data_len: felt, data: Array*) = deserialize(offsets_len, offsets, properties_len, properties)

    return (data[0].len, data[0].arr,
            data[1].len, data[1].arr,
            data[2].len, data[2].arr,
            data[3].len, data[3].arr,
            data[4].len, data[4].arr,
            data[5].arr[0],
            data[6].arr[0],
            data[7].arr[0])
end