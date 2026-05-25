// ============================================================
// CakeSpark 1.0.0 — Comprehensive Stress Benchmark
// Tests: all 40+ builtins, all control flow, blocks, scoping,
//        type coercion, error handling, arrays, strings, bitwise
// ============================================================

// --- 1. Fibonacci(30) — arithmetic, while, comparison ---
set 0 >> a
set 1 >> b
set 0 >> i
while i < 30
  set a >> tmp
  set b >> a
  add tmp b >> b
  add i 1 >> i
end
log "1. fib(31) = {b}"

// --- 2. Sieve of Eratosthenes up to 1000 — arrays, nested loops, mod, if ---
set 1000 >> limit
arr.new(limit) >> sieve
set 0 >> si
loop limit
  arr.push(sieve, 1)
end
set 2 >> p
while p < limit
  arr.get(sieve, p) >> is_p
  if is_p == 1
    set p >> mul_p
    add mul_p p >> mul_p
    while mul_p < limit
      arr.set(sieve, mul_p, 0)
      add mul_p p >> mul_p
    end
  end
  add p 1 >> p
end
set 0 >> prime_sum
set 2 >> pc
while pc < limit
  arr.get(sieve, pc) >> is_prime
  if is_prime == 1
    add prime_sum pc >> prime_sum
  end
  add pc 1 >> pc
end
log "2. sum of primes < {limit} = {prime_sum}"

// --- 3. String operations — str.len, str.upper, str.split, str.join, str.find, str.slice, str.cat ---
set "the quick brown fox jumps over the lazy dog" >> pangram
str.len(pangram) >> pangram_len
str.upper(pangram) >> upper_pangram
str.split(pangram, " ") >> words
arr.len(words) >> words_count
str.join(words, "|") >> piped
str.find(pangram, "fox") >> fox_pos
str.slice(pangram, fox_pos, 99) >> tail
str.cat("hello ", "world") >> greeted
str.len(greeted) >> greet_len
log "3. str ops: {words_count} words, fox at {fox_pos}, greet len={greet_len}"

// --- 4. Array sort + search — arr.push, arr.sort, arr.get, arr.contains, mul, loop ---
arr.new(200) >> arr200
set 0 >> ai
loop 200
  mul ai 127 >> rv
  mod rv 9999 >> rv
  add rv 1 >> rv
  arr.push(arr200, rv)
end
arr.len(arr200) >> arr200_len
arr.sort(arr200) >> sorted200
arr.get(sorted200, 0) >> min_v
arr.get(sorted200, 99) >> mid_v
arr.get(sorted200, 199) >> max_v
arr.contains(sorted200, min_v) >> has_min
arr.contains(sorted200, max_v) >> has_max
arr.pop(arr200) >> popped_v
arr.len(arr200) >> after_pop
log "4. array: len={arr200_len} min={min_v} mid={mid_v} max={max_v} after_pop={after_pop}"

// --- 5. Factorial via blocks — block, run, scope sharing, mul ---
set 1 >> fac_n
set 1 >> fac_result

block multiply
  mul fac_result fac_n >> fac_result
  add fac_n 1 >> fac_n
end

loop 12
  run multiply
end
log "5. factorial(12) via blocks = {fac_result}"

// --- 6. Scope stress — while, if/elif/else, mod, scoped variables ---
set 0 >> scope_i
set 0 >> scope_acc
while scope_i < 50
  mod scope_i 3 >> scope_mod
  if scope_mod == 0
    set "fizz" >> scope_label
    add scope_acc 1 >> scope_acc
  elif scope_mod == 1
    set "buzz" >> scope_label
    add scope_acc 10 >> scope_acc
  else
    set "fizzbuzz" >> scope_label
    add scope_acc 100 >> scope_acc
  end
  add scope_i 1 >> scope_i
end
log "6. scope stress: acc={scope_acc}"

// --- 7. each iteration — each, string building ---
set ["alpha", "beta", "gamma", "delta", "epsilon"] >> greek
set "" >> greek_str
each greek >> letter
  str.cat(greek_str, letter) >> greek_str
  str.cat(greek_str, ",") >> greek_str
end
str.len(greek_str) >> greek_len
log "7. each iter: {greek_len} chars"

// --- 8. Type conversions — typeof, tofloat, tostr, toint ---
set 314159 >> big_int
tofloat big_int >> big_float
tostr big_float >> big_str
str.len(big_str) >> big_str_len
toint "42" >> parsed_int
add parsed_int 100 >> adjusted
typeof adjusted >> adj_type
log "8. types: int={adjusted} type={adj_type} str_len={big_str_len}"

// --- 9. Bitwise operations — and, or, xor, not, shl, shr ---
set 63 >> bw_a
set 21 >> bw_b
and bw_a bw_b >> bw_and
or bw_a bw_b >> bw_or
xor bw_a bw_b >> bw_xor
not bw_a >> bw_not
shl bw_a 3 >> bw_shl
shr bw_a 2 >> bw_shr
add bw_and bw_or >> bw_sum
add bw_sum bw_xor >> bw_sum
add bw_sum bw_not >> bw_sum
add bw_sum bw_shl >> bw_sum
add bw_sum bw_shr >> bw_sum
log "9. bitwise sum: {bw_sum}"

// --- 10. Nested loops — nested while, break ---
set 0 >> dl_sum
set 0 >> dl_i
while dl_i < 20
  set 0 >> dl_j
  while dl_j < 20
    add dl_sum dl_i >> dl_sum
    add dl_sum dl_j >> dl_sum
    if dl_sum > 5000
      break
    end
    add dl_j 1 >> dl_j
  end
  add dl_i 1 >> dl_i
end
log "10. nested loop sum: {dl_sum}"

// --- 11. Math functions — pow, sqrt, abs, min, max ---
pow 2 16 >> pow_val
sqrt 1024 >> sqrt_val
abs -42 >> abs_val
min 7 3 >> min_val
max 7 3 >> max_val
add pow_val sqrt_val >> math_sum
add math_sum abs_val >> math_sum
add math_sum min_val >> math_sum
add math_sum max_val >> math_sum
log "11. math sum: {math_sum}"

// --- 12. Error propagation — div by 0, mod by 0, error flow through add ---
div 1 0 >> div0_err
typeof div0_err >> div0_type
tostr div0_err >> div0_msg
set 0 >> err_pass
mod 1 0 >> mod0_err
typeof mod0_err >> mod0_type
if mod0_type == "err"
  set 1 >> err_pass
end
add div0_err 5 >> propagated_err
typeof propagated_err >> prop_type
log "12. errors: div0={div0_type} mod0={mod0_type} prop={prop_type} pass={err_pass}"

// --- 13. String building stress — str.cat in loop ---
set "hello" >> base
set "" >> result_str
set 0 >> str_i
loop 200
  str.cat(result_str, base) >> result_str
end
str.len(result_str) >> final_str_len
set "" >> empty_str
str.cat(empty_str, "c") >> empty_str
str.cat(empty_str, "a") >> empty_str
str.cat(empty_str, "k") >> empty_str
str.cat(empty_str, "e") >> empty_str
str.upper(empty_str) >> cake_upper
log "13. string stress: len={final_str_len} word={cake_upper}"

// --- 14. Array mutation stress — push, get, set in while, pop ---
arr.new(50) >> mut_arr
set 0 >> mut_i
loop 50
  mul mut_i 97 >> mut_val
  mod mut_val 999 >> mut_val
  arr.push(mut_arr, mut_val)
end
set 0 >> mut_j
while mut_j < 50
  arr.get(mut_arr, mut_j) >> elem
  add elem 1 >> elem
  arr.set(mut_arr, mut_j, elem)
  add mut_j 1 >> mut_j
end
arr.pop(mut_arr) >> last_elem
arr.len(mut_arr) >> mut_len
log "14. array mutation: last={last_elem} len={mut_len}"

// --- 15. Block call chain — block, run x200 ---
set 0 >> chain_val

block inc
  add chain_val 1 >> chain_val
end
block dec
  sub chain_val 1 >> chain_val
end

loop 100
  run inc
end
loop 50
  run dec
end
log "15. block chain: {chain_val}"

// --- 16. Comparison operators — == != < > <= >= ---
set 10 >> cmp_a
set 20 >> cmp_b
set 0 >> cmp_score
if cmp_a == 10
  add cmp_score 1 >> cmp_score
end
if cmp_a != cmp_b
  add cmp_score 2 >> cmp_score
end
if cmp_a < cmp_b
  add cmp_score 4 >> cmp_score
end
if cmp_b > cmp_a
  add cmp_score 8 >> cmp_score
end
if cmp_a <= cmp_b
  add cmp_score 16 >> cmp_score
end
if cmp_b >= cmp_a
  add cmp_score 32 >> cmp_score
end
log "16. comparisons: score={cmp_score}"

// --- 17. Layout stress — many variables, many reads/writes ---
set 1 >> v1
set 2 >> v2
set 3 >> v3
set 4 >> v4
set 5 >> v5
set 0 >> layout_sum
add layout_sum v1 >> layout_sum
add layout_sum v2 >> layout_sum
add layout_sum v3 >> layout_sum
add layout_sum v4 >> layout_sum
add layout_sum v5 >> layout_sum
mul layout_sum 2 >> layout_sum
sub layout_sum 10 >> layout_sum
abs layout_sum >> layout_sum
log "17. layout test: {layout_sum}"

log "BENCHMARK COMPLETE"
