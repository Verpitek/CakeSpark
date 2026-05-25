"""
Python 3 equivalent of bench.cake — same 17 sections, same algorithms, same output.
"""

import math
import random
import time
import sys


# ---- Error simulation (CakeSpark err-type propagation) ----
class ErrVal:
    def __init__(self, msg):
        self.msg = msg

    def __repr__(self):
        return self.msg


def cake_add(a, b):
    if isinstance(a, ErrVal): return a
    if isinstance(b, ErrVal): return b
    return a + b


def cake_div(a, b):
    if isinstance(a, ErrVal): return a
    if isinstance(b, ErrVal): return b
    if b == 0: return ErrVal("division by zero")
    return a // b


def cake_mod(a, b):
    if isinstance(a, ErrVal): return a
    if isinstance(b, ErrVal): return b
    if b == 0: return ErrVal("modulo by zero")
    return a % b


def cake_typeof(v):
    if isinstance(v, ErrVal):  return "err"
    if isinstance(v, int):     return "int"
    if isinstance(v, float):   return "float"
    if isinstance(v, str):     return "str"
    if isinstance(v, list):    return "arr"
    return "unknown"


def cake_tostr(v):
    if isinstance(v, ErrVal): return v.msg
    if isinstance(v, list):   return "[" + ", ".join(str(e) for e in v) + "]"
    return str(v)


def cake_toint(v):
    if isinstance(v, ErrVal):  return v
    if isinstance(v, float):   return int(v)
    if isinstance(v, str):
        try:    return int(float(v))
        except: return ErrVal("cannot convert to int")
    return int(v)


def cake_tofloat(v):
    if isinstance(v, ErrVal):  return v
    if isinstance(v, str):
        try:    return float(v)
        except: return ErrVal("cannot convert to float")
    return float(v)


def cake_sqrt(n):
    if isinstance(n, ErrVal): return n
    if n < 0: return ErrVal("sqrt of negative")
    return int(math.floor(math.sqrt(n)))


# ============================================================
# Benchmark sections (1-17)
# ============================================================

def bench_1():
    a, b, i = 0, 1, 0
    while i < 30:
        tmp = a; a = b; b = tmp + b; i += 1
    print(f"1. fib(31) = {b}")


def bench_2():
    limit = 1000
    sieve = [1] * limit
    p = 2
    while p < limit:
        if sieve[p] == 1:
            mul_p = p + p
            while mul_p < limit:
                sieve[mul_p] = 0
                mul_p += p
        p += 1
    prime_sum = 0; pc = 2
    while pc < limit:
        if sieve[pc] == 1: prime_sum += pc
        pc += 1
    print(f"2. sum of primes < {limit} = {prime_sum}")


def bench_3():
    pangram = "the quick brown fox jumps over the lazy dog"
    words = pangram.split(" ")
    words_count = len(words)
    piped = "|".join(words)
    fox_pos = pangram.find("fox")
    tail = pangram[fox_pos:]
    greeted = "hello " + "world"
    greet_len = len(greeted)
    print(f"3. str ops: {words_count} words, fox at {fox_pos}, greet len={greet_len}")


def bench_4():
    arr200 = [random.randint(1, 10000) for _ in range(200)]
    arr200_len = len(arr200)
    arr200.sort()
    min_v = arr200[0]; mid_v = arr200[99]; max_v = arr200[199]
    has_min = 1 if min_v in arr200 else 0
    has_max = 1 if max_v in arr200 else 0
    popped_v = arr200.pop()
    after_pop = len(arr200)
    print(f"4. array: len={arr200_len} min={min_v} mid={mid_v} max={max_v} after_pop={after_pop}")


def bench_5():
    fac_n = 1; fac_result = 1
    def multiply():
        nonlocal fac_n, fac_result
        fac_result *= fac_n; fac_n += 1
    for _ in range(12): multiply()
    print(f"5. factorial(12) via blocks = {fac_result}")


def bench_6():
    scope_i = 0; scope_acc = 0
    while scope_i < 50:
        scope_mod = scope_i % 3
        if scope_mod == 0:   scope_acc += 1
        elif scope_mod == 1: scope_acc += 10
        else:                scope_acc += 100
        scope_i += 1
    print(f"6. scope stress: acc={scope_acc}")


def bench_7():
    greek = ["alpha", "beta", "gamma", "delta", "epsilon"]
    greek_str = ""
    for letter in greek: greek_str += letter + ","
    print(f"7. each iter: {len(greek_str)} chars")


def bench_8():
    big_int = 314159
    big_float = cake_tofloat(big_int)
    big_str = cake_tostr(big_float)
    big_str_len = len(big_str)
    parsed_int = cake_toint("42")
    adjusted = cake_add(parsed_int, 100)
    adj_type = cake_typeof(adjusted)
    print(f"8. types: int={adjusted} type={adj_type} str_len={big_str_len}")


def bench_9():
    bw_a = 0x3F; bw_b = 0x15
    bw_and = bw_a & bw_b
    bw_or  = bw_a | bw_b
    bw_xor = bw_a ^ bw_b
    bw_not = ~bw_a
    bw_shl = bw_a << 3
    bw_shr = bw_a >> 2
    bw_sum = bw_and + bw_or + bw_xor + bw_not + bw_shl + bw_shr
    print(f"9. bitwise sum: {bw_sum}")


def bench_10():
    dl_sum = 0; dl_i = 0
    while dl_i < 20:
        dl_j = 0
        while dl_j < 20:
            dl_sum += dl_i + dl_j
            if dl_sum > 5000: break
            dl_j += 1
        dl_i += 1
    print(f"10. nested loop sum: {dl_sum}")


def bench_11():
    pow_val = 2 ** 16
    sqrt_val = cake_sqrt(1024)
    abs_val = abs(-42)
    min_val = min(7, 3); max_val = max(7, 3)
    math_sum = pow_val + sqrt_val + abs_val + min_val + max_val
    print(f"11. math sum: {math_sum}")


def bench_12():
    div0_err = cake_div(1, 0)
    div0_type = cake_typeof(div0_err)
    div0_msg = cake_tostr(div0_err)
    err_pass = 0
    mod0_err = cake_mod(1, 0)
    mod0_type = cake_typeof(mod0_err)
    if mod0_type == "err": err_pass = 1
    propagated_err = cake_add(div0_err, 5)
    prop_type = cake_typeof(propagated_err)
    print(f"12. errors: div0={div0_type} mod0={mod0_type} prop={prop_type} pass={err_pass}")


def bench_13():
    base = "hello"; result_str = ""
    for _ in range(200): result_str += base
    final_str_len = len(result_str)
    empty_str = "c" + "a" + "k" + "e"
    cake_upper = empty_str.upper()
    print(f"13. string stress: len={final_str_len} word={cake_upper}")


def bench_14():
    mut_arr = [random.randint(0, 999) for _ in range(50)]
    mut_j = 0
    while mut_j < 50:
        mut_arr[mut_j] += 1
        mut_j += 1
    last_elem = mut_arr.pop()
    print(f"14. array mutation: last={last_elem} len={len(mut_arr)}")


def bench_15():
    chain_val = 0
    def inc():
        nonlocal chain_val; chain_val += 1
    def dec():
        nonlocal chain_val; chain_val -= 1
    for _ in range(100): inc()
    for _ in range(50): dec()
    print(f"15. block chain: {chain_val}")


def bench_16():
    cmp_a = 10; cmp_b = 20; cmp_score = 0
    if cmp_a == 10: cmp_score += 1
    if cmp_a != cmp_b: cmp_score += 2
    if cmp_a < cmp_b: cmp_score += 4
    if cmp_b > cmp_a: cmp_score += 8
    if cmp_a <= cmp_b: cmp_score += 16
    if cmp_b >= cmp_a: cmp_score += 32
    print(f"16. comparisons: score={cmp_score}")


def bench_17():
    v1, v2, v3, v4, v5 = 1, 2, 3, 4, 5
    layout_sum = v1 + v2 + v3 + v4 + v5
    layout_sum = layout_sum * 2
    layout_sum = layout_sum - 10
    layout_sum = abs(layout_sum)
    print(f"17. layout test: {layout_sum}")


# ============================================================
# Runner
# ============================================================

def main():
    t0 = time.time()

    bench_1()
    bench_2()
    bench_3()
    bench_4()
    bench_5()
    bench_6()
    bench_7()
    bench_8()
    bench_9()
    bench_10()
    bench_11()
    bench_12()
    bench_13()
    bench_14()
    bench_15()
    bench_16()
    bench_17()

    elapsed = time.time() - t0
    print(f"\nPython elapsed: {elapsed:.6f}s")
    print("BENCHMARK COMPLETE")


if __name__ == "__main__":
    main()
