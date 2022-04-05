import os
from utils import *
import pytest
import functools
from starkware.crypto.signature.signature import private_to_stark_key, sign
from starkware.starknet.testing.contract import StarknetContract
from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from starkware.crypto.signature.fast_pedersen_hash import pedersen_hash
from starkware.starknet.business_logic.state import BlockInfo

ADMIN = private_to_stark_key(1234567)
USER1 = private_to_stark_key(7654321)
USER2 = private_to_stark_key(123)
ER721_CONTRACT_FILE = os.path.join(os.path.dirname(__file__), 'ERC721.cairo')
DECMEDIA_CONTRACT_FILE = os.path.join(os.path.dirname(__file__), 'DecentralMedia.cairo')
starknet = None
decentral_media = None

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
    global starknet
    global decentral_media
    if starknet != None and decentral_media != None:
        return

    starknet = await Starknet.empty()
    user = await starknet.deploy(
        source=ER721_CONTRACT_FILE,
        constructor_calldata=[str_to_felt("User Token"), str_to_felt("UT"), ADMIN],
        cairo_path=['cairo-contracts'])
    content = await starknet.deploy(
        source=ER721_CONTRACT_FILE,
        constructor_calldata=[str_to_felt("Content Token"), str_to_felt("CT"), ADMIN],
        cairo_path=['cairo-contracts'])
    decentral_media = await starknet.deploy(
            source=DECMEDIA_CONTRACT_FILE,
            constructor_calldata=[ADMIN],
            cairo_path=['cairo-contracts'])

    await user.transfer_ownership(new_owner=decentral_media.contract_address).invoke(caller_address=ADMIN)
    await content.transfer_ownership(new_owner=decentral_media.contract_address).invoke(caller_address=ADMIN)
    
    nonce = generate_nonce()
    await decentral_media.set_user_erc721_contract(contract=user.contract_address, nonce=nonce).invoke(caller_address=ADMIN,
        signature=sign_stark_inputs(1234567, [str(user.contract_address), str(nonce)]))

    nonce = generate_nonce()
    await decentral_media.set_content_erc721_contract(contract=content.contract_address, nonce=nonce).invoke(caller_address=ADMIN,
        signature=sign_stark_inputs(1234567, [str(content.contract_address), str(nonce)]))
    
    return starknet, decentral_media


@pytest.mark.asyncio
async def test_create_user():
    await deploy()
    set_block_timestamp(starknet.state, 1)
    nonce = generate_nonce()
    await decentral_media.create_user(username=str_to_felt_array('janez'),
                                 image=str_to_felt_array('https://picsum.photos/200'),
                                 background_image=str_to_felt_array('https://picsum.photos/seed/picsum/200/300'),
                                 description=str_to_felt_array("I am here to read some good articles!"),
                                 social_link=str_to_felt_array('https://twitter.com/unknown'),
                                 nonce=nonce).invoke(
                                    caller_address=USER1,
                                    signature=sign_stark_inputs(7654321, [str(1), str(2), str(3), str(3), str(2), str(nonce)]))

    exec_info = await decentral_media.get_user(address=USER1).call()

    assert felt_array_to_string(exec_info.result.username) == 'janez'
    assert felt_array_to_string(exec_info.result.image) == 'https://picsum.photos/200'
    assert felt_array_to_string(exec_info.result.background_image) == 'https://picsum.photos/seed/picsum/200/300'
    assert felt_array_to_string(exec_info.result.description) == 'I am here to read some good articles!'
    assert felt_array_to_string(exec_info.result.social_link) == 'https://twitter.com/unknown'
    assert exec_info.result.following == []
    assert exec_info.result.followers == []
    assert exec_info.result.contents == []
    assert exec_info.result.rated == []
    assert exec_info.result.rating[0] == 0
    assert exec_info.result.rating[1] == 0
    assert exec_info.result.created_at == 1


@pytest.mark.asyncio
async def test_update_user():
    await deploy()
    set_block_timestamp(starknet.state, 2)

    nonce = generate_nonce()
    token_id = await decentral_media.get_user_token_id(USER1).call()
    await decentral_media.update_user(token_id=token_id.result[0],
                                 username=str_to_felt_array('janez plemeniti'),
                                 image=str_to_felt_array('https://picsum.photos/202'),
                                 background_image=str_to_felt_array('https://picsum.photos/seed/picsum/200/302'),
                                 description=str_to_felt_array("I am here to read some good articles 2!"),
                                 social_link=str_to_felt_array('https://twitter.com/unknown2'),
                                 nonce=nonce).invoke(
                                    caller_address=USER1,
                                    signature=sign_stark_inputs(7654321, [str(1), str(2), str(3), str(3), str(2), str(nonce)]))

    exec_info = await decentral_media.get_user(address=USER1).call()

    assert felt_array_to_string(exec_info.result.username) == 'janez plemeniti'
    assert felt_array_to_string(exec_info.result.image) == 'https://picsum.photos/202'
    assert felt_array_to_string(exec_info.result.background_image) == 'https://picsum.photos/seed/picsum/200/302'
    assert felt_array_to_string(exec_info.result.description) == 'I am here to read some good articles 2!'
    assert felt_array_to_string(exec_info.result.social_link) == 'https://twitter.com/unknown2'
    assert exec_info.result.following == []
    assert exec_info.result.followers == []
    assert exec_info.result.contents == []
    assert exec_info.result.rated == []
    assert exec_info.result.rating[0] == 0
    assert exec_info.result.rating[1] == 0
    assert exec_info.result.created_at == 1


@pytest.mark.asyncio
async def test_follow_user():
    await deploy()
    set_block_timestamp(starknet.state, 3)

    nonce = generate_nonce()
    await decentral_media.create_user(username=str_to_felt_array('Marija'),
                                 image=str_to_felt_array('https://picsum.photos/200'),
                                 background_image=str_to_felt_array('https://picsum.photos/seed/picsum/200/300'),
                                 description=str_to_felt_array("I write articles!"),
                                 social_link=str_to_felt_array('https://twitter.com/marija'),
                                 nonce=nonce).invoke(
                                    caller_address=USER2,
                                    signature=sign_stark_inputs(123, [str(1), str(2), str(3), str(2), str(2), str(nonce)]))

    nonce = generate_nonce()
    token_id = await decentral_media.get_user_token_id(USER1).call()
    token_id_creator = await decentral_media.get_user_token_id(USER2).call()
    await decentral_media.follow(creator_token_id=token_id_creator.result[0],
                                 nonce=nonce).invoke(
                                    caller_address=USER1,
                                    signature=sign_stark_inputs(7654321, [str(nonce)]))

    exec_info = await decentral_media.get_user(address=USER1).call()
    assert exec_info.result.following[0] == uint256_to_felt(token_id_creator.result[0])
    assert exec_info.result.followers == []

    exec_info = await decentral_media.get_user(address=USER2).call()
    assert exec_info.result.following == []
    assert exec_info.result.followers[0] == uint256_to_felt(token_id.result[0])

    nonce = generate_nonce()
    await decentral_media.unfollow(creator_token_id=token_id_creator.result[0],
                                    nonce=nonce).invoke(
                                    caller_address=USER1,
                                    signature=sign_stark_inputs(7654321, [str(nonce)]))

    exec_info = await decentral_media.get_user(address=USER1).call()
    assert exec_info.result.following == []
    assert exec_info.result.followers == []

    exec_info = await decentral_media.get_user(address=USER2).call()
    assert exec_info.result.following == []
    assert exec_info.result.followers == []


@pytest.mark.asyncio
async def test_rate_user():
    await deploy()
    set_block_timestamp(starknet.state, 4)

    nonce = generate_nonce()
    token_id_creator = await decentral_media.get_user_token_id(USER2).call()
    await decentral_media.rate(creator_token_id=token_id_creator.result[0],
                                rating=5,
                                nonce=nonce).invoke(
                                    caller_address=USER1,
                                    signature=sign_stark_inputs(7654321, [str(5), str(nonce)]))

    exec_info = await decentral_media.get_user(address=USER1).call()
    assert exec_info.result.rated[0] == uint256_to_felt(token_id_creator.result[0])
    assert exec_info.result.rating[0] == 0
    assert exec_info.result.rating[1] == 0

    exec_info = await decentral_media.get_user(address=USER2).call()
    assert exec_info.result.rated == []
    assert exec_info.result.rating[0] == 1
    assert exec_info.result.rating[1] == 5


@pytest.mark.asyncio
async def test_create_content():
    await deploy()
    set_block_timestamp(starknet.state, 5)

    nonce = generate_nonce()
    await decentral_media.create_content(content=str_to_felt_array('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce quam metus, euismod a tellus ac, efficitur aliquam ex. Nulla varius velit quam, vitae fringilla enim condimentum a. In hac habitasse platea dictumst. Etiam eget odio nisi. Donec in porttitor lacus. Etiam blandit, lectus ut pharetra feugiat, lacus dui maximus metus, vitae scelerisque turpis massa vel enim. Nunc vestibulum leo purus, eget iaculis sapien accumsan in. Vivamus maximus tellus at risus consequat, in ullamcorper ligula facilisis. Phasellus in lacus quam. Maecenas fringilla, mi sit amet condimentum pretium, arcu leo porttitor enim, a gravida erat ante vel neque. Curabitur cursus felis sed placerat feugiat. Sed eget mollis libero, ac lacinia ante. Fusce sit amet orci elementum, tristique turpis sed, condimentum quam. Ut elementum et lacus vehicula sollicitudin. Praesent tincidunt tellus vitae aliquam interdum.'),
                                        tags=str_to_felt_array('lorem,ipsum'),
                                        authors=str_to_felt_array('janez novak'),
                                        public=1,
                                        nonce=nonce).invoke(
                                            caller_address=USER1,
                                            signature=sign_stark_inputs(7654321, [str(60), str(1), str(1), str(1), str(nonce)]))

    token_id = await decentral_media.get_user_token_id(USER1).call()
    exec_info = await decentral_media.get_user(address=USER1).call()
    print(exec_info.result)
    assert len(exec_info.result.contents) == 1

    exec_info = await decentral_media.get_content(token_id=uint256(exec_info.result.contents[0])).call()
    print(exec_info.result)
    assert felt_array_to_string(exec_info.result.content) == 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce quam metus, euismod a tellus ac, efficitur aliquam ex. Nulla varius velit quam, vitae fringilla enim condimentum a. In hac habitasse platea dictumst. Etiam eget odio nisi. Donec in porttitor lacus. Etiam blandit, lectus ut pharetra feugiat, lacus dui maximus metus, vitae scelerisque turpis massa vel enim. Nunc vestibulum leo purus, eget iaculis sapien accumsan in. Vivamus maximus tellus at risus consequat, in ullamcorper ligula facilisis. Phasellus in lacus quam. Maecenas fringilla, mi sit amet condimentum pretium, arcu leo porttitor enim, a gravida erat ante vel neque. Curabitur cursus felis sed placerat feugiat. Sed eget mollis libero, ac lacinia ante. Fusce sit amet orci elementum, tristique turpis sed, condimentum quam. Ut elementum et lacus vehicula sollicitudin. Praesent tincidunt tellus vitae aliquam interdum.'
    assert felt_array_to_string(exec_info.result.tags) == 'lorem,ipsum'
    assert felt_array_to_string(exec_info.result.authors) == 'janez novak'
    assert exec_info.result.liked_by == []
    assert exec_info.result.likes == 0
    assert exec_info.result.views == 1
    assert exec_info.result.public == 1
    assert exec_info.result.created_at == 5
    assert exec_info.result.creator == uint256_to_felt(token_id.result[0])

@pytest.mark.asyncio
async def test_update_content():
    await deploy()
    set_block_timestamp(starknet.state, 6)

    exec_info = await decentral_media.get_user(address=USER1).call()
    nonce = generate_nonce()
    await decentral_media.update_content(token_id=uint256(exec_info.result.contents[0]),
                                        public=0,
                                        nonce=nonce).invoke(
                                            caller_address=USER1,
                                            signature=sign_stark_inputs(7654321, [str(0), str(nonce)]))

    exec_info = await decentral_media.get_content(token_id=uint256(exec_info.result.contents[0])).call()
    
    print(exec_info.result)
    assert exec_info.result.public == 0


@pytest.mark.asyncio
async def test_like_content():
    await deploy()
    set_block_timestamp(starknet.state, 7)

    user = await decentral_media.get_user(address=USER1).call()
    nonce = generate_nonce()
    await decentral_media.like(token_id=uint256(user.result.contents[0]),
                                nonce=nonce).invoke(caller_address=USER1,
                                            signature=sign_stark_inputs(7654321, [str(nonce)]))

    exec_info = await decentral_media.get_content(token_id=uint256(user.result.contents[0])).call()
    token_id = await decentral_media.get_user_token_id(USER1).call()

    print(exec_info.result)
    assert exec_info.result.likes == 1
    assert exec_info.result.liked_by[0] == uint256_to_felt(token_id.result[0])

    nonce = generate_nonce()
    await decentral_media.dislike(token_id=uint256(user.result.contents[0]),
                                nonce=nonce).invoke(caller_address=USER1,
                                            signature=sign_stark_inputs(7654321, [str(nonce)]))

    exec_info = await decentral_media.get_content(token_id=uint256(user.result.contents[0])).call()
    token_id = await decentral_media.get_user_token_id(USER1).call()
    
    print(exec_info.result)
    assert exec_info.result.likes == 0
    assert exec_info.result.liked_by == []


@pytest.mark.asyncio
async def test_flag_user():
    await deploy()
    set_block_timestamp(starknet.state, 8)

    token_id = await decentral_media.get_user_token_id(USER2).call()
    nonce = generate_nonce()
    await decentral_media.flag_user(token_id=token_id.result[0],
                                    flag=1,
                                nonce=nonce).invoke(caller_address=ADMIN,
                                            signature=sign_stark_inputs(1234567, [str(1), str(nonce)]))
    nonce = generate_nonce()
    #with pytest.raises(StarkException):
    await decentral_media.create_content(content=str_to_felt_array('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce quam metus, euismod a tellus ac, efficitur aliquam ex. Nulla varius velit quam, vitae fringilla enim condimentum a. In hac habitasse platea dictumst. Etiam eget odio nisi. Donec in porttitor lacus. Etiam blandit, lectus ut pharetra feugiat, lacus dui maximus metus, vitae scelerisque turpis massa vel enim. Nunc vestibulum leo purus, eget iaculis sapien accumsan in. Vivamus maximus tellus at risus consequat, in ullamcorper ligula facilisis. Phasellus in lacus quam. Maecenas fringilla, mi sit amet condimentum pretium, arcu leo porttitor enim, a gravida erat ante vel neque. Curabitur cursus felis sed placerat feugiat. Sed eget mollis libero, ac lacinia ante. Fusce sit amet orci elementum, tristique turpis sed, condimentum quam. Ut elementum et lacus vehicula sollicitudin. Praesent tincidunt tellus vitae aliquam interdum.'),
                                        tags=str_to_felt_array('lorem,ipsum'),
                                        authors=str_to_felt_array('janez novak'),
                                        public=1,
                                        nonce=nonce).invoke(
                                            caller_address=USER2,
                                            signature=sign_stark_inputs(123, [str(60), str(1), str(1), str(1), str(nonce)]))