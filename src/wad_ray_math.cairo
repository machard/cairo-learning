// https://github.com/aave-starknet-project/aave-starknet-core

from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_sub,
    uint256_mul,
    uint256_unsigned_div_rem,
    uint256_le,
)
from starkware.cairo.common.bool import TRUE, FALSE
from src.safe_uint256_cmp import SafeUint256Cmp

const UINT128_MAX = 2 ** 128 - 1;

namespace WadRayMath {
    // WAD = 1 * 10 ^ 18
    const WAD = 10 ** 18;
    const HALF_WAD = WAD / 2;

    // RAY = 1 * 10 ^ 27
    const RAY = 10 ** 27;
    const HALF_RAY = RAY / 2;

    // WAD_RAY_RATIO = 1 * 10 ^ 9
    const WAD_RAY_RATIO = 10 ** 9;
    const HALF_WAD_RAY_RATIO = WAD_RAY_RATIO / 2;

    func ray() -> (ray: Uint256) {
        return (Uint256(RAY, 0),);
    }

    func wad() -> (wad: Uint256) {
        return (Uint256(WAD, 0),);
    }

    func half_ray() -> (half_ray: Uint256) {
        return (Uint256(HALF_RAY, 0),);
    }

    func half_wad() -> (half_wad: Uint256) {
        return (Uint256(HALF_WAD, 0),);
    }

    func wad_ray_ratio() -> (ratio: Uint256) {
        return (Uint256(WAD_RAY_RATIO, 0),);
    }

    func half_wad_ray_ratio() -> (ratio: Uint256) {
        return (Uint256(HALF_WAD_RAY_RATIO, 0),);
    }

    func uint256_max() -> (max: Uint256) {
        return (Uint256(UINT128_MAX, UINT128_MAX),);
    }

    func wad_mul{range_check_ptr}(a: Uint256, b: Uint256) -> (res: Uint256) {
        alloc_locals;
        if (a.high + a.low == 0) {
            return (Uint256(0, 0),);
        }
        if (b.high + b.low == 0) {
            return (Uint256(0, 0),);
        }

        let (UINT256_MAX) = uint256_max();
        let (HALF_WAD_UINT) = half_wad();
        let (WAD_UINT) = wad();

        with_attr error_message("WAD multiplication overflow") {
            let (bound) = uint256_sub(UINT256_MAX, HALF_WAD_UINT);
            let (quotient, rem) = uint256_unsigned_div_rem(bound, b);
            let (le) = SafeUint256Cmp.le(a, quotient);
            assert le = TRUE;
        }

        let (ab, _) = uint256_mul(a, b);
        let (abHW, _) = uint256_add(ab, HALF_WAD_UINT);
        let (res, _) = uint256_unsigned_div_rem(abHW, WAD_UINT);
        return (res,);
    }

    func wad_div{range_check_ptr}(a: Uint256, b: Uint256) -> (res: Uint256) {
        alloc_locals;
        with_attr error_message("WAD divide by zero") {
            assert_not_zero(b.high + b.low);
        }

        let (halfB, _) = uint256_unsigned_div_rem(b, Uint256(2, 0));

        let (UINT256_MAX) = uint256_max();
        let (WAD_UINT) = wad();

        with_attr error_message("WAD div overflow") {
            let (bound) = uint256_sub(UINT256_MAX, halfB);
            let (quo, _) = uint256_unsigned_div_rem(bound, WAD_UINT);
            let (le) = SafeUint256Cmp.le(a, quo);
            assert le = TRUE;
        }

        let (aWAD, _) = uint256_mul(a, WAD_UINT);
        let (aWADHalfB, _) = uint256_add(aWAD, halfB);
        let (res, _) = uint256_unsigned_div_rem(aWADHalfB, b);
        return (res,);
    }

    func wad_add{range_check_ptr}(a: Uint256, b: Uint256) -> (res: Uint256, overflow: felt) {
        let (sum, overflow) = uint256_add(a, b);
        return (sum, overflow);
    }

    func wad_sub{range_check_ptr}(a: Uint256, b: Uint256) -> (res: Uint256) {
        let (diff) = uint256_sub(a, b);
        return (diff,);
    }

    func ray_mul{range_check_ptr}(a: Uint256, b: Uint256) -> (res: Uint256) {
        alloc_locals;
        if (a.high + a.low == 0) {
            return (Uint256(0, 0),);
        }
        if (b.high + b.low == 0) {
            return (Uint256(0, 0),);
        }

        let (UINT256_MAX) = uint256_max();
        let (HALF_RAY_UINT) = half_ray();
        let (RAY_UINT) = ray();

        with_attr error_message("RAY div overflow") {
            let (bound) = uint256_sub(UINT256_MAX, HALF_RAY_UINT);
            let (quotient, rem) = uint256_unsigned_div_rem(bound, b);
            let (le) = SafeUint256Cmp.le(a, quotient);
            assert le = TRUE;
        }

        let (ab, _) = uint256_mul(a, b);
        let (abHR, _) = uint256_add(ab, HALF_RAY_UINT);
        let (res, _) = uint256_unsigned_div_rem(abHR, RAY_UINT);
        return (res,);
    }

    func ray_div{range_check_ptr}(a: Uint256, b: Uint256) -> (res: Uint256) {
        alloc_locals;
        with_attr error_message("RAY divide by zero") {
            assert_not_zero(b.high + b.low);
        }

        let (halfB, _) = uint256_unsigned_div_rem(b, Uint256(2, 0));

        let (UINT256_MAX) = uint256_max();
        let (RAY_UINT) = ray();

        with_attr error_message("RAY multiplication overflow") {
            let (bound) = uint256_sub(UINT256_MAX, halfB);
            let (quo, _) = uint256_unsigned_div_rem(bound, RAY_UINT);
            let (le) = SafeUint256Cmp.le(a, quo);
            assert le = TRUE;
        }

        let (aRAY, _) = uint256_mul(a, RAY_UINT);
        let (aRAYHalfB, _) = uint256_add(aRAY, halfB);
        let (res, _) = uint256_unsigned_div_rem(aRAYHalfB, b);
        return (res,);
    }

    func ray_to_wad{range_check_ptr}(a: Uint256) -> (res: Uint256) {
        alloc_locals;
        let (HALF_WAD_RAY_RATIO_UINT) = half_wad_ray_ratio();
        let (WAD_RAY_RATIO_UINT) = wad_ray_ratio();

        let (res, overflow) = uint256_add(a, HALF_WAD_RAY_RATIO_UINT);
        with_attr error_message("ray_to_wad overflow") {
            assert overflow = FALSE;
        }
        let (res, _) = uint256_unsigned_div_rem(res, WAD_RAY_RATIO_UINT);
        return (res,);
    }

    func wad_to_ray{range_check_ptr}(a: Uint256) -> (res: Uint256) {
        alloc_locals;
        let (WAD_RAY_RATIO_UINT) = wad_ray_ratio();

        let (res, overflow) = uint256_mul(a, WAD_RAY_RATIO_UINT);
        with_attr error_message("wad_to_ray overflow") {
            assert overflow.high + overflow.low = FALSE;
        }
        return (res,);
    }

    func ray_mul_no_rounding{range_check_ptr}(a: Uint256, b: Uint256) -> (res: Uint256) {
        alloc_locals;
        if (a.high + a.low == 0) {
            return (Uint256(0, 0),);
        }
        if (b.high + b.low == 0) {
            return (Uint256(0, 0),);
        }

        let (RAY_UINT) = ray();

        let (ab, overflow) = uint256_mul(a, b);
        with_attr error_message("ray_mul_no_rounding overflow") {
            assert overflow.high = FALSE;
            assert overflow.low = FALSE;
        }
        let (res, _) = uint256_unsigned_div_rem(ab, RAY_UINT);
        return (res,);
    }

    func ray_div_no_rounding{range_check_ptr}(a: Uint256, b: Uint256) -> (res: Uint256) {
        alloc_locals;
        with_attr error_message("RAY divide by zero") {
            assert_not_zero(b.high + b.low);
        }

        let (RAY_UINT) = ray();

        let (aRAY, overflow) = uint256_mul(a, RAY_UINT);
        with_attr error_message("ray_div_no_rounding overflow") {
            assert overflow.high = FALSE;
            assert overflow.low = FALSE;
        }
        let (res, _) = uint256_unsigned_div_rem(aRAY, b);
        return (res,);
    }

    func ray_to_wad_no_rounding{range_check_ptr}(a: Uint256) -> (res: Uint256) {
        let (WAD_RAY_RATIO_UINT) = wad_ray_ratio();
        let (res, _) = uint256_unsigned_div_rem(a, WAD_RAY_RATIO_UINT);
        return (res,);
    }

    func ray_add{range_check_ptr}(a: Uint256, b: Uint256) -> (res: Uint256, overflow: felt) {
        let (sum, overflow) = uint256_add(a, b);
        return (sum, overflow);
    }

    func ray_sub{range_check_ptr}(a: Uint256, b: Uint256) -> (res: Uint256) {
        let (diff) = uint256_sub(a, b);
        return (diff,);
    }

    func wad_le{range_check_ptr}(a: Uint256, b: Uint256) -> (res: felt) {
        let (res) = SafeUint256Cmp.le(a, b);
        return (res,);
    }
}
