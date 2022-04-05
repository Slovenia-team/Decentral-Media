%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_tx_signature, get_contract_address, get_block_timestamp, get_caller_address
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.math import assert_nn


from utils.Array import concat_arr, assert_array_not_includes, assert_array_includes, array_remove_element
from utils.DecentralMediaHelper import deserialize, Array, Uint256_to_felt, felt_to_Uint256
from utils.utils import verify_inputs_by_signature
from starknet_erc721_storage.IStorage import IStorage
from IERC721 import IERC721


#
# Storage
#

@storage_var
func user_contract() -> (contract : felt):
end

@storage_var
func user_token_id(address : felt) -> (token_id : Uint256):
end

@storage_var
func user_counter() -> (token_id : felt):
end


#
# Getters
#

func User_getUserTokenId{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    address : felt) -> (
    token_id : Uint256):
    return user_token_id.read(address=address)
end

func User_getIsFlaged{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    token_id: Uint256) -> (
    flaged: felt):
    let (contract) = user_contract.read()
    let (flaged) = IStorage.getPropertyFelt(contract, 'flaged', token_id)
    return (flaged)
end

func User_getUser{
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
    rated_len: felt,
    rated: felt*,
    rating_len: felt,
    rating: felt*,
    created_at: felt):
    alloc_locals

    let (token_id) = user_token_id.read(address=address)
    let (contract) = user_contract.read()

    let names : felt* = alloc()
    assert [names] = 'username'
    assert [names + 1] = 'image'
    assert [names + 2] = 'background_image'
    assert [names + 3] = 'description'
    assert [names + 4] = 'social_link'
    assert [names + 5] = 'following'
    assert [names + 6] = 'followers'
    assert [names + 7] = 'contents'
    assert [names + 8] = 'rated'
    assert [names + 9] = 'rating'
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
            user_data[8].len, user_data[8].arr,
            user_data[9].len, user_data[9].arr,
            user_data[10].arr[0])
end


#
# Externals
#

func User_createUser{
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

    let (caller) = get_caller_address()
    let inputs : felt* = alloc()
    inputs[0] = username_len
    inputs[1] = image_len
    inputs[2] = background_image_len
    inputs[3] = description_len
    inputs[4] = social_link_len
    inputs[5] = nonce
    verify_inputs_by_signature(caller, 6, inputs)

    # TODO: If we are filtering by unique usernames, create storage variable for usernames and add assert here

    let (counter) = user_counter.read()
    let (contract) = user_contract.read()
    let (timestamp) = get_block_timestamp()
    let token_id: Uint256 = felt_to_Uint256(counter + 1)

    IERC721.mint(contract, caller, token_id)

    let (local names: felt*) = alloc()
    assert [names] = 'username'
    assert [names + 1] = 'image'
    assert [names + 2] = 'background_image'
    assert [names + 3] = 'description'
    assert [names + 4] = 'social_link'
    assert [names + 5] = 'created_at'
    assert [names + 6] = 'rating'

    let (local offsets: felt*) = alloc()
    assert [offsets] = username_len
    assert [offsets + 1] = offsets[0] + image_len
    assert [offsets + 2] = offsets[1] + background_image_len
    assert [offsets + 3] = offsets[2] + description_len
    assert [offsets + 4] = offsets[3] + social_link_len
    assert [offsets + 5] = offsets[4] + 1
    assert [offsets + 6] = offsets[5] + 2

    let (local timestamp_arr: felt*) = alloc()
    assert [timestamp_arr] = timestamp

    let (local rating_arr: felt*) = alloc()
    assert [rating_arr] = 0
    assert [rating_arr + 1] = 0

    let (values_len, values) = concat_arr(username_len, username, image_len, image)
    let (values_len, values) = concat_arr(values_len, values, background_image_len, background_image)
    let (values_len, values) = concat_arr(values_len, values, description_len, description)
    let (values_len, values) = concat_arr(values_len, values, social_link_len, social_link)
    let (values_len, values) = concat_arr(values_len, values, 1, timestamp_arr)
    let (values_len, values) = concat_arr(values_len, values, 2, rating_arr)

    IStorage.setProperties(contract, 7, names, token_id, 7, offsets, values_len, values)

    user_token_id.write(caller, token_id)
    user_counter.write(counter + 1)
    return ()
end

func User_updateUser{
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

    let (caller) = get_caller_address()
    let inputs : felt* = alloc()
    inputs[0] = username_len
    inputs[1] = image_len
    inputs[2] = background_image_len
    inputs[3] = description_len
    inputs[4] = social_link_len
    inputs[5] = nonce
    verify_inputs_by_signature(caller, 6, inputs)

    # TODO: If we are filtering by unique usernames, create storage variable for usernames and add assert here

    let (contract) = user_contract.read()

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

func User_updateContents{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    token_id: Uint256,
    content_token_id: Uint256):
    alloc_locals

    let (contract) = user_contract.read()

    let (content_token_id_felt: felt) = Uint256_to_felt(content_token_id)
    let (user_contents_len: felt, user_contents: felt*) = IStorage.getPropertyArray(contract, 'contents', token_id)
    assert user_contents[user_contents_len] = content_token_id_felt
    IStorage.setPropertyArray(contract, 'contents', token_id, user_contents_len + 1, user_contents)

    return ()
end

func User_follow{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    creator_token_id: Uint256,
    nonce: felt):
    alloc_locals

    let (caller) = get_caller_address()
    let inputs : felt* = alloc()
    assert inputs[0] = nonce
    verify_inputs_by_signature(caller, 1, inputs)

    let (contract) = user_contract.read()
    let (token_id: Uint256) = user_token_id.read(caller)
    let (token_id_felt: felt) = Uint256_to_felt(token_id)
    let (creator_token_id_felt: felt) = Uint256_to_felt(creator_token_id)

    let (following_len: felt, following: felt*) = IStorage.getPropertyArray(contract, 'following', token_id)
    assert_array_not_includes(following_len, following, creator_token_id_felt, 1)
    assert following[following_len] = creator_token_id_felt

    let (followers_len: felt, followers: felt*) = IStorage.getPropertyArray(contract, 'followers', creator_token_id)
    assert followers[followers_len] = token_id_felt

    IStorage.setPropertyArray(contract, 'following', token_id, following_len + 1, following)
    IStorage.setPropertyArray(contract, 'followers', creator_token_id, followers_len + 1, followers)

    return ()
end

func User_unfollow{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    creator_token_id: Uint256,
    nonce: felt):
    alloc_locals


    let (caller) = get_caller_address()
    let inputs : felt* = alloc()
    assert inputs[0] = nonce
    verify_inputs_by_signature(caller, 1, inputs)

    let (contract) = user_contract.read()
    let (token_id: Uint256) = user_token_id.read(caller)
    let (token_id_felt: felt) = Uint256_to_felt(token_id)
    let (creator_token_id_felt: felt) = Uint256_to_felt(creator_token_id)

    let (following_len: felt, following: felt*) = IStorage.getPropertyArray(contract, 'following', token_id)
    assert_array_includes(following_len, following, creator_token_id_felt, 1)
    array_remove_element(following_len, following, creator_token_id_felt)

    let (followers_len: felt, followers: felt*) = IStorage.getPropertyArray(contract, 'followers', creator_token_id)
    array_remove_element(followers_len, followers, token_id_felt)

    IStorage.setPropertyArray(contract, 'following', token_id, following_len - 1, following)
    IStorage.setPropertyArray(contract, 'followers', creator_token_id, followers_len - 1, followers)

    return ()
end

func User_rate{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    creator_token_id: Uint256,
    rating: felt,
    nonce: felt):
    alloc_locals

    assert_nn(5 - rating)
    assert_nn(rating - 1)

    let (caller) = get_caller_address()
    let inputs : felt* = alloc()
    assert inputs[0] = rating
    assert inputs[1] = nonce
    verify_inputs_by_signature(caller, 2, inputs)

    let (contract) = user_contract.read()
    let (token_id: Uint256) = user_token_id.read(caller)
    let (token_id_felt: felt) = Uint256_to_felt(token_id)
    let (creator_token_id_felt: felt) = Uint256_to_felt(creator_token_id)

    let (rated_len: felt, rated: felt*) = IStorage.getPropertyArray(contract, 'rated', token_id)
    assert_array_not_includes(rated_len, rated, creator_token_id_felt, 2)
    assert rated[rated_len] = creator_token_id_felt
    assert rated[rated_len + 1] = rating

    IStorage.setPropertyArray(contract, 'rated', token_id, rated_len + 2, rated)

    let (ratings_len: felt, ratings: felt*) = IStorage.getPropertyArray(contract, 'rating', creator_token_id)
    let (new_rating: felt*) = alloc()
    assert new_rating[0] = ratings[0] + 1      # num_ratings
    assert new_rating[1] = ratings[1] + rating # sum_ratings

    IStorage.setPropertyArray(contract, 'rating', creator_token_id, 2, new_rating)

    return ()
end

func User_setContract{
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

    user_contract.write(contract)

    return ()
end

func User_flag{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    adm: felt,
    token_id: Uint256,
    flag: felt,
    nonce: felt):

    let inputs : felt* = alloc()
    inputs[0] = flag
    inputs[1] = nonce
    verify_inputs_by_signature(adm, 2, inputs)

    let (contract) = user_contract.read()
    IStorage.setPropertyFelt(contract, 'flaged', token_id, flag)

    return ()
end