object "EcPairing" {
	code { }
	object "EcPairing_deployed" {
		code {
			////////////////////////////////////////////////////////////////
            //                      CONSTANTS
            ////////////////////////////////////////////////////////////////

            function ZERO() -> zero {
                zero := 0x00
            }

            function ONE() -> one {
                one := 0x01
            }

            function TWO() -> two {
                two := 0x02
            }

            function THREE() -> three {
                three := 0x03
            }

            function MONTGOMERY_ONE() -> m_one {
                m_one := 6350874878119819312338956282401532409788428879151445726012394534686998597021
            }

            function MONTGOMERY_TWO() -> m_two {
                m_two := 12701749756239638624677912564803064819576857758302891452024789069373997194042
            }

            function MONTGOMERY_THREE() -> m_three {
                m_three := 19052624634359457937016868847204597229365286637454337178037183604060995791063
            }

            function MONTGOMERY_TWO_INV() -> two_inv {
                two_inv := 14119558874979547267292681013829403749242370018224634694350716214666112402802
            }

            function MONTGOMERY_TWISTED_CURVE_COEFFS() -> z0, z1 {
                z0 := 16772280239760917788496391897731603718812008455956943122563801666366297604776
                z1 := 568440292453150825972223760836185707764922522371208948902804025364325400423
            }

            // Group order of alt_bn128, see https://eips.ethereum.org/EIPS/eip-196
            function P() -> ret {
                ret := 21888242871839275222246405745257275088696311157297823662689037894645226208583
            }

            function R2_MOD_P() -> ret {
                ret := 3096616502983703923843567936837374451735540968419076528771170197431451843209
            }

            function R3_MOD_P() -> ret {
                ret := 14921786541159648185948152738563080959093619838510245177710943249661917737183
            }

            function N_PRIME() -> ret {
                ret := 111032442853175714102588374283752698368366046808579839647964533820976443843465
            }

            function NAF_REPRESENTATIVE() ->  ret {
                ret := 7186291078002685655833716264194454051281486193901198152801
            }

            function FP6_ZERO() -> z00, z01, z10, z11, z20, z21 {
                z00 := 0
                z01 := 0
                z10 := 0
                z11 := 0
                z20 := 0
                z21 := 0
            }

            function G2_INFINITY() -> z00, z01, z02, z10, z11, z12 {
                z00 := 0
                z01 := 0
                z02 := 0
                z10 := 0
                z11 := 0
                z12 := 0
            }

            function FP12_ONE() -> z000, z001, z010, z011, z100, z101, z110, z111, z200, z201, z210, z211 {
                z000 := MONTGOMERY_ONE()
                z001 := 0
                z010 := 0
                z011 := 0
                z100 := 0
                z101 := 0
                z110 := 0
                z111 := 0
                z200 := 0
                z201 := 0
                z210 := 0
                z211 := 0
            }

            function PAIR_LENGTH() -> ret {
                ret := 0xc0
            }

			// HELPER FUNCTIONS

			/// @dev Executes the `precompileCall` opcode.
			function precompileCall(precompileParams, gasToBurn) -> ret {
				// Compiler simulation for calling `precompileCall` opcode
				ret := verbatim_2i_1o("precompile", precompileParams, gasToBurn)
			}

			function burnGas() {
				// Precompiles that do not have a circuit counterpart
				// will burn the provided gas by calling this function.
				precompileCall(0, gas())
		  	}

            // CONSOLE.LOG Caller
            // It prints 'val' in the node console and it works using the 'mem'+0x40 memory sector
            function console_log(val) -> {
                let log_address := 0x000000000000000000636F6e736F6c652e6c6f67
                // load the free memory pointer
                let freeMemPointer := mload(0x600)
                // store the function selector of log(uint256) in memory
                mstore(freeMemPointer, 0xf82c50f1)
                // store the first argument of log(uint256) in the next memory slot
                mstore(add(freeMemPointer, 0x20), val)
                // call the console.log contract
                if iszero(staticcall(gas(),log_address,add(freeMemPointer, 28),add(freeMemPointer, 0x40),0x00,0x00)) {
                    revert(0,0)
                }
            }

            function console_log_fp12(a000, a001, a010, a011, a100, a101, a110, a111, a200, a201, a210, a211) {
                console_log(a000)
                console_log(a001)
                console_log(a010)
                console_log(a011)
                console_log(a100)
                console_log(a101)
                console_log(a110)
                console_log(a111)
                console_log(a200)
                console_log(a201)
                console_log(a210)
                console_log(a211)
            }

            /// @notice Checks if the LSB of a number is 1.
            /// @param x The number to check.
            /// @return ret True if the LSB is 1, false otherwise.
            function lsbIsOne(x) -> ret {
                ret := and(x, ONE())
            }

            // MONTGOMERY

			function submod(minuend, subtrahend, modulus) -> difference {
                difference := addmod(minuend, sub(modulus, subtrahend), modulus)
            }

            function binaryExtendedEuclideanAlgorithm(base) -> inv {
                // Precomputation of 1 << 255
                let mask := 57896044618658097711785492504343953926634992332820282019728792003956564819968
                let modulus := P()
                // modulus >> 255 == 0 -> modulus & 1 << 255 == 0
                let modulusHasSpareBits := iszero(and(modulus, mask))

                let u := base
                let v := modulus
                // Avoids unnecessary reduction step.
                let b := R2_MOD_P()
                let c := ZERO()

                for {} and(iszero(eq(u, ONE())), iszero(eq(v, ONE()))) {} {
                    for {} iszero(and(u, ONE())) {} {
                        u := shr(1, u)
                        let current_b := b
                        let current_b_is_odd := and(current_b, ONE())
                        if iszero(current_b_is_odd) {
                            b := shr(1, b)
                        }
                        if current_b_is_odd {
                            let new_b := add(b, modulus)
                            let carry := or(lt(new_b, b), lt(new_b, modulus))
                            b := shr(1, new_b)

                            if and(iszero(modulusHasSpareBits), carry) {
                                b := or(b, mask)
                            }
                        }
                    }

                    for {} iszero(and(v, ONE())) {} {
                        v := shr(1, v)
                        let current_c := c
                        let current_c_is_odd := and(current_c, ONE())
                        if iszero(current_c_is_odd) {
                            c := shr(1, c)
                        }
                        if current_c_is_odd {
                            let new_c := add(c, modulus)
                            let carry := or(lt(new_c, c), lt(new_c, modulus))
                            c := shr(1, new_c)

                            if and(iszero(modulusHasSpareBits), carry) {
                                c := or(c, mask)
                            }
                        }
                    }

                    switch gt(v, u)
                    case 0 {
                        u := sub(u, v)
                        if lt(b, c) {
                            b := add(b, modulus)
                        }
                        b := sub(b, c)
                    }
                    case 1 {
                        v := sub(v, u)
                        if lt(c, b) {
                            c := add(c, modulus)
                        }
                        c := sub(c, b)
                    }
                }

                switch eq(u, ONE())
                case 0 {
                    inv := c
                }
                case 1 {
                    inv := b
                }
            }

            function overflowingAdd(augend, addend) -> sum, overflowed {
                sum := add(augend, addend)
                overflowed := or(lt(sum, augend), lt(sum, addend))
            }

            function getHighestHalfOfMultiplication(multiplicand, multiplier) -> ret {
                ret := verbatim_2i_1o("mul_high", multiplicand, multiplier)
            }

            // https://en.wikipedia.org/wiki/Montgomery_modular_multiplication//The_REDC_algorithm
            function REDC(lowest_half_of_T, higher_half_of_T) -> S {
                let q := mul(lowest_half_of_T, N_PRIME())
                let a_high := add(higher_half_of_T, getHighestHalfOfMultiplication(q, P()))
                let a_low, overflowed := overflowingAdd(lowest_half_of_T, mul(q, P()))
                if overflowed {
                    a_high := add(a_high, ONE())
                }
                S := a_high
                if iszero(lt(a_high, P())) {
                    S := sub(a_high, P())
                }
            }

            // Transforming into the Montgomery form -> REDC((a mod N)(R2 mod N))
            function intoMontgomeryForm(a) -> ret {
                    let higher_half_of_a := getHighestHalfOfMultiplication(mod(a, P()), R2_MOD_P())
                    let lowest_half_of_a := mul(mod(a, P()), R2_MOD_P())
                    ret := REDC(lowest_half_of_a, higher_half_of_a)
            }

            // Transforming out of the Montgomery form -> REDC(a * R mod N)
            function outOfMontgomeryForm(m) -> ret {
                    let higher_half_of_m := ZERO()
                    let lowest_half_of_m := m 
                    ret := REDC(lowest_half_of_m, higher_half_of_m)
            }

            function montgomeryAdd(augend, addend) -> ret {
                ret := addmod(augend, addend, P())
            }

            function montgomerySub(minuend, subtrahend) -> ret {
                ret := montgomeryAdd(minuend, sub(P(), subtrahend))
            }

            // Multipling field elements in Montgomery form -> REDC((a * R mod N)(b * R mod N))
            function montgomeryMul(multiplicand, multiplier) -> ret {
                let higher_half_of_product := getHighestHalfOfMultiplication(multiplicand, multiplier)
                let lowest_half_of_product := mul(multiplicand, multiplier)
                ret := REDC(lowest_half_of_product, higher_half_of_product)
            }

            function montgomeryModExp(
                base,
                exponent
            ) -> pow {
                pow := MONTGOMERY_ONE()
                let aux_exponent := exponent
                for { } gt(aux_exponent, ZERO()) { } {
                    if mod(aux_exponent, TWO()) {
                        pow := montgomeryMul(pow, base)
                    }
                    aux_exponent := shr(1, aux_exponent)
                    base := montgomeryMul(base, base)
                }
            }

            function montgomeryModularInverse(a) -> invmod {
                invmod := binaryExtendedEuclideanAlgorithm(a)
            }

            function montgomeryDiv(dividend, divisor) -> quotient {
                quotient := montgomeryMul(dividend, montgomeryModularInverse(divisor))
            }

			// CURVE ARITHMETICS

            /// @notice Checks if a coordinate is on the curve group order.
            /// @dev A coordinate is on the curve group order if it is on the range [0, curveGroupOrder).
            /// @param coordinate The coordinate to check.
            /// @return ret True if the coordinate is in the range, false otherwise.
            function coordinateIsOnGroupOrder(coordinate) -> ret {
                ret := lt(coordinate, P())
            }
            
            /// @notice Checks if affine coordinates are on the curve group order.
            /// @dev Affine coordinates are on the curve group order if both coordinates are on the range [0, curveGroupOrder).
            /// @param x The x coordinate to check.
            /// @param y The y coordinate to check.
            /// @return ret True if the coordinates are in the range, false otherwise.
            function affinePointCoordinatesAreOnGroupOrder(x, y) -> ret {
                ret := and(coordinateIsOnGroupOrder(x), coordinateIsOnGroupOrder(y))
            }

            // G1

            function g1AffinePointIsInfinity(x, y) -> ret {
                ret := and(iszero(x), iszero(y))
            }

			function g1AffinePointIsOnCurve(x, y) -> ret {
				if g1AffinePointIsInfinity(x,y) {
                    ret := 1
                }
                if iszero(g1AffinePointIsInfinity(x, y)) { 
                    let ySquared := mulmod(y, y, P())
                    let xSquared := mulmod(x, x, P())
                    let xQubed := mulmod(xSquared, x, P())
                    let xQubedPlusThree := addmod(xQubed, THREE(), P())

                    ret := eq(ySquared, xQubedPlusThree)
                }
            }


            // G2

            function g2ProjectiveIntoAffine(xp0, xp1, yp0, yp1, zp0, zp1) -> xr0, xr1, yr0, yr1 {
				let z0, z1 := fp2Inv(zp0, zp1)
				xr0, xr1 := fp2Mul(xp0, xp1, zp0, zp1)
				yr0, yr1 := fp2Mul(yp0, yp1, zp0, zp1)
			}

			// G2 function to go back and forth between affine and projective coordinates
			function g2ProjectiveFromAffine(xp0, xp1, yp0, yp1) -> xr0, xr1, yr0, yr1, zr0, zr1 {
				xr0 := xp0
				xr1 := xp1
				yr0 := yp0
				yr1 := yp1
				zr0 := MONTGOMERY_ONE()
				zr1 := ZERO()
				if and(eq(xp0, ZERO()), eq(xp1, ZERO())) {
					if and(eq(yp0, ZERO()), eq(yp1, ZERO())) {
						xr0 := MONTGOMERY_ONE()
						// xr1 is already ZERO()
						yr0 := MONTGOMERY_ONE()
						// yr1 is already ZERO()
						zr0 := ZERO()
						// zr1 is already ZERO()
					}
				}
			}

            function g2AffinePointIsInfinity(x0, x1, y0, y1) -> ret {
                ret := iszero(or(or(x0, x1), or(y0, y1)))
            }

			function g2AffinePointIsOnCurve(x0, x1, y0, y1) -> ret {
                if g2AffinePointIsInfinity(x0, x1, y0, y1) {
                    ret := 1
                }
                if iszero(g2AffinePointIsInfinity(x0, x1, y0, y1)) {
                    let a0, a1 := MONTGOMERY_TWISTED_CURVE_COEFFS()
                    let b0, b1 := fp2Mul(x0, x1, x0, x1)
                    b0, b1 := fp2Mul(b0, b1, x0, x1)
                    b0, b1 := fp2Add(b0, b1, a0, a1)
                    let c0, c1 := fp2Mul(y0, y1, y0, y1)
                    ret := and(eq(b0, c0), eq(b1, c1))
                }
			}

            function g2ProjectivePointIsInfinity(x0, x1, y0, y1, z0, z1) -> ret {
                ret := iszero(or(z0, z1))
            }

			// Neg function for G2 in affine coordinates
			function g2Neg(x0, x1, y0, y1) -> nx0, nx1, ny0, ny1 {
				nx0 := x0
				nx1 := x1
				ny0, ny1 := fp2Neg(y0, y1)
			}

            function g2Eq(xp0, xp1, yp0, yp1, zp0, zp1, xq0, xq1, yq0, yq1, zq0, zq1) -> ret{
                ret := and(eq(xp0, xq0), eq(xp1, xq1))
                ret := and(eq(yp0, yq0), eq(yp1, yq1))
                ret := and(eq(zp0, zq0), eq(zp1, zq1))
            }

            function g2ProjectiveDouble(xp0, xp1, yp0, yp1, zp0, zp1) -> xr0, xr1, yr0, yr1, zr0, zr1 {
                let x_squared0, x_squared1 := fp2Mul(xp0, xp1, xp0, xp1)
                let temp00, temp01 := fp2Add(x_squared0, x_squared1, x_squared0, x_squared1)
                let t0, t1 := fp2Add(x_squared0, x_squared1, temp00, temp01)
                let yz0, yz1 := fp2Mul(yp0, yp1, zp0, zp1)
                let u0, u1 := fp2Add(yz0, yz1, yz0, yz1)
                temp00, temp01 := fp2Mul(xp0, xp1, yp0, yp1)
                let uxy0, uxy1 := fp2Mul(u0, u1, temp00, temp01)
                let v0, v1 := fp2Add(uxy0, uxy1, uxy0, uxy1)
                temp00, temp01 := fp2Mul(t0, t1, t0, t1)
                let temp10, temp11 := fp2Add(v0, v1, v0, v1)
                let w0, w1 := fp2Sub(temp00, temp01, temp10, temp11)

                xr0, xr1 := fp2Mul(u0, u1, w0, w1)
                let uy0, uy1 := fp2Mul(u0, u1, yp0, yp1)
                let uy_squared0, uy_squared1 := fp2Mul(uy0, uy1, uy0, uy1)
                temp00, temp01 := fp2Sub(v0, v1, w0, w1)
                temp10, temp11 := fp2Mul(t0, t1, temp00, temp01)
                let temp20, temp21 := fp2Add(uy_squared0, uy_squared1, uy_squared0, uy_squared1)
                yr0, yr1 := fp2Sub(temp10, temp11, temp20, temp21)
                let temp30, temp31 := fp2Mul(u0, u1, u0, u1)
                zr0, zr1 := fp2Mul(u0, u1, temp30, temp31)
            }

            function g2ScalarMul(xp0, xp1, yp0, yp1, zp0, zp1, scalar) -> xr0, xr1, yr0, yr1, zr0, zr1 {
                switch scalar
                case 0x02 {
                    xr0, xr1, yr0, yr1, zr0, zr1 := g2ProjectiveDouble(xp0, xp1, yp0, yp1, zp0, yp1)
                }
                default {
                    let xq0 := xp0
                    let xq1 := xp1
                    let yq0 := yp0
                    let yq1 := yp1
                    let zq0 := zp0
                    let zq1 := zp1
                    let xr0 := MONTGOMERY_ONE()
                    let xr1 := ZERO()
                    let yr0 := MONTGOMERY_ONE()
                    let yr1 := ZERO()
                    let zr0 := ZERO()
                    let zr1 := ZERO()
                    for {} scalar {} {
                        if lsbIsOne(scalar) {
                            let qIsInfinity := g2ProjectivePointIsInfinity(xq0, xq1, yq0, yq1, zq0, zq1)
                            let rIsInfinity := g2ProjectivePointIsInfinity(xr0, xr1, yr0, yr1, zr0, zr1)
                            if and(rIsInfinity, qIsInfinity) {
                                // Infinity + Infinity = Infinity
                                break
                            }
                            if and(rIsInfinity, iszero(qIsInfinity)) {
                                // Infinity + P = P
                                xr0 := xq0
                                xr1 := xq1
                                yr0 := yq0
                                yr1 := yq1
                                zr0 := zq0
                                zr1 := zq1
        
                                xq0, xq1, yq0, yq1, zq0, zq1 := g2ProjectiveDouble(xq0, xq1, yq0, yq1, zq0, zq1)
                                // Check next bit
                                scalar := shr(1, scalar)
                                continue
                            }
                            if and(iszero(rIsInfinity), qIsInfinity) {
                                // P + Infinity = P
                                break
                            }
                            if g2Eq(xr0, xr1, montgomerySub(ZERO(), yr0), montgomerySub(ZERO(), yr1), zr0, zr1, xq0, xq1, yq0, yq1, zq0, zq1) {
                                // P + (-P) = Infinity
                                xr0 := ZERO()
                                xr1 := ZERO()
                                yr0 := ZERO()
                                yr1 := ZERO()
                                zr0 := ZERO()
                                zr1 := ZERO()
        
                                xq0, xq1, yq0, yq1, zq0, zq1 := g2ProjectiveDouble(xq0, xq1, yq0, yq1, zq0, zq1)
                                // Check next bit
                                scalar := shr(1, scalar)
                                continue
                            }
                            // FIXME: This condition is not addapted for fp2
                            if g2Eq(xr0, xr1, xq0, xq1, yr0, yr1, yq0, yq1, zr0, zr1, zq0, zq1) {
                                // P + P = 2P
                                xr0, xr1, yr0, yr1, zr0, zr1 := g2ProjectiveDouble(xr0, xr1, yr0, yr1, zr0, zr1)
        
                                xq0 := xr0
                                xq1 := xr1
                                yq0 := yr0
                                yq1 := yr1
                                zq0 := zr0
                                zq1 := zr1
                                // Check next bit
                                scalar := shr(1, scalar)
                                continue
                            }
        
                            // P1 + P2 = P3
        
                            let t00, t01 := fp2Mul(yq0, yq1, zr0, zr1)
                            let t10, t11 := fp2Mul(yr0, yr1, zq0, zq1)
                            let t0, t1 := fp2Sub(t00, t01, t10, t11)
                            let u00, u01 := fp2Mul(xq0, zq1, zr0, zr1)
                            let u10, u11 := fp2Mul(xr0, xr1, zq0, zq1)
                            let u0, u1 := fp2Sub(u00, u01, u10, u11)
                            let u20, u21 := fp2Mul(u0, u1, u0, u1)
                            let u30, u31 := fp2Mul(u20, u21, u0, u1)
                            let v0, v1 := fp2Mul(zq0, zq1, zr0, zr1)

                            let temp00, temp01 := fp2Add(u00, u01, u10, u11)
                            let temp10, temp11 := fp2Mul(u20, u21, temp00, temp01)
                            let temp20, temp21 := fp2Mul(t0, t1, t0, t1)
                            let temp30, temp31 := fp2Mul(temp20, temp21, v0, v1)
                            let w0, w1 := fp2Sub(temp30, temp31, temp10, temp11)
            
                            xr0, xr1 := fp2Mul(u0, u1, w0, w1)
                            
                            temp00, temp01 := fp2Mul(u00, u01, u20, u21)
                            temp10, temp11 := fp2Sub(temp00, temp01, w0, w1)
                            temp20, temp21 := fp2Mul(t00, t01, u30, u31)
                            temp30, temp31 := fp2Mul(t0, t1, temp10, temp11)
                            yr0, yr1 := fp2Sub(temp30, temp31, temp20, temp21)

                            zr0, zr1 := fp2Mul(u30, u31, v0, v1)
                        }
        
                        xq0, xq1, yq0, yq1, zq0, zq1 := g2ProjectiveDouble(xq0, xq1, yq0, yq1, zq0, zq1)
                        // Check next bit
                        scalar := shr(1, scalar)
                    }
                }
            }

            // FP2 ARITHMETHICS

            function fp2Add(a00, a01, b00, b01) -> c00, c01 {
                c00 := montgomeryAdd(a00, b00)
                c01 := montgomeryAdd(a01, b01)
            }

            function fp2Sub(a00, a01, b00, b01) -> c00, c01 {
                c00 := montgomerySub(a00, b00)
                c01 := montgomerySub(a01, b01)
            }

            function fp2ScalarMul(a00, a01, scalar) -> c00, c01 {
                c00 := montgomeryMul(a00, scalar)
                c01 := montgomeryMul(a01, scalar)
            }

            function fp2Mul(a00, a01, b00, b01) -> c00, c01 {
                c00 := montgomerySub(montgomeryMul(a00, b00), montgomeryMul(a01, b01))
                c01 := montgomeryAdd(montgomeryMul(a00, b01), montgomeryMul(a01, b00))
            }

            function fp2Neg(a00, a01) -> c00, c01 {
                c00, c01 := fp2Sub(ZERO(), ZERO(), a00, a01)
            }

            function fp2Inv(a00, a01) -> c00, c01 {
                let t0 := montgomeryMul(a00, a00)
                let t1 := montgomeryMul(a01, a01)
                t0 := montgomeryAdd(t0, t1)
                t1 := montgomeryModularInverse(t0)

                c00 := montgomeryMul(a00, t1)
                c01 := montgomerySub(ZERO(), montgomeryMul(a01, t1))
            }

            function mulByXi(a00, a01) -> c00, c01 {
                let t0, t1 := fp2ScalarMul(a00, a01, intoMontgomeryForm(8))
                c00 := montgomerySub(montgomeryAdd(t0, a00), a01)
                c01 := montgomeryAdd(montgomeryAdd(t1, a00), a01)
            }

            function fp2Conjugate(a00, a01) -> c00, c01 {
                c00 := a00
                c01 := montgomerySub(ZERO(), a01)
            }

            // FP6 ARITHMETHICS

            function fp6Add(a00, a01, a10, a11, a20, a21, b00, b01, b10, b11, b20, b21) -> c00, c01, c10, c11, c20, c21 {
                c00, c01 := fp2Add(a00, a01, b00, b01)
                c10, c11 := fp2Add(a10, a11, b10, b11)
                c20, c21 := fp2Add(a20, a21, b20, b21)
            }

            function fp6Sub(a00, a01, a10, a11, a20, a21, b00, b01, b10, b11, b20, b21) -> c00, c01, c10, c11, c20, c21 {
                c00, c01 := fp2Sub(a00, a01, b00, b01)
                c10, c11 := fp2Sub(a10, a11, b10, b11)
                c20, c21 := fp2Sub(a20, a21, b20, b21)
            }

            function mulByGamma(a00, a01, a10, a11, a20, a21) -> c00, c01, c10, c11, c20, c21 {
                c00, c01 := mulByXi(a20, a21)
                c10 := a00
                c11 := a01
                c20 := a10
                c21 := a11
            }

            function fp6Mul(a00, a01, a10, a11, a20, a21, b00, b01, b10, b11, b20, b21) -> c00, c01, c10, c11, c20, c21 {
                let t00, t01 := fp2Mul(a00, a01, b00, b01)
                let t10, t11 := fp2Mul(a10, a11, b10, b11)
                let t20, t21 := fp2Mul(a20, a21, b20, b21)

                let tmp0, temp1 := fp2Add(a10, a11, a20, a21)
                let tmp2, tmp3 := fp2Add(b10, b11, b20, b21)
                let tmp4, tmp5 := fp2Mul(tmp0, temp1, tmp2, tmp3)
                let tmp6, tmp7 := fp2Sub(tmp4, tmp5, t10, t11)
                let tmp8, tmp9 := fp2Sub(tmp6, tmp7, t20, t21)
                let tmp10, tmp11 := mulByXi(tmp8, tmp9)
                c00, c01 := fp2Add(tmp10, tmp11, t00, t01)

                tmp0, temp1 := fp2Add(a00, a01, a10, a11)
                tmp2, tmp3 := fp2Add(b00, b01, b10, b11)
                tmp4, tmp5 := fp2Mul(tmp0, temp1, tmp2, tmp3)
                tmp6, tmp7 := fp2Sub(tmp4, tmp5, t00, t01)
                tmp8, tmp9 := fp2Sub(tmp6, tmp7, t10, t11)
                tmp10, tmp11 := mulByXi(t20, t21)
                c10, c11 := fp2Add(tmp8, tmp9, tmp10, tmp11)

                tmp0, temp1 := fp2Add(a00, a01, a20, a21)
                tmp2, tmp3 := fp2Add(b00, b01, b20, b21)
                tmp4, tmp5 := fp2Mul(tmp0, temp1, tmp2, tmp3)
                tmp6, tmp7 := fp2Sub(tmp4, tmp5, t00, t01)
                tmp8, tmp9 := fp2Sub(tmp6, tmp7, t20, t21)
                c20, c21 := fp2Add(tmp8, tmp9, t10, t11)
            }

            function fp6Neg(a00, a01, a10, a11, a20, a21) -> c00, c01, c10, c11, c20, c21 {
                c00, c01 := fp2Neg(a00, a01)
                c10, c11 := fp2Neg(a10, a11)
                c20, c21 := fp2Neg(a20, a21)
            }

            function fp6MulByIndependentTerm(a00, a01, a10, a11, a20, a21, b00, b01) -> c00, c01, c10, c11, c20, c21 {
                c00, c01 := fp2Mul(a00, a01, b00, b01)
                c10, c11 := fp2Mul(a01, a10, b00, b01)
                c20, c21 := fp2Mul(a10, a11, b00, b01)
            }

            function fp6MulByIndependentAndLinearTerm(a00, a01, a10, a11, a20, a21, b00, b01, b10, b11) -> c00, c01, c10, c11, c20, c21 {
                let t00, t01 := fp2Mul(a00, a01, b00, b01)
                let t10, t11 := fp2Mul(a10, a11, b10, b11)

                let tmp00, tmp01 := fp2Add(a10, a11, a20, a21)
                tmp00, tmp01 := fp2Mul(tmp00, tmp01, b10, b11)
                tmp00, tmp01 := fp2Sub(tmp00, tmp01, t10, t11)
                tmp00, tmp01 := mulByXi(tmp00, tmp01)
                c00, c01 := fp2Add(t00, t01, tmp00, tmp01)

                tmp00, tmp01 := fp2Add(a00, a01, a10, a11)
                let tmp10, tmp11 := fp2Add(b00, b01, b10, b11)
                tmp00, tmp01 := fp2Mul(tmp00, tmp01, tmp10, tmp11)
                tmp00, tmp01 := fp2Sub(tmp00, tmp01, t00, t01)
                c10, c11 := fp2Sub(tmp00, tmp01, t10, t11)

                tmp00, tmp01 := fp2Mul(a20, a21, b00, b01)
                c20, c21 := fp2Add(tmp00, tmp01, t10, t11)
            }

            function fp6Square(a00, a01, a10, a11, a20, a21) -> c00, c01, c10, c11, c20, c21 {
                let tmp0, tmp1 := fp2Mul(a00, a01, a10, a11)
                tmp0, tmp1 := fp2Add(tmp0, tmp1, tmp0, tmp1)

                let tmp2, tmp3 := fp2Mul(a20, a21, a20, a21)
                let tmp4, tmp5 := mulByXi(tmp2, tmp3)
                c10, c11 := fp2Add(tmp4, tmp5, tmp0, tmp1)

                c20, c21 := fp2Sub(tmp0, tmp1, tmp2, tmp3)

                let tmp6, tmp7 := fp2Mul(a00, a01, a00, a01)
                let tmp8, tmp9 := fp2Sub(a00, a01, a10, a11)
                tmp0, tmp1 := fp2Add(tmp8, tmp9, a20, a21)
            
                let tmp10, tmp11 := fp2Mul(a10, a11, a20, a21)
                tmp2, tmp3 := fp2Add(tmp10, tmp11, tmp10, tmp11)
                tmp0, tmp1 := fp2Mul(tmp0, tmp1, tmp0, tmp1)

                let tmp12, tmp13 := mulByXi(tmp2, tmp3)
                c00, c01 := fp2Add(tmp12, tmp13, tmp6, tmp7)

                let tmp14, tmp15 := fp2Add(c20, c21, tmp0, tmp1)
                tmp14, tmp15 := fp2Add(tmp14, tmp15, tmp2, tmp3)
                c20, c21 := fp2Sub(tmp14, tmp15, tmp6, tmp7)
            
            }

            function fp6Inv(a00, a01, a10, a11, a20, a21) -> c00, c01, c10, c11, c20, c21 {
                let t00, t01 := fp2Mul(a00, a01, a00, a01)
                let t10, t11 := fp2Mul(a10, a11, a10, a11)
                let t20, t21 := fp2Mul(a20, a21, a20, a21)
                let t30, t31 := fp2Mul(a00, a01, a10, a11)
                let t40, t41 := fp2Mul(a00, a01, a20, a21)
                let t50, t51 := fp2Mul(a20, a21, a10, a11)
                let t50Xi, t51Xi := mulByXi(t50, t51)
                c00, c01 := fp2Sub(t00, t01, t50Xi, t51Xi)
                let t20Xi, t21Xi := mulByXi(t20, t21)
                c10, c11 := fp2Sub(t20Xi, t21Xi, t30, t31)
                c20, c21 := fp2Sub(t10, t11, t40, t41)
                let t60, t61 := fp2Mul(a00, a01, c00, c01)
                let a20Xi, a21Xi := mulByXi(a20, a21)
                let a20XiC10, a21XiC11 := fp2Mul(a20Xi, a21Xi, c10, c11)
                t60, t61 := fp2Add(t60, t61, a20XiC10, a21XiC11)
                let a10Xi, a11Xi := mulByXi(a10, a11)
                let a10XiC20, a11XiC21 := fp2Mul(a10Xi, a11Xi, c20, c21)
                t60, t61 := fp2Add(t60, t61, a10XiC20, a11XiC21)
                t60, t61 := fp2Inv(t60, t61)
                c00, c01 := fp2Mul(c00, c01, t60, t61)
                c10, c11 := fp2Mul(c10, c11, t60, t61)
                c20, c21 := fp2Mul(c20, c21, t60, t61)
            }

            // FP12 ARITHMETHICS

            function fp12Add(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121, b000, b001, b010, b011, b020, b021, b100, b101, b110, b111, b120, b121) -> c000, c001, c010, c011, c020, c021, c100, c101, c110, c111, c120, c121 {
                c000, c001, c010, c011, c020, c021 := fp6Add(a000, a001, a010, a011, a020, a021, b000, b001, b010, b011, b020, b021)
                c100, c101, c110, c111, c120, c121 := fp6Add(a100, a101, a110, a111, a120, a121, b100, b101, b110, b111, b120, b121)
            }

            function fp12Sub(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121, b000, b001, b010, b011, b020, b021, b100, b101, b110, b111, b120, b121) -> c000, c001, c010, c011, c020, c021, c100, c101, c110, c111, c120, c121 {
                c000, c001, c010, c011, c020, c021 := fp6Sub(a000, a001, a010, a011, a020, a021, b000, b001, b010, b011, b020, b021)
                c100, c101, c110, c111, c120, c121 := fp6Sub(a100, a101, a110, a111, a120, a121, b100, b101, b110, b111, b120, b121)
            }

            function fp12Mul(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121, b000, b001, b010, b011, b020, b021, b100, b101, b110, b111, b120, b121) -> c000, c001, c010, c011, c020, c021, c100, c101, c110, c111, c120, c121 {
                let t000, t001, t010, t011, t020, t021 := fp6Mul(a000, a001, a010, a011, a020, a021, b000, b001, b010, b011, b020, b021)
                let t100, t101, t110, t111, t120, t121 := fp6Mul(a100, a101, a110, a111, a120, a121, b100, b101, b110, b111, b120, b121)
                let t200, t201, t210, t211, t220, t221 := mulByGamma(t100, t101, t110, t111, t120, t121)
                c000, c001, c010, c011, c020, c021 := fp6Add(t000, t001, t010, t011, t020, t021, t200, t201, t210, t211, t220, t221)
                let t300, t301, t310, t311, t320, t321 := fp6Add(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121)
                let t400, t401, t410, t411, t420, t421 := fp6Add(b000, b001, b010, b011, b020, b021, b100, b101, b110, b111, b120, b121)
                c100, c101, c110, c111, c120, c121 := fp6Mul(t300, t301, t310, t311, t320, t321, t400, t401, t410, t411, t420, t421)
                c100, c101, c110, c111, c120, c121 := fp6Sub(c100, c101, c110, c111, c120, c121, t000, t001, t010, t011, t020, t021)
                c100, c101, c110, c111, c120, c121 := fp6Sub(c100, c101, c110, c111, c120, c121, t100, t101, t110, t111, t120, t121)
            }

            function fp12Square(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121) -> c000, c001, c010, c011, c020, c021, c100, c101, c110, c111, c120, c121 {
                let t100, t101, t110, t111, t120, t121 := fp6Sub(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121)
                let t200, t201, t210, t211, t220, t221 := mulByGamma(a100, a101, a110, a111, a120, a121)
                let t300, t301, t310, t311, t320, t321 := fp6Sub(a000, a001, a010, a011, a020, a021, t200, t201, t210, t211, t220, t221)
                let t400, t401, t410, t411, t420, t421 := fp6Mul(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121)
                let t500, t501, t510, t511, t520, t521 := fp6Mul(t100, t101, t110, t111, t120, t121, t300, t301, t310, t311, t320, t321)
                let t600, t601, t610, t611, t620, t621 := fp6Add(t400, t401, t410, t411, t420, t421, t500, t501, t510, t511, t520, t521)
                c100, c101, c110, c111, c120, c121 := fp6Add(t400, t401, t410, t411, t420, t421, t400, t401, t410, t411, t420, t421)
                let t700, t701, t710, t711, t720, t721 := mulByGamma(t400, t401, t410, t411, t420, t421)
                c000, c001, c010, c011, c020, c021 := fp6Add(t600, t601, t610, t611, t620, t621, t700, t701, t710, t711, t720, t721)
            }

            function fp12Inv(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121) -> c000, c001, c010, c011, c020, c021, c100, c101, c110, c111, c120, c121 {
                let t000, t001, t010, t011, t020, t021 := fp6Square(a000, a001, a010, a011, a020, a021)
                let t100, t101, t110, t111, t120, t121 := fp6Square(a100, a101, a110, a111, a120, a121)
                let t200, t201, t210, t211, t220, t221 := mulByGamma(t100, t101, t110, t111, t120, t121)
                t000, t001, t010, t011, t020, t021 := fp6Sub(t000, t001, t010, t011, t020, t021, t200, t201, t210, t211, t220, t221)
                t100, t101, t110, t111, t120, t121 := fp6Inv(t000, t001, t010, t011, t020, t021)
                c000, c001, c010, c011, c020, c021 := fp6Mul(a000, a001, a010, a011, a020, a021, t100, t101, t110, t111, t120, t121)
                let z00, z01, z10, z11, z20, z21 :=  FP6_ZERO()
                c100, c101, c110, c111, c120, c121 := fp6Mul(a100, a101, a110, a111, a120, a121,t100, t101, t110, t111, t120, t121)
                c100, c101, c110, c111, c120, c121 := fp6Sub(z00, z01, z10, z11, z20, z21, c100, c101, c110, c111, c120, c121)
            }

            function fp12Expt(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121) -> c000, c001, c010, c011, c020, c021, c100, c101, c110, c111, c120, c121 {
                let t000, t001, t010, t011, t020, t021, t100, t101, t110, t111, t120, t121 := fp12CyclotomicSquare(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121)
                let t200, t201, t210, t211, t220, t221, t300, t301, t310, t311, t320, t321 := fp12CyclotomicSquare(t000, t001, t010, t011, t020, t021, t100, t101, t110, t111, t120, t121)
                c000, c001, c010, c011, c020, c021, c100, c101, c110, c111, c120, c121 := fp12CyclotomicSquare(t200, t201, t210, t211, t220, t221, t300, t301, t310, t311, t320, t321)
                let t400, t401, t410, t411, t420, t421, t500, t501, t510, t511, t520, t521 := fp12CyclotomicSquare(c000, c001, c010, c011, c020, c021, c100, c101, c110, c111, c120, c121)

                let t600, t601, t610, t611, t620, t621, t700, t701, t710, t711, t720, t721 := fp12Mul(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121, t400, t401, t410, t411, t420, t421, t500, t501, t510, t511, t520, t521)
                t400, t401, t410, t411, t420, t421, t500, t501, t510, t511, t520, t521 := fp12Mul(t600, t601, t610, t611, t620, t621, t700, t701, t710, t711, t720, t721, t000, t001, t010, t011, t020, t021, t100, t101, t110, t111, t120, t121)
                let t800, t801, t810, t811, t820, t821, t900, t901, t910, t911, t920, t921 := fp12Mul(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121, t400, t401, t410, t411, t420, t421, t500, t501, t510, t511, t520, t521)
                let t1000, t1001, t1010, t1011, t1020, t1021, t1100, t1101, t1110, t1111, t1120, t1121 := fp12Mul(c000, c001, c010, c011, c020, c021, c100, c101, c110, c111, c120, c121, t600, t601, t610, t611, t620, t621, t700, t701, t710, t711, t720, t721)
                let t1200, t1201, t1210, t1211, t1220, t1221, t1300, t1301, t1310, t1311, t1320, t1321 := fp12CyclotomicSquare(t600, t601, t610, t611, t620, t621, t700, t701, t710, t711, t720, t721)
                t800, t801, t810, t811, t820, t821, t900, t901, t910, t911, t920, t921 := fp12Mul(t800, t801, t810, t811, t820, t821, t900, t901, t910, t911, t920, t921, t400, t401, t410, t411, t420, t421, t500, t501, t510, t511, t520, t521)
                t400, t401, t410, t411, t420, t421, t500, t501, t510, t511, t520, t521 := fp12Mul(t800, t801, t810, t811, t820, t821, t900, t901, t910, t911, t920, t921, t000, t001, t010, t011, t020, t021, t100, t101, t110, t111, t120, t121)
                t1200, t1201, t1210, t1211, t1220, t1221, t1300, t1301, t1310, t1311, t1320, t1321 := nSquare(t1200, t1201, t1210, t1211, t1220, t1221, t1300, t1301, t1310, t1311, t1320, t1321, 6)
                t200, t201, t210, t211, t220, t221, t300, t301, t310, t311, t320, t321 := fp12Mul(t1200, t1201, t1210, t1211, t1220, t1221, t1300, t1301, t1310, t1311, t1320, t1321, t200, t201, t210, t211, t220, t221, t300, t301, t310, t311, t320, t321)
                t200, t201, t210, t211, t220, t221, t300, t301, t310, t311, t320, t321 := fp12Mul(t200, t201, t210, t211, t220, t221, t300, t301, t310, t311, t320, t321, t1000, t1001, t1010, t1011, t1020, t1021, t1100, t1101, t1110, t1111, t1120, t1121)
                t200, t201, t210, t211, t220, t221, t300, t301, t310, t311, t320, t321 := nSquare(t200, t201, t210, t211, t220, t221, t300, t301, t310, t311, t320, t321, 7)
                t1000, t1001, t1010, t1011, t1020, t1021, t1100, t1101, t1110, t1111, t1120, t1121 := fp12Mul(t200, t201, t210, t211, t220, t221, t300, t301, t310, t311, t320, t321, t1000, t1001, t1010, t1011, t1020, t1021, t1100, t1101, t1110, t1111, t1120, t1121)
                t1000, t1001, t1010, t1011, t1020, t1021, t1100, t1101, t1110, t1111, t1120, t1121 := nSquare(t1000, t1001, t1010, t1011, t1020, t1021, t1100, t1101, t1110, t1111, t1120, t1121, 8)
                t1000, t1001, t1010, t1011, t1020, t1021, t1100, t1101, t1110, t1111, t1120, t1121 := fp12Mul(t1000, t1001, t1010, t1011, t1020, t1021, t1100, t1101, t1110, t1111, t1120, t1121, t400, t401, t410, t411, t420, t421, t500, t501, t510, t511, t520, t521)
                t000, t001, t010, t011, t020, t021, t100, t101, t110, t111, t120, t121 := fp12Mul(t1000, t1001, t1010, t1011, t1020, t1021, t1100, t1101, t1110, t1111, t1120, t1121, t000, t001, t010, t011, t020, t021, t100, t101, t110, t111, t120, t121)
                t000, t001, t010, t011, t020, t021, t100, t101, t110, t111, t120, t121 := nSquare(t000, t001, t010, t011, t020, t021, t100, t101, t110, t111, t120, t121, 6)
                t600, t601, t610, t611, t620, t621, t700, t701, t710, t711, t720, t721 := fp12Mul(t000, t001, t010, t011, t020, t021, t100, t101, t110, t111, t120, t121, t600, t601, t610, t611, t620, t621, t700, t701, t710, t711, t720, t721)
                t600, t601, t610, t611, t620, t621, t700, t701, t710, t711, t720, t721 := nSquare(t600, t601, t610, t611, t620, t621, t700, t701, t710, t711, t720, t721, 8)
                t600, t601, t610, t611, t620, t621, t700, t701, t710, t711, t720, t721 := fp12Mul(t600, t601, t610, t611, t620, t621, t700, t701, t710, t711, t720, t721, t400, t401, t410, t411, t420, t421, t500, t501, t510, t511, t520, t521)
                t600, t601, t610, t611, t620, t621, t700, t701, t710, t711, t720, t721 := nSquare(t600, t601, t610, t611, t620, t621, t700, t701, t710, t711, t720, t721, 6)
                t600, t601, t610, t611, t620, t621, t700, t701, t710, t711, t720, t721 := fp12Mul(t600, t601, t610, t611, t620, t621, t700, t701, t710, t711, t720, t721, t400, t401, t410, t411, t420, t421, t500, t501, t510, t511, t520, t521)
                t600, t601, t610, t611, t620, t621, t700, t701, t710, t711, t720, t721 := nSquare(t600, t601, t610, t611, t620, t621, t700, t701, t710, t711, t720, t721, 10)
                t800, t801, t810, t811, t820, t821, t900, t901, t910, t911, t920, t921 := fp12Mul(t600, t601, t610, t611, t620, t621, t700, t701, t710, t711, t720, t721, t800, t801, t810, t811, t820, t821, t900, t901, t910, t911, t920, t921)
                t800, t801, t810, t811, t820, t821, t900, t901, t910, t911, t920, t921 := nSquare(t800, t801, t810, t811, t820, t821, t900, t901, t910, t911, t920, t921, 6)
                t400, t401, t410, t411, t420, t421, t500, t501, t510, t511, t520, t521 := fp12Mul(t400, t401, t410, t411, t420, t421, t500, t501, t510, t511, t520, t521, t800, t801, t810, t811, t820, t821, t900, t901, t910, t911, t920, t921)
                c000, c001, c010, c011, c020, c021, c100, c101, c110, c111, c120, c121 := fp12Mul(t400, t401, t410, t411, t420, t421, t500, t501, t510, t511, t520, t521, c000, c001, c010, c011, c020, c021, c100, c101, c110, c111, c120, c121)
            }

            function fp12Conjugate(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121) -> c000, c001, c010, c011, c020, c021, c100, c101, c110, c111, c120, c121 {
                c000 := a000
                c001 := a001
                c010 := a010
                c011 := a011
                c020 := a020
                c021 := a021
                c100, c101, c110, c111, c120, c121 := fp6Neg(a100, a101, a110, a111, a120, a121)
            }

            function fp12CyclotomicSquare(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121) -> c000, c001, c010, c011, c020, c021, c100, c101, c110, c111, c120, c121 {
                let t00, t01 := fp2Mul(a110, a111, a110, a111)
                let t10, t11 := fp2Mul(a000, a001, a000, a001)
                let t20, t21 := fp2Add(a110, a111, a000, a001)
                t20, t21 := fp2Mul(t20, t21, t20, t21)
                t20, t21 := fp2Sub(t20, t21, t00, t01)
                t20, t21 := fp2Sub(t20, t21, t10, t11)
                let t30, t31 := fp2Mul(a020, a021, a020, a021)
                let t40, t41 := fp2Mul(a100, a101, a100, a101)
                let t50, t51 := fp2Add(a020, a021, a100, a101)
                t50, t51 := fp2Mul(t50, t51, t50, t51)
                t50, t51 := fp2Sub(t50, t51, t30, t31)
                t50, t51 := fp2Sub(t50, t51, t40, t41)
                let t60, t61 := fp2Mul(a120, a121, a120, a121)
                let t70, t71 := fp2Mul(a010, a011, a010, a011)
                let t80, t81 := fp2Add(a120, a121, a010, a011)
                t80, t81 := fp2Mul(t80, t81, t80, t81)
                t80, t81 := fp2Sub(t80, t81, t60, t61)
                t80, t81 := fp2Sub(t80, t81, t70, t71)
                t80, t81 := mulByXi(t80, t81)
                t00, t01 := mulByXi(t00, t01)
                t00, t01 := fp2Add(t00, t01, t10, t11)
                t30, t31 := mulByXi(t30, t31)
                t30, t31 := fp2Add(t30, t31, t40, t41)
                t60, t61 := mulByXi(t60, t61)
                t60, t61 := fp2Add(t60, t61, t70, t71)

                c000, c001 := fp2Sub(t00, t01, a000, a001)
                c000, c001 := fp2Add(c000, c001, c000, c001)
                c000, c001 := fp2Add(c000, c001, t00, t01)
            
                c010, c011 := fp2Sub(t30, t31, a010, a011)
                c010, c011 := fp2Add(c010, c011, c010, c011)
                c010, c011 := fp2Add(c010, c011, t30, t31)
            
                c020, c021 := fp2Sub(t60, t61, a020, a021)
                c020, c021 := fp2Add(c020, c021, c020, c021)
                c020, c021 := fp2Add(c020, c021, t60, t61)
            
                c100, c101 := fp2Add(t80, t81, a100, a101)
                c100, c101 := fp2Add(c100, c101, c100, c101)
                c100, c101 := fp2Add(c100, c101, t80, t81)
            
                c110, c111 := fp2Add(t20, t21, a110, a111)
                c110, c111 := fp2Add(c110, c111, c110, c111)
                c110, c111 := fp2Add(c110, c111, t20, t21)
            
                c120, c121 := fp2Add(t50, t51, a120, a121)
                c120, c121 := fp2Add(c120, c121, c120, c121)
                c120, c121 := fp2Add(c120, c121, t50, t51)
            }

            function nSquare(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121, n) -> c000, c001, c010, c011, c020, c021, c100, c101, c110, c111, c120, c121 {
                c000 := a000
                c001 := a001
                c010 := a010
                c011 := a011
                c020 := a020
                c021 := a021
                c100 := a100
                c101 := a101
                c110 := a110
                c111 := a111
                c120 := a120
                c121 := a121
                for { let i := 0 } lt(i, n) { i := add(i, ONE()) } {
                    c000, c001, c010, c011, c020, c021, c100, c101, c110, c111, c120, c121 := fp12CyclotomicSquare(c000, c001, c010, c011, c020, c021, c100, c101, c110, c111, c120, c121)
                }
            }

            // FROBENIUS

            function frobenius(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121) -> c00, c01, c10, c11, c20, c21, c30, c31, c40, c41, c50, c51 {
                let t10, t11 := fp2Conjugate(a000, a001)
                let t20, t21 := fp2Conjugate(a100, a101)
                let t30, t31 := fp2Conjugate(a010, a011)
                let t40, t41 := fp2Conjugate(a110, a111)
                let t50, t51 := fp2Conjugate(a020, a021)
                let t60, t61 := fp2Conjugate(a120, a121)

                t20, t21 := mulByGamma11(t20, t21)
                t30, t31 := mulByGamma12(t30, t31)
                t40, t41 := mulByGamma13(t40, t41)
                t50, t51 := mulByGamma14(t50, t51)
                t60, t61 := mulByGamma15(t60, t61)

                c00 := t10
                c01 := t11
                c10 := t30
                c11 := t31
                c20 := t50
                c21 := t51
                c30 := t20
                c31 := t21
                c40 := t40
                c41 := t41
                c50 := t60
                c51 := t61
            }

            function frobeniusSquare(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121) -> c00, c01, c10, c11, c20, c21, c30, c31, c40, c41, c50, c51 {
                let t10 := a000 
                let t11 := a001
                let t20, t21 := mulByGamma21(a100, a101)
                let t30, t31 := mulByGamma22(a010, a011)
                let t40, t41 := mulByGamma23(a110, a111)
                let t50, t51 := mulByGamma24(a020, a021)
                let t60, t61 := mulByGamma25(a120, a121)

                c00 := t10
                c01 := t11
                c10 := t30
                c11 := t31
                c20 := t50
                c21 := t51
                c30 := t20
                c31 := t21
                c40 := t40
                c41 := t41
                c50 := t60
                c51 := t61
            }

            function frobeniusCube(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121) -> c00, c01, c10, c11, c20, c21, c30, c31, c40, c41, c50, c51 {
                let t10, t11 := fp2Conjugate(a000, a001)
                let t20, t21 := fp2Conjugate(a100, a101)
                let t30, t31 := fp2Conjugate(a010, a011)
                let t40, t41 := fp2Conjugate(a110, a111)
                let t50, t51 := fp2Conjugate(a020, a021)
                let t60, t61 := fp2Conjugate(a120, a121)

                t20, t21 := mulByGamma31(t20, t21)
                t30, t31 := mulByGamma32(t30, t31)
                t40, t41 := mulByGamma33(t40, t41)
                t50, t51 := mulByGamma34(t50, t51)
                t60, t61 := mulByGamma35(t60, t61)

                c00 := t10
                c01 := t11
                c10 := t30
                c11 := t31
                c20 := t50
                c21 := t51
                c30 := t20
                c31 := t21
                c40 := t40
                c41 := t41
                c50 := t60
                c51 := t61
            }

            // GAMMA_1_i

            function mulByGamma11(a00, a01) -> c00, c01 {
                let g00 := 1334504125441109323775816677333762124980877086439557453392802825656291576071
                let g01 := 7532670101108748540749979597679923402841328813027773483599019704565791010162
                c00, c01 := fp2Mul(a00, a01, g00, g01)
            }

            function mulByGamma12(a00, a01) -> c00, c01 {
                let g00 := 11461073415658098971834280704587444395456423268720245247603935854280982113072
                let g01 := 17373957475705492831721812124331982823197004514106338927670775596783233550167
                c00, c01 := fp2Mul(a00, a01, g00, g01)
            }

            function mulByGamma13(a00, a01) -> c00, c01 {
                let g00 := 16829996427371746075450799880956928810557034522864196246648550205375670302249
                let g01 := 20140510615310063345578764457068708762835443761990824243702724480509675468743
                c00, c01 := fp2Mul(a00, a01, g00, g01)
            }

            function mulByGamma14(a00, a01) -> c00, c01 {
                let g00 := 9893659366031634526915473325149983243417508801286144596494093251884139331218
                let g01 := 16514792769865828027011044701859348114858257981779976519405133026725453154633
                c00, c01 := fp2Mul(a00, a01, g00, g01)
            }

            function mulByGamma15(a00, a01) -> c00, c01 {
                let g00 := 8443299194457421137480282511969901974227997168695360756777672575877693116391
                let g01 := 21318636632361225103955470331868462398471880609949088574192481281746934874025
                c00, c01 := fp2Mul(a00, a01, g00, g01)
            }

            // GAMMA_2_i

            function mulByGamma21(a00, a01) -> c00, c01 {
                let g0 := 1881798392815877688876180778159931906057091683336018750908411925848733129714
                c00, c01 := fp2ScalarMul(a00, a01, g0)
            }

            function mulByGamma22(a00, a01) -> c00, c01 {
                let g0 := 17419166386535333598783630241015674584964973961482396687585055285806960741276
                c00, c01 := fp2ScalarMul(a00, a01, g0)
            }

            function mulByGamma23(a00, a01) -> c00, c01 {
                let g0 := 15537367993719455909907449462855742678907882278146377936676643359958227611562
                c00, c01 := fp2ScalarMul(a00, a01, g0)
            }

            function mulByGamma24(a00, a01) -> c00, c01 {
                let g0 := 20006444479023397533370224967097343182639219473961804911780625968796493078869
                c00, c01 := fp2ScalarMul(a00, a01, g0)
            }

            function mulByGamma25(a00, a01) -> c00, c01 {
                let g0 := 4469076485303941623462775504241600503731337195815426975103982608838265467307
                c00, c01 := fp2ScalarMul(a00, a01, g0)
            }

            // GAMMA_3_i

            function mulByGamma31(a00, a01) -> c00, c01 {
                let g00 := 3649295186494431467217240962842301358951278585756714214031945394966344685949
                let g01 := 17372117152826387298350653207345606612066102743297871578090761045572893546809
                c00, c01 := fp2Mul(a00, a01, g00, g01)
            }

            function mulByGamma32(a00, a01) -> c00, c01 {
                let g00 := 14543349330631744552586812320441124107441202078168618766450326117520897829805
                let g01 := 4646831431411403714092965637071058625728899792817054432901795759277546050476
                c00, c01 := fp2Mul(a00, a01, g00, g01)
            }

            function mulByGamma33(a00, a01) -> c00, c01 {
                let g00 := 5058246444467529146795605864300346278139276634433627416040487689269555906334
                let g01 := 1747732256529211876667641288188566325860867395306999418986313414135550739840
                c00, c01 := fp2Mul(a00, a01, g00, g01)
            }

            function mulByGamma34(a00, a01) -> c00, c01 {
                let g00 := 3025265262868802913511075437173590487338001780554453930995247874855578067679
                let g01 := 10425289180741305073643362413949631488281652900778689227251281048515799234257
                c00, c01 := fp2Mul(a00, a01, g00, g01)
            }

            function mulByGamma35(a00, a01) -> c00, c01 {
                let g00 := 9862576063628467829192720579684130652367741026604221989510773554027227469215
                let g01 := 16681752610922605480353377694363181135019829138759259603037557916788351015335
                c00, c01 := fp2Mul(a00, a01, g00, g01)
            }

			// PAIRING FUNCTIONS

			function doubleStep(xq0, xq1, yq0, yq1, zq0, zq1) -> l00, l01, l10, l11, l20, l21, l30, l31, l40, l41, l50, l51, xt0, xt1, yt0, yt1, zt0, zt1 {
                let zero := ZERO()
                let twoInv := MONTGOMERY_TWO_INV()
                let t00, t01 := fp2Mul(xq0, xq1, yq0, yq1)
                let t10, t11 := fp2ScalarMul(t00, t01, twoInv)
                let t20, t21 := fp2Mul(yq0, yq1, yq0, yq1)
                let t30, t31 := fp2Mul(zq0, zq1, zq0, zq1)
                let t40, t41 := fp2Add(t30, t31, t30, t31)
                t40, t41 := fp2Add(t40, t41, t30, t31)
                let t50, t51 := MONTGOMERY_TWISTED_CURVE_COEFFS()
                t50, t51 := fp2Mul(t40, t41, t50, t51)
                let t60, t61 :=fp2Add(t50, t51, t50, t51)
                t60, t61 := fp2Add(t60, t61, t50, t51)
                let t70, t71 := fp2Add(t20, t21, t60, t61)
                t70, t71 := fp2ScalarMul(t70, t71, twoInv)
                let t80, t81 := fp2Add(yq0, yq1, zq0, zq1)
                t80, t81 := fp2Mul(t80, t81, t80, t81)
                let t90, t91 := fp2Add(t30, t31, t20, t21)
                t80, t81 := fp2Sub(t80, t81, t90, t91)
                let t100, t101 := fp2Sub(t50, t51, t20, t21)
                let t110, t111 := fp2Mul(xq0, xq1, xq0, xq1)
                let t120, t121 := fp2Mul(t50, t51, t50, t51)
                let t130, t131 := fp2Add(t120, t121, t120, t121)
                t130, t131 := fp2Add(t130, t131, t120, t121)

                // l0
                l00, l01 := fp2Neg(t80, t81)
                l10 := zero
                l11 := zero
                l20 := zero
                l21 := zero

                // l1
                l30, l31 := fp2Add(t110, t111, t110, t111)
                l30, l31 := fp2Add(l30, l31, t110, t111)
                
                // l2
                l40 := t100
                l41 := t101

                l50 := zero
                l51 := zero

                // Tx
                xt0, xt1 := fp2Sub(t20, t21, t60, t61)
                xt0, xt1 := fp2Mul(xt0, xt1, t10, t11)

                // Ty
                yt0, yt1 := fp2Mul(t70, t71, t70, t71)
                yt0, yt1 := fp2Sub(yt0, yt1, t130, t131)

                // Tz
                zt0, zt1 := fp2Mul(t20, t21, t80, t81)
            }


            function mixed_addition_step(xq0, xq1, yq0, yq1, xt0, xt1, yt0, yt1, zt0, zt1) -> l00, l01, l10, l11, l20, l21, l30, l31, l40, l41, l50, l51, xc0, xc1, yc0, yc1, zc0, zc1 {
                let zero := ZERO()
                let t00, t01 := fp2Mul(yq0,yq1,zt0,zt1)
                let t10, t11 := fp2Sub(yt0, yt1, t00, t01)
                t00, t01 := fp2Mul(xq0, xq1, zt0, zt1)
                let t20, t21 := fp2Sub(xt0, xt1, t00, t01)
                let t30, t31 := fp2Mul(t10, t11, t10, t11)
                let t40, t41 := fp2Mul(t20, t21, t20, t21)
                let t50, t51 := fp2Mul(t20, t21, t40, t41)
                let t60, t61 := fp2Mul(zt0, zt1, t30, t31)
                let t70, t71 := fp2Mul(xt0, xt1, t40, t41)
                t00, t01 := fp2Add(t70, t71, t70, t71)
                let t80, t81 := fp2Add(t50, t51, t60, t61)
                t80, t81 := fp2Sub(t80, t81, t00, t01)
                t00, t01 := fp2Mul(yt0, yt1, t50, t51)

                // Xc0
                xc0, xc1 := fp2Mul(t20, t21, t80, t81)

                // Yc0
                yc0, yc1 := fp2Sub(t70, t71, t80, t81)
                yc0, yc1 := fp2Mul(yc0, yc1, t10, t11)
                yc0, yc1 := fp2Sub(yc0, yc1, t00, t01)

                // Zc0
                zc0, zc1 := fp2Mul(t50, t51, zt0, zt1)
                t00, t01 := fp2Mul(t20, t21, yq0, yq1)
                let t90, t91 := fp2Mul(xq0, xq1, t10, t11)
                t90, t91 := fp2Sub(t90, t91, t00, t01)

                // l0
                l00 := t20
                l01 := t21
                l10 := zero
                l11 := zero
                l20 := zero
                l21 := zero

                // l1
                l30, l31 := fp2Neg(t10, t11)

                // l2
                l40 := t90
                l41 := t91
                l50 := zero
                l51 := zero
            }

            function finalExponentiation(a000, a001, a010, a011, a020, a021, a100, a101, a110, a111, a120, a121) -> f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121 {
                f000 := a000
                f001 := a001
                f010 := a010
                f011 := a011
                f020 := a020
                f021 := a021
                f100 := a100
                f101 := a101
                f110 := a110
                f111 := a111
                f120 := a120
                f121 := a121

                // Easy Part
                let t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121 := fp12Conjugate(f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121)
                f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121 := fp12Inv(f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121)
                t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121 := fp12Mul(t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121, f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121)
                let t1000, t1001, t1010, t1011, t1020, t1021, t1100, t1101, t1110, t1111, t1120, t1121 := frobeniusSquare(t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121)
                f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121 := fp12Mul(t1000, t1001, t1010, t1011, t1020, t1021, t1100, t1101, t1110, t1111, t1120, t1121, t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121)

                // Hard Part
                t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121 := fp12Expt(f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121)
                t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121 := fp12Conjugate(t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121)
                t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121 := fp12CyclotomicSquare(t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121)
                t1000, t1001, t1010, t1011, t1020, t1021, t1100, t1101, t1110, t1111, t1120, t1121 := fp12CyclotomicSquare(t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121)
                t1000, t1001, t1010, t1011, t1020, t1021, t1100, t1101, t1110, t1111, t1120, t1121 := fp12Mul(t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121, t1000, t1001, t1010, t1011, t1020, t1021, t1100, t1101, t1110, t1111, t1120, t1121)
                let t2000, t2001, t2010, t2011, t2020, t2021, t2100, t2101, t2110, t2111, t2120, t2121 := fp12Expt(t1000, t1001, t1010, t1011, t1020, t1021, t1100, t1101, t1110, t1111, t1120, t1121)
                t2000, t2001, t2010, t2011, t2020, t2021, t2100, t2101, t2110, t2111, t2120, t2121 := fp12Conjugate(t2000, t2001, t2010, t2011, t2020, t2021, t2100, t2101, t2110, t2111, t2120, t2121)
                let t3000, t3001, t3010, t3011, t3020, t3021, t3100, t3101, t3110, t3111, t3120, t3121 := fp12Conjugate(t1000, t1001, t1010, t1011, t1020, t1021, t1100, t1101, t1110, t1111, t1120, t1121)
                t1000, t1001, t1010, t1011, t1020, t1021, t1100, t1101, t1110, t1111, t1120, t1121 := fp12Mul(t2000, t2001, t2010, t2011, t2020, t2021, t2100, t2101, t2110, t2111, t2120, t2121, t3000, t3001, t3010, t3011, t3020, t3021, t3100, t3101, t3110, t3111, t3120, t3121)
                t3000, t3001, t3010, t3011, t3020, t3021, t3100, t3101, t3110, t3111, t3120, t3121 := fp12CyclotomicSquare(t2000, t2001, t2010, t2011, t2020, t2021, t2100, t2101, t2110, t2111, t2120, t2121)
                let t4000, t4001, t4010, t4011, t4020, t4021, t4100, t4101, t4110, t4111, t4120, t4121 := fp12Expt(t3000, t3001, t3010, t3011, t3020, t3021, t3100, t3101, t3110, t3111, t3120, t3121)
                t4000, t4001, t4010, t4011, t4020, t4021, t4100, t4101, t4110, t4111, t4120, t4121 := fp12Mul(t4000, t4001, t4010, t4011, t4020, t4021, t4100, t4101, t4110, t4111, t4120, t4121, t1000, t1001, t1010, t1011, t1020, t1021, t1100, t1101, t1110, t1111, t1120, t1121)
                t3000, t3001, t3010, t3011, t3020, t3021, t3100, t3101, t3110, t3111, t3120, t3121 := fp12Mul(t4000, t4001, t4010, t4011, t4020, t4021, t4100, t4101, t4110, t4111, t4120, t4121, t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121)
                t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121 := fp12Mul(t2000, t2001, t2010, t2011, t2020, t2021, t2100, t2101, t2110, t2111, t2120, t2121, t4000, t4001, t4010, t4011, t4020, t4021, t4100, t4101, t4110, t4111, t4120, t4121)
                t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121 := fp12Mul(t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121, f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121)
                t2000, t2001, t2010, t2011, t2020, t2021, t2100, t2101, t2110, t2111, t2120, t2121 := frobenius(t3000, t3001, t3010, t3011, t3020, t3021, t3100, t3101, t3110, t3111, t3120, t3121)
                t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121 := fp12Mul(t2000, t2001, t2010, t2011, t2020, t2021, t2100, t2101, t2110, t2111, t2120, t2121, t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121)
                t2000, t2001, t2010, t2011, t2020, t2021, t2100, t2101, t2110, t2111, t2120, t2121 := frobeniusSquare(t4000, t4001, t4010, t4011, t4020, t4021, t4100, t4101, t4110, t4111, t4120, t4121)
                t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121 := fp12Mul(t2000, t2001, t2010, t2011, t2020, t2021, t2100, t2101, t2110, t2111, t2120, t2121, t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121)
                t2000, t2001, t2010, t2011, t2020, t2021, t2100, t2101, t2110, t2111, t2120, t2121 := fp12Conjugate(f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121)
                t2000, t2001, t2010, t2011, t2020, t2021, t2100, t2101, t2110, t2111, t2120, t2121 := fp12Mul(t2000, t2001, t2010, t2011, t2020, t2021, t2100, t2101, t2110, t2111, t2120, t2121, t3000, t3001, t3010, t3011, t3020, t3021, t3100, t3101, t3110, t3111, t3120, t3121)
                t2000, t2001, t2010, t2011, t2020, t2021, t2100, t2101, t2110, t2111, t2120, t2121 := frobeniusCube(t2000, t2001, t2010, t2011, t2020, t2021, t2100, t2101, t2110, t2111, t2120, t2121)
                f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121 := fp12Mul(t2000, t2001, t2010, t2011, t2020, t2021, t2100, t2101, t2110, t2111, t2120, t2121, t0000, t0001, t0010, t0011, t0020, t0021, t0100, t0101, t0110, t0111, t0120, t0121)
            }

            function millerLoop(xq0, xq1, yq0, yq1, xp, yp) -> f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121 {
                let t00, t01, t10, t11, t20, t21 := g2ProjectiveFromAffine(xq0, xq1, yq0, yq1)
                let mq00, mq01, mq10, mq11 := g2Neg(xq0, xq1, yq0, yq1)
                f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121 := FP12_ONE()
                let naf := NAF_REPRESENTATIVE()
                let n_iter := 65
                let l00, l01, l10, l11, l20, l21, l30, l31, l40, l41, l50, l51 := FP12_ONE()

                for {let i := 0} lt(i, n_iter) { i := add(i, 1) } {
                    f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121 := fp12Square(f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121)

                    l00, l01, l10, l11, l20, l21, l30, l31, l40, l41, l50, l51, t00, t01, t10, t11, t20, t21 := doubleStep(t00, t01, t10, t11, t20, t21)
                    l00, l01 := fp2ScalarMul(l00, l01, yp)
                    l30, l31 := fp2ScalarMul(l30, l31, xp)
                    f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121 := fp12Mul(f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121, l00, l01, l10, l11, l20, l21, l30, l31, l40, l41, l50, l51)

                    // naf digit = 1
                    if and(naf, 2) {
                        l00, l01, l10, l11, l20, l21, l30, l31, l40, l41, l50, l51, t00, t01, t10, t11, t20, t21 := mixed_addition_step(xq0, xq1, yq0, yq1, t00, t01, t10, t11, t20, t21)
                        l00, l01 := fp2ScalarMul(l00, l01, yp)
                        l30, l31 := fp2ScalarMul(l30, l31, xp)
                        f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121 := fp12Mul(f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121, l00, l01, l10, l11, l20, l21, l30, l31, l40, l41, l50, l51)
                    }

                    // naf digit = -1
                    if and(naf, 4) {
                        l00, l01, l10, l11, l20, l21, l30, l31, l40, l41, l50, l51, t00, t01, t10, t11, t20, t21 := mixed_addition_step(mq00, mq01, mq10, mq11, t00, t01, t10, t11, t20, t21)
                        l00, l01 := fp2ScalarMul(l00, l01, yp)
                        l30, l31 := fp2ScalarMul(l30, l31, xp)
                        f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121 := fp12Mul(f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121, l00, l01, l10, l11, l20, l21, l30, l31, l40, l41, l50, l51)
                    }

                    naf := shr(3, naf)
                }

                let r00, r01 := fp2Conjugate(xq0, xq1)
                let r10, r11 := fp2Conjugate(yq0, yq1)
                r00, r01 := mulByGamma12(r00, r01)
                r10, r11 := mulByGamma13(r10, r11)
                
                let r20, r21 := mulByGamma22(xq0, xq1)
                let r30, r31 := mulByGamma23(yq0, yq1)
                r30, r31 := fp2Neg(r30, r31)

                l00, l01, l10, l11, l20, l21, l30, l31, l40, l41, l50, l51, t00, t01, t10, t11, t20, t21 := mixed_addition_step(r00, r01, r10, r11, t00, t01, t10, t11, t20, t21)
                l00, l01 := fp2ScalarMul(l00, l01, yp)
                l30, l31 := fp2ScalarMul(l30, l31, xp)
                f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121 := fp12Mul(f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121, l00, l01, l10, l11, l20, l21, l30, l31, l40, l41, l50, l51)

                l00, l01, l10, l11, l20, l21, l30, l31, l40, l41, l50, l51, t00, t01, t10, t11, t20, t21 := mixed_addition_step(r20, r21, r30, r31, t00, t01, t10, t11, t20, t21)
                l00, l01 := fp2ScalarMul(l00, l01, yp)
                l30, l31 := fp2ScalarMul(l30, l31, xp)
                f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121 := fp12Mul(f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121, l00, l01, l10, l11, l20, l21, l30, l31, l40, l41, l50, l51)
            }

            function pair(g1_x, g1_y, g2_x0, g2_x1, g2_y0, g2_y1) -> f000, f001, f010, f011, f100, f101, f110, f111, f200, f201, f210, f211 {
                f000, f001, f010, f011, f100, f101, f110, f111, f200, f201, f210, f211 := millerLoop(g2_x0, g2_x1, g2_y0, g2_y1, g1_x, g1_y)
                f000, f001, f010, f011, f100, f101, f110, f111, f200, f201, f210, f211 := finalExponentiation(f000, f001, f010, f011, f100, f101, f110, f111, f200, f201, f210, f211)
            }

			////////////////////////////////////////////////////////////////
            //                      FALLBACK
            ////////////////////////////////////////////////////////////////

		  	let inputSize := calldatasize()

			// Empty input is valid and results in returning one.
		  	if eq(inputSize, ZERO()) {
				mstore(0, ONE())
				return(0, 32)
			}

			// If the input length is not a multiple of 192, the call fails.
            if mod(inputSize, PAIR_LENGTH()) {
                // Bad pairing input
				burnGas()
            }

            let r000, r001, r010, r011, r020, r021, r100, r101, r110, r111, r120, r121 := FP12_ONE()

			// Calldata "parsing"
			for { let i := 0 } lt(i, inputSize) { i := add(i, PAIR_LENGTH()) } {
				/* G1 */
				calldatacopy(i, i, 32) // x
				calldatacopy(add(i, 32), add(i, 32), 32) // y

				let g1_x := mload(i)
				let g1_y := mload(add(i, 32))

                if iszero(and(coordinateIsOnGroupOrder(g1_x), coordinateIsOnGroupOrder(g1_y))) {
                    burnGas()
                }

				if iszero(g1AffinePointIsOnCurve(g1_x, g1_y)) {
					burnGas()
				}

				/* G2 */
				let g2_x1_offset := add(i, 64)
				let g2_x0_offset := add(i, 96)
				let g2_y1_offset := add(i, 128)
				let g2_y0_offset := add(i, 160)

				calldatacopy(g2_x1_offset, g2_x1_offset, 32)
				calldatacopy(g2_x0_offset, g2_x0_offset, 32)
				calldatacopy(g2_y1_offset, g2_y1_offset, 32)
				calldatacopy(g2_y0_offset, g2_y0_offset, 32)

				let g2_x1 := mload(g2_x1_offset)
				let g2_x0 := mload(g2_x0_offset)
				let g2_y1 := mload(g2_y1_offset)
				let g2_y0 := mload(g2_y0_offset)

                // TODO: Double check if this is right
                if iszero(and(coordinateIsOnGroupOrder(g2_x0), coordinateIsOnGroupOrder(g2_x1))) {
                    burnGas()
                }

                // TODO: Double check if this is right
                if iszero(and(coordinateIsOnGroupOrder(g2_y0), coordinateIsOnGroupOrder(g2_y1))) {
                    burnGas()
                }

                if g2AffinePointIsInfinity(g2_x0, g2_x1, g2_y0, g2_y1) {
                    continue
                }

                g1_x := intoMontgomeryForm(g1_x)
                g1_y := intoMontgomeryForm(g1_y)
                g2_x0 := intoMontgomeryForm(g2_x0)
                g2_x1 := intoMontgomeryForm(g2_x1)
                g2_y0 := intoMontgomeryForm(g2_y0)
                g2_y1 := intoMontgomeryForm(g2_y1)

                if iszero(g2AffinePointIsOnCurve(g2_x0, g2_x1, g2_y0, g2_y1)) {
					burnGas()
				}

                if g1AffinePointIsInfinity(g1_x, g1_y) {
                    continue
                }

                let f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121 := pair(g1_x, g1_y, g2_x0, g2_x1, g2_y0, g2_y1)

                r000, r001, r010, r011, r020, r021, r100, r101, r110, r111, r120, r121 := fp12Mul(r000, r001, r010, r011, r020, r021, r100, r101, r110, r111, r120, r121, f000, f001, f010, f011, f020, f021, f100, f101, f110, f111, f120, f121)
			}

            // Pair check

            if and(and(eq(r000, MONTGOMERY_ONE()), iszero(r001)), and(iszero(r010), iszero(r011))) {
                if and(and(iszero(r020), iszero(r021)), and(iszero(r100), iszero(r101))) {
                    if and(and(iszero(r110), iszero(r111)), and(iszero(r120), iszero(r121))) {
                        mstore(0, ONE())
                        return(0, 32)
                    }
                }
            }

            mstore(0, ZERO())
			return(0, 32)
		}
	}
}
