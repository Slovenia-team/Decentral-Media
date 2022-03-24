%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import (HashBuiltin, SignatureBuiltin)
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_nn, assert_not_zero, unsigned_div_rem, split_felt
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.starknet.common.messages import send_message_to_l1
from starkware.starknet.common.syscalls import get_tx_signature, get_contract_address, get_block_timestamp, get_caller_address
from starkware.cairo.common.uint256 import (Uint256, uint256_eq)

from utils.DecentralMediaHelper import (User, deserialize, Array, Uint256_to_felt)
from utils.Array import (concat_arr, assert_array_includes, array_remove_element)
from starknet_erc721_storage.IStorage import IStorage
from IERC721 import IERC721

const USER_ERC721 = 1
const CONTENT_ERC721 = 2


#
# Storage
#

@storage_var
func admin() -> (adm : felt):
end

@storage_var
func pause() -> (paus : felt):
end

@storage_var
func user_token_id(address : felt) -> (token_id : Uint256):
end

@storage_var
func erc721_contract(contract : felt) -> (contract : felt):
end

@storage_var
func user_counter() -> (token_id : felt):
end


#
# Constructor
#

@constructor
func constructor{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    adm : felt):
    admin.write(value=adm)

    return ()
end


#
# Getters
#

@view
func is_pause{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}() -> (
    paus : felt):
    return pause.read()
end

@view
func get_user_token_id{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    address : felt) -> (
    token_id : Uint256):
    return user_token_id.read(address=address)
end

@view
func get_user{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    address : felt) -> (
    username_len: felt,
    username: felt*,
    image_len: felt,
    image: felt*,
    background_image_len: felt,
    background_image: felt*,
    description_len: felt,
    description: felt*,
    social_link_len: felt,
    social_link: felt*,
    following_len: felt,
    following: felt*,
    followers_len: felt,
    followers: felt*,
    contents_len: felt,
    contents: felt*,
    num_ratings: felt,
    sum_ratings: felt,
    created_at: felt):
    alloc_locals

    let (token_id) = user_token_id.read(address=address)
    let (contract) = erc721_contract.read(contract=USER_ERC721)

    let names : felt* = alloc()
    assert [names] = 'username'
    assert [names + 1] = 'image'
    assert [names + 2] = 'background_image'
    assert [names + 3] = 'description'
    assert [names + 4] = 'social_link'
    assert [names + 5] = 'following'
    assert [names + 6] = 'followers'
    assert [names + 7] = 'contents'
    assert [names + 8] = 'num_ratings'
    assert [names + 9] = 'sum_ratings'
    assert [names + 10] = 'created_at'

    let (offsets_len, offsets, properties_len, properties) = IStorage.getProperties(contract, 11, names, token_id)
    let (user_data_len: felt, user_data: Array*) = deserialize(offsets_len, offsets, properties_len, properties)

    return (user_data[0].len, user_data[0].arr,
            user_data[1].len, user_data[1].arr,
            user_data[2].len, user_data[2].arr,
            user_data[3].len, user_data[3].arr,
            user_data[4].len, user_data[4].arr,
            user_data[5].len, user_data[5].arr,
            user_data[6].len, user_data[6].arr,
            user_data[7].len, user_data[7].arr,
            user_data[8].arr[0],
            user_data[9].arr[0],
            user_data[10].arr[0])
end


#
# Externals
#

@external
func create_user{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    username_len: felt,
    username: felt*,
    image_len: felt,
    image: felt*,
    background_image_len: felt,
    background_image: felt*,
    description_len: felt,
    description: felt*,
    social_link_len: felt,
    social_link: felt*,
    nonce: felt):
    alloc_locals

    check_on()

    let (caller) = get_caller_address()
    let inputs : felt* = alloc()
    inputs[0] = username
    inputs[1] = nonce
    verify_inputs_by_signature(caller, 2, inputs)

    # TODO: If we are filtering by unique usernames, create storage variable for usernames and add assert here

    let (counter) = user_counter.read()
    let (contract) = erc721_contract.read(contract=USER_ERC721)
    let (timestamp) = get_block_timestamp()
    let (low : felt, high : felt) = split_felt(counter)
    let token_id : Uint256 = Uint256(low,high)

    IERC721.mint(contract, caller, token_id)

    let (local names: felt*) = alloc()
    assert [names] = 'username'
    assert [names + 1] = 'image'
    assert [names + 2] = 'background_image'
    assert [names + 3] = 'description'
    assert [names + 4] = 'social_link'
    assert [names + 5] = 'created_at'

    let (local offsets: felt*) = alloc()
    assert [offsets] = username_len
    assert [offsets + 1] = offsets[0] + image_len
    assert [offsets + 2] = offsets[1] + background_image_len
    assert [offsets + 3] = offsets[2] + description_len
    assert [offsets + 4] = offsets[3] + social_link_len
    assert [offsets + 5] = offsets[4] + 1

    let (local timestamp_arr: felt*) = alloc()
    assert [timestamp_arr] = timestamp

    let (values_len, values) = concat_arr(username_len, username, image_len, image)
    let (values_len, values) = concat_arr(values_len, values, background_image_len, background_image)
    let (values_len, values) = concat_arr(values_len, values, description_len, description)
    let (values_len, values) = concat_arr(values_len, values, social_link_len, social_link)
    let (values_len, values) = concat_arr(values_len, values, 1, timestamp_arr)

    IStorage.setProperties(contract, 6, names, token_id, 6, offsets, values_len, values)

    user_counter.write(counter + 1)
    return ()
end

@external
func update_user{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    token_id: Uint256,
    username_len: felt,
    username: felt*,
    image_len: felt,
    image: felt*,
    background_image_len: felt,
    background_image: felt*,
    description_len: felt,
    description: felt*,
    social_link_len: felt,
    social_link: felt*,
    nonce: felt):
    alloc_locals

    check_on()

    let (caller) = get_caller_address()
    let inputs : felt* = alloc()
    inputs[0] = username
    inputs[1] = nonce
    verify_inputs_by_signature(caller, 2, inputs)

    # TODO: If we are filtering by unique usernames, create storage variable for usernames and add assert here

    let (contract) = erc721_contract.read(contract=USER_ERC721)

    let (local names: felt*) = alloc()
    assert [names] = 'username'
    assert [names + 1] = 'image'
    assert [names + 2] = 'background_image'
    assert [names + 3] = 'description'
    assert [names + 4] = 'social_link'

    let (local offsets: felt*) = alloc()
    assert [offsets] = username_len
    assert [offsets + 1] = offsets[0] + image_len
    assert [offsets + 2] = offsets[1] + background_image_len
    assert [offsets + 3] = offsets[2] + description_len
    assert [offsets + 4] = offsets[3] + social_link_len

    let (values_len, values) = concat_arr(username_len, username, image_len, image)
    let (values_len, values) = concat_arr(values_len, values, background_image_len, background_image)
    let (values_len, values) = concat_arr(values_len, values, description_len, description)
    let (values_len, values) = concat_arr(values_len, values, social_link_len, social_link)

    IStorage.setProperties(contract, 5, names, token_id, 5, offsets, values_len, values)

    return ()
end

@external
func follow{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    creator_token_id: Uint256,
    nonce: felt):
    alloc_locals

    check_on()

    let (creator_token_id_felt: felt) = Uint256_to_felt(creator_token_id)

    let (caller) = get_caller_address()
    let inputs : felt* = alloc()
    assert inputs[0] = creator_token_id_felt
    assert inputs[1] = nonce
    verify_inputs_by_signature(caller, 2, inputs)

    let (contract) = erc721_contract.read(contract=USER_ERC721)
    let (token_id: Uint256) = user_token_id.read(caller)
    let (token_id_felt: felt) = Uint256_to_felt(token_id)

    let (following_len: felt, following: felt*) = IStorage.getPropertyArray(contract, 'following', token_id)
    assert_array_includes(following_len, following, creator_token_id_felt)
    let (local new_following: felt*) = alloc()
    assert [new_following] = creator_token_id_felt
    let (new_following_arr_len: felt, new_following_arr: felt*) = concat_arr(following_len, following, 1, new_following)

    let (followers_len: felt, followers: felt*) = IStorage.getPropertyArray(contract, 'followers', creator_token_id)
    let (local new_follower: felt*) = alloc()
    assert [new_follower] = token_id_felt
    let (new_follower_arr_len: felt, new_follower_arr: felt*) = concat_arr(following_len, following, 1, new_follower)

    IStorage.setPropertyArray(contract, 'following', token_id, new_following_arr_len, new_following_arr)
    IStorage.setPropertyArray(contract, 'followers', creator_token_id, new_follower_arr_len, new_follower_arr)

    return ()
end

@external
func unfollow{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    creator_token_id: Uint256,
    nonce: felt):
    alloc_locals

    check_on()

    let (creator_token_id_felt: felt) = Uint256_to_felt(creator_token_id)

    let (caller) = get_caller_address()
    let inputs : felt* = alloc()
    assert inputs[0] = creator_token_id_felt
    assert inputs[1] = nonce
    verify_inputs_by_signature(caller, 2, inputs)

    let (contract) = erc721_contract.read(contract=USER_ERC721)
    let (token_id: Uint256) = user_token_id.read(caller)
    let (token_id_felt: felt) = Uint256_to_felt(token_id)

    let (following_len: felt, following: felt*) = IStorage.getPropertyArray(contract, 'following', token_id)
    assert_array_includes(following_len, following, creator_token_id_felt)
    array_remove_element(following_len, following, creator_token_id_felt, 0)

    let (followers_len: felt, followers: felt*) = IStorage.getPropertyArray(contract, 'followers', creator_token_id)
    array_remove_element(followers_len, followers, token_id_felt, 0)

    IStorage.setPropertyArray(contract, 'following', token_id, following_len, following)
    IStorage.setPropertyArray(contract, 'followers', creator_token_id, followers_len, followers)

    return ()
end

@external
func set_pause{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    paus_ : felt,
    nonce : felt):
    alloc_locals
    assert paus_ * (paus_ - 1) = 0

    let (adm) = admin.read()
    let inputs : felt* = alloc()
    inputs[0] = paus_
    inputs[1] = nonce
    verify_inputs_by_signature(adm, 2, inputs)

    pause.write(paus_)

    return ()
end

@external
func set_user_erc721_contract{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    contract : felt,
    nonce : felt):
    alloc_locals

    let (adm) = admin.read()
    let inputs : felt* = alloc()
    inputs[0] = contract
    inputs[1] = nonce
    verify_inputs_by_signature(adm, 2, inputs)

    erc721_contract.write(USER_ERC721, contract)

    return ()
end

@external
func set_content_erc721_contract{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    contract : felt,
    nonce : felt):
    alloc_locals

    let (adm) = admin.read()
    let inputs : felt* = alloc()
    inputs[0] = contract
    inputs[1] = nonce
    verify_inputs_by_signature(adm, 2, inputs)

    erc721_contract.write(CONTENT_ERC721, contract)

    return ()
end


#
# Internals
#

func check_on{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}():
    let (paus) = pause.read()
    assert paus = 0

    return ()
end

func verify_inputs_by_signature{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    user : felt,
    n : felt,
    inputs : felt*):
    alloc_locals

    let (n_sig : felt, local sig : felt*) = get_tx_signature()
    assert n_sig = 2

    local syscall_ptr : felt* = syscall_ptr
    let (res) = hash_inputs(n, inputs)
    verify_ecdsa_signature(
        message=res,
        public_key=user,
        signature_r=sig[0],
        signature_s=sig[1])

    return ()
end

func hash_inputs{
    pedersen_ptr : HashBuiltin*}(
    n : felt, inputs : felt*) -> (
    result : felt):
    if n == 1:
        let (res) = hash2{hash_ptr=pedersen_ptr}(inputs[0], 0)

        return (result=res)
    end

    let (res) = hash_inputs(n - 1, inputs + 1)
    let (res) = hash2{hash_ptr=pedersen_ptr}(inputs[0], res)

    return (result=res)
end