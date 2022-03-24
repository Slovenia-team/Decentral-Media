# https://github.com/marcellobardus/starknet-l2-storage-verifier/blob/master/contracts/starknet/lib/concat_arr.cairo

from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_not_equal

func concat_arr{range_check_ptr}(
        arr1_len: felt,
        arr1: felt*,
        arr2_len: felt,
        arr2: felt*,
    ) -> (res_len: felt, res: felt*):
    alloc_locals
    let (local res: felt*) = alloc()
    memcpy(res, arr1, arr1_len)
    memcpy(res + arr1_len, arr2, arr2_len)
    return (arr1_len + arr2_len, res)
end

func assert_array_includes{range_check_ptr}(
    arr_len: felt,
    arr: felt*,
    num: felt
    ):

    if arr_len == 0:
        return ()
    end
    
    assert_not_equal(arr[0], num)

    assert_array_includes(arr_len - 1, arr + 1, num)

    return ()
end

func array_remove_element{range_check_ptr}(
    arr_len: felt,
    arr: felt*,
    el: felt,
    found: felt
    ):

    if arr_len == 0:
        return ()
    end

    if found == 1:
        assert arr[0] = arr[1]
    end

    if arr[0] == el:
        assert arr[0] = arr[1]
        assert arr_len = arr_len - 1
    end
    
    array_remove_element(arr_len - 1, arr + 1, el, 0)

    return ()
end