%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import (HashBuiltin, SignatureBuiltin)
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_nn, assert_not_zero, unsigned_div_rem
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.starknet.common.messages import send_message_to_l1
from starkware.starknet.common.syscalls import get_tx_signature, get_contract_address, get_block_timestamp, get_caller_address

from utils.DecentralMediaHelper import (Rating, String)
from ERC721_User import (mint, createUser)


const USER_ERC721 = 1
const CONTENT_ERC721 = 2

@storage_var
func admin() -> (adm : felt):
end

@storage_var
func pause() -> (paus : felt):
end

@storage_var
func user(address : felt) -> (token_id : felt):
end

@storage_var
func erc721_contract(contract : felt) -> (contract : felt):
end

@storage_var
func user_token_id() -> (token_id : felt):
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
    usr : felt):
    return user.read(address=address)
end


@external
func create_user{
    syscall_ptr : felt*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    username : String,
    image : String,
    background_image : String,
    description : String,
    social_links_len : felt,
    social_links : String*,
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

    let (token_id) = user_token_id.read()

    # TODO: Change ERC721 contract to mint with parameters

    mint(caller, token_id)
    createUser(token_id, username, image, 
                background_image, description, 
                social_links_len, social_links)

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