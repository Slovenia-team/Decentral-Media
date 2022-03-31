import os
from utils import *
import pytest
import functools
from starkware.crypto.signature.signature import private_to_stark_key, sign
from starkware.starknet.testing.contract import StarknetContract
from starkware.starknet.testing.starknet import Starknet
from starkware.crypto.signature.fast_pedersen_hash import pedersen_hash
from starkware.starknet.business_logic.state import BlockInfo

STARK_KEY = private_to_stark_key(1234567)
USER = private_to_stark_key(7654321)
ER721_CONTRACT_FILE = os.path.join(os.path.dirname(__file__), 'ERC721.cairo')
DECMEDIA_CONTRACT_FILE = os.path.join(os.path.dirname(__file__), 'DecentralMedia.cairo')

def set_block_timestamp(starknet_state, timestamp):
    starknet_state.state.block_info = BlockInfo(
        starknet_state.state.block_info.block_number, timestamp
    )

def sign_stark_inputs(private_key, inputs):
    message_hash = functools.reduce(
        lambda x, y: pedersen_hash(y, x),
        reversed([int(x, 16) if x.startswith('0x') else int(x) for x in inputs]), 0)
    return sign(msg_hash=message_hash, priv_key=private_key)
    
async def deploy() -> (StarknetContract):
    starknet = await Starknet.empty()
    user = await starknet.deploy(
        source=ER721_CONTRACT_FILE,
        constructor_calldata=[str_to_felt("User Token"), str_to_felt("UT"), STARK_KEY],
        cairo_path=['cairo-contracts'])
    content = await starknet.deploy(
        source=ER721_CONTRACT_FILE,
        constructor_calldata=[str_to_felt("Content Token"), str_to_felt("CT"), STARK_KEY],
        cairo_path=['cairo-contracts'])
    decentral_media = await starknet.deploy(
            source=DECMEDIA_CONTRACT_FILE,
            constructor_calldata=[STARK_KEY],
            cairo_path=['cairo-contracts'])

    await user.transfer_ownership(new_owner=decentral_media.contract_address).invoke(caller_address=STARK_KEY)
    await content.transfer_ownership(new_owner=decentral_media.contract_address).invoke(caller_address=STARK_KEY)
    
    nonce = generate_nonce()
    await decentral_media.set_user_erc721_contract(contract=user.contract_address, nonce=nonce).invoke(caller_address=STARK_KEY,
        signature=sign_stark_inputs(1234567, [str(user.contract_address), str(nonce)]))
    await decentral_media.set_content_erc721_contract(contract=content.contract_address, nonce=nonce).invoke(caller_address=STARK_KEY,
        signature=sign_stark_inputs(1234567, [str(content.contract_address), str(nonce)]))
    
    return starknet, user, content, decentral_media


@pytest.mark.asyncio
async def create_user():
    (starknet, user, content, decentral_media) = await deploy()
    set_block_timestamp(starknet.state, 1)
    nonce = generate_nonce()
    await decentral_media.create_user(username=str_to_felt_array('username'),
                                 image=str_to_felt_array('https://picsum.photos/200'),
                                 background_image=str_to_felt_array('https://picsum.photos/seed/picsum/200/300'),
                                 description=str_to_felt_array("I am here to read some good articles!"),
                                 social_link=str_to_felt_array('https://twitter.com/unknown'),
                                 nonce=nonce).invoke(
                                    caller_address=USER,
                                    signature=sign_stark_inputs(7654321, [str(1), str(2), str(3), str(3), str(2), str(nonce)]))

    exec_info = await decentral_media.get_user(address=USER).call()
    print(exec_info.result)

    assert felt_array_to_string(exec_info.result.username) == 'username'
    assert felt_array_to_string(exec_info.result.image) == 'https://picsum.photos/200'
    assert felt_array_to_string(exec_info.result.background_image) == 'https://picsum.photos/seed/picsum/200/300'
    assert felt_array_to_string(exec_info.result.description) == 'I am here to read some good articles!'
    assert felt_array_to_string(exec_info.result.social_link) == 'https://twitter.com/unknown'
    assert exec_info.result.following == []
    assert exec_info.result.followers == []
    assert exec_info.result.contents == []
    assert exec_info.result.num_ratings[0] == 0
    assert exec_info.result.sum_ratings[0] == 0
    assert exec_info.result.created_at == 1
