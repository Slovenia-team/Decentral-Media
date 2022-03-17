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
async def test_successful_escrow():
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
