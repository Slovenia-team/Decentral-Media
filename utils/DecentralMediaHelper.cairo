%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import split_felt
from utils.Array import concat_arr

struct Array:
    member len: felt
    member arr: felt*
end

func deserialize{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    offsets_len: felt,
    offsets: felt*,
    values_len: felt,
    values: felt*) -> (res_len: felt, res: Array*):
    alloc_locals

    let (local initial_offset: felt*) = alloc()
    assert [initial_offset] = 0
    let (offsets_len, offsets) = concat_arr(1, initial_offset, offsets_len, offsets)

    let (local res: Array*) = alloc()
    let (res_len, res) = loop_extract(offsets_len, offsets, values_len, values, 0, res)

    return (res_len, res)
end

func loop_extract{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    offsets_len: felt,
    offsets: felt*,
    values_len: felt,
    values: felt*,
    res_len: felt,
    res: Array*) -> (res_len: felt, res: Array*):
    alloc_locals

    let (local arr: felt*) = alloc()
    let (arr_len, arr) = loop_extract_array(values_len, values, offsets[0], offsets[1], 0, arr)
    assert [res] = Array(arr_len, arr)

    if offsets_len == 2:
        return (offsets_len - 1, res)
    end

    loop_extract(offsets_len - 1, offsets + 1, values_len, values, res_len + 1, res + Array.SIZE)

    return (offsets_len - 1, res)
end

func loop_extract_array{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    values_len: felt,
    values: felt*,
    offset_from: felt,
    offset_to: felt,
    res_len: felt,
    res: felt*) -> (res_len: felt, res: felt*):
    alloc_locals

    if offset_from == offset_to:
        return(res_len, res)
    end

    assert [res] = values[offset_from]
    loop_extract_array(values_len, values, offset_from + 1, offset_to, res_len + 1, res + 1)

    return (offset_to - offset_from, res)
end

func Uint256_to_felt{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    num: Uint256) -> (num_felt: felt):

    return (num.high * (2 ** 128) + num.low)
end

func felt_to_Uint256{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr}(
    num_felt: felt) -> (num: Uint256):

    let (low: felt, high: felt) = split_felt(num_felt)
    let num: Uint256 = Uint256(low, high)

    return (num)
end
