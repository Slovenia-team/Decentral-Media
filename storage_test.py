from functools import reduce
import os
from utils import *

import pytest
from starkware.starknet.testing.contract import StarknetContract
from starkware.starknet.testing.starknet import Starknet

CONTRACT_FILE = os.path.join(os.path.dirname(__file__), 'storage.cairo')

async def deploy() -> (StarknetContract):
    starknet = await Starknet.empty()
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
        constructor_calldata=[])

    return contract


@pytest.mark.asyncio
async def test_getters():
    (contract) = await deploy()

    await contract.set_property_felt(name=str_to_felt('ime'), token_id=uint256(1), value=str_to_felt('Janez')).invoke()
    await contract.set_property_felt(name=str_to_felt('priimek'), token_id=uint256(1), value=str_to_felt('Kranjski')).invoke()
    await contract.set_property_felt(name=str_to_felt('ime'), token_id=uint256(2), value=str_to_felt('Marija')).invoke()

    exec_info = await contract.get_property_felt(name=str_to_felt('ime'), token_id=uint256(1)).call()
    print(felt_to_str(exec_info.result[0]))
    assert felt_to_str(exec_info.result[0]) == "Janez"

    exec_info = await contract.get_property_array(name=str_to_felt('ime'), token_id=uint256(1)).call()
    print(felt_to_str(exec_info.result[0][0]))
    assert felt_to_str(exec_info.result[0][0]) == "Janez"

    exec_info = await contract.get_properties(names=[str_to_felt('ime'), str_to_felt('priimek')], token_id=uint256(1)).call()
    for prop in exec_info.result[1]:
        print(felt_to_str(prop), end=" ")
    assert felt_to_str(exec_info.result[1][0]) == "Janez"
    assert felt_to_str(exec_info.result[1][1]) == "Kranjski"


@pytest.mark.asyncio
async def test_set_property_array():
    (contract) = await deploy()

    await contract.set_property_array(name=str_to_felt('opis'), token_id=uint256(1), value=str_to_felt_array('1 Janez je šel po Ježa in nato se je vrnil v svojo Jazbino kjer je zaspal trdno kot Trnjuljčica.')).invoke()

    exec_info = await contract.get_property_array(name=str_to_felt('ime'), token_id=uint256(1)).call()
    res = reduce(lambda x, y: x + felt_to_str(y), exec_info.result[0], '')

    assert res == '1 Janez je šel po Ježa in nato se je vrnil v svojo Jazbino kjer je zaspal trdno kot Trnjuljčica.'


@pytest.mark.asyncio
async def test_set_properties():
    (contract) = await deploy()

    names = [str_to_felt('ime'), str_to_felt('opis')]
    properties = ['Janez', '1 Janez je šel po Ježa in nato se je vrnil v svojo Jazbino kjer je zaspal trdno kot Trnjuljčica.']
    offsets = []
    values = []
    for property in properties:
        values = values + str_to_felt_array(property)
        offsets.append(len(values))
    
    await contract.set_properties(names=names, token_id=uint256(1), offsets=offsets, values=values).invoke()

    exec_info = await contract.get_properties(names=[str_to_felt('ime'), str_to_felt('opis')], token_id=uint256(1)).call()

    properties = []
    offset_from = 0
    for offset in exec_info.result[0]:
        properties.append(reduce(lambda x, y: x + felt_to_str(y), exec_info.result[1][offset_from:offset], ''))
        offset_from = offset

    assert properties[0] == 'Janez'
    assert properties[1] == '1 Janez je šel po Ježa in nato se je vrnil v svojo Jazbino kjer je zaspal trdno kot Trnjuljčica.'
