import uuid
from functools import reduce

MAX_LEN_FELT = 15
FIELD_PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481


def str_to_felt(text):
    if len(text) > MAX_LEN_FELT:
        raise Exception("Text length too long to convert to felt.")

    return int.from_bytes(text.encode(), "big")

def felt_to_str(felt):
    length = (felt.bit_length() + 7) // 8
    return felt.to_bytes(length, byteorder="big").decode("utf-8")

def str_to_felt_array(text):
    return [str_to_felt(text[i:i+MAX_LEN_FELT]) for i in range(0, len(text), MAX_LEN_FELT)]

def uint256_to_int(uint256):
    return uint256[0] + uint256[1]*2**128

def uint256_to_felt(uint256):
    return (uint256.high * (2 ** 128) + uint256.low)

def uint256(val):
    return (val & 2**128-1, (val & (2**256-2**128)) >> 128)

def hex_to_felt(val):
    return int(val, 16)

def generate_nonce():
    uid = uuid.uuid1().hex
    return str_to_felt(uid[0:MAX_LEN_FELT])

def felt_array_to_string(array):
    return reduce(lambda x, y: x + felt_to_str(y), array, '')

def int_to_negative_felt(val):
    return FIELD_PRIME + val