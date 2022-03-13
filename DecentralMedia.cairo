%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import (HashBuiltin, SignatureBuiltin)
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_nn, assert_not_zero, unsigned_div_rem, split_felt
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.starknet.common.messages import send_message_to_l1
from starkware.starknet.common.syscalls import get_tx_signature, get_contract_address, get_block_timestamp, get_caller_address
from starkware.cairo.common.uint256 import Uint256

from utils.DecentralMediaHelper import (Array, User)
from ERC721_User import (mint, getPropertyFelt, getPropertyArray, getProperties, setPropertyFelt, setPropertyArray, setProperties)


const USER_ERC721 = 1
const CONTENT_ERC721 = 2

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


@constructor
func constructor{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    adm : felt):
    admin.write(value=adm)

    return ()
end


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
    token_id : User):
    alloc_locals

    let (token_id) = user_token_id.read(address=address)
    let (contract) = erc721_contract.read(contract=USER_ERC721)

    let names : felt* = alloc()
    names[0] = 'username'
    names[1] = 'image'
    names[2] = 'background_image'
    names[3] = 'description'
    names[4] = 'social_link'
    names[5] = 'following'
    names[6] = 'followers'
    names[7] = 'contents'
    names[8] = 'num_ratings'
    names[9] = 'sum_ratings'
    names[10] = 'created_at'

    let (user) = getProperties(contract, names, 11, token_id)

    return User(username = user[0], 
                image = user[1], 
                background_image = user[2], 
                description = user[3],
                social_link = user[4]
                following = user[5]
                followers = user[6],
                contents = user[7],
                num_ratings = user[8].arr[0],
                sum_ratings = user[9].arr[0],
                created_at = user[10].arr[0])
end

@external
func create_user{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    username : Array,
    image : Array,
    background_image : Array,
    description : Array,
    social_link : Array,
    nonce : felt):
    alloc_locals

    check_on()

    let (caller) = get_caller_address()
    let inputs : felt* = alloc()
    inputs[0] = username
    inputs[1] = nonce
    verify_inputs_by_signature(caller, 2, inputs)

    let (user) = user.read(caller)
    assert user = 0

    # TODO: If we are filtering by unique usernames, create storage variable for usernames and add assert here

    let (counter) = user_counter.read()
    let (contract) = erc721_contract.read(contract=USER_ERC721)
    let (timestamp) = get_block_timestamp()
    let (low : felt, high : felt) = split_felt(counter)
    let token_id : Uint256 = Uint256(low,high)

    mint(contract, caller, token_id)

    let names : felt* = alloc()
    names[0] = 'username'
    names[1] = 'image'
    names[2] = 'background_image'
    names[3] = 'description'
    names[4] = 'social_link'
    names[5] = 'created_at'

    let values : felt* = alloc()
    values[0] = username
    values[1] = image
    values[2] = background_image
    values[3] = description
    values[4] = social_link
    values[5] = timestamp

    setProperties(contract, names, 6, values token_id)

    user_counter.write(counter + 1)
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