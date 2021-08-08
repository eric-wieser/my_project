/-
Copyright (c) 2021 Lu-Ming Zhang. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Lu-Ming Zhang.
-/
import field_theory.finite.basic
import group_theory.quotient_group
import monoid_hom
import set_finset_fintype

/-!
# Finite fields

This file supplements basic results about finite field that are missing in mathlib.
As well, this files defines quadratic residues and the quadratic character, 
and contains basic results about them.
Throughout most of this file, `F` denotes a finite field, 
and `q` is notation for the cardinality of `F`, and `p` is the character of `F`.

## Main results
1. `finite_field.is_quad_residue`: a proposition predicating whether a given `a : F` is a quadratic residue in `F`. 
   `finite_field.is_quad_residue a` is defined to be `a ≠ 0 ∧ ∃ b, a = b^2`.
2. `finite_field.is_non_residue`: a proposition predicating whether a given `a : F` is a quadratic non-residue in `F`.
   `finite_field.is_non_residue a` is defined to be `a ≠ 0 ∧ ¬ ∃ b, a = b^2`.

3. `finite_field.quad_residues`: the subtype of `F` containing quadratic residues.
4. `finite_field.quad_residues_set`: the set containing quadratic residues of `F`.
5. `finite_field.non_residues`: the subtype of `F` containing quadratic non-residues.
6. `finite_field.non_residues_set`: the set containing quadratic non-residues of `F`.

7. `finite_field.sq`: the square function from `units F` to `units F`, defined as a group homomorphism.

8. `finite_filed.non_residue_mul`: is the map `_ * b` given a non-residue `b` defined on `{a : F // is_quad_residue a}`.

9. `finite_field.quad_char`: defines the quadratic character of `a` in a finite field `F`. 
   - `χ a = 0 ` if `a = 0`
   - `χ a = 1` if `a ≠ 0` and  `a` is a square
   - `χ a = -1` otherwise

## Notation

Throughout most of this file, `F` denotes a finite field, 
and `q` is notation for the cardinality of `F`, and `p` is the character of `F`.
`χ a` denotes the quadratic character of `a : F`.

-/

local attribute [instance] set_fintype
--local attribute [-instance] set.fintype_univ

open_locale big_operators
open finset fintype monoid_hom nat.modeq function

namespace finite_field

variables {F : Type*} [field F] [fintype F] {p : ℕ} [char_p F p] 
local notation `q` := fintype.card F 

/- ## basic -/
section basic

variables (p)
lemma char_eq_of_prime_eq_zero 
{n : ℕ} (h₁ : nat.prime n) (h₂ : ↑n = (0 : F)) : p = n :=
begin
  have g₁ : nat.prime p, {obtain ⟨n, h1, h2⟩:= finite_field.card F p, assumption},
  have g₂ := (char_p.cast_eq_zero_iff F p n).1 h₂,
  exact (nat.prime_dvd_prime_iff_eq g₁ h₁).1 g₂,
end

lemma char_ne_two :
q ≡ 1 [MOD 4] ∨ q ≡ 3 [MOD 4] → p ≠ 2 :=
begin
  obtain ⟨n, p_prime, g⟩:= finite_field.card F p,
  rw g,
  rintro (h | h),
  any_goals 
  { rw nat.modeq.modeq_iff_dvd at h, 
    rintro hp, rw hp at h, 
    rcases h with ⟨k, h⟩, 
    simp at h,
    have : 2 ∣ 4 * k + 2 ^ ↑n,
    { use (2 * k + (2 : ℤ) ^ n.1.pred), 
      simp [mul_add], congr' 1, 
      ring, 
      have : (2 : ℤ) * 2 ^ (n : ℕ).pred = 2 ^ ((n : ℕ).pred + 1), {refl}, 
      convert this.symm, 
      clear this,
      convert (nat.succ_pred_eq_of_pos _).symm, 
      exact n.2 },
  },
  { have g := eq_add_of_sub_eq h, rw ← g at this, revert this, dec_trivial },
  { have g := eq_add_of_sub_eq h, rw ← g at this, revert this, dec_trivial }, 
end

lemma char_ne_two' : 
q ≡ 3 [MOD 4] → p ≠ 2 ∧ ¬ q ≡ 1 [MOD 4] :=
begin
  intros h,
  refine ⟨char_ne_two p (or.inr h), _⟩,
  intro h',
  have g := h'.symm.trans  h,
  simp [nat.modeq.modeq_iff_dvd] at g,
  rcases g with ⟨k, g⟩,
  norm_num at g, 
  have : 2 / 4 = (4 * k) / 4, {rw ← g},
  norm_num at this,
  simp [← this] at g,
  assumption  
end

/-- For non-zero `a : F`, `to_unit` converts `a` to an instance of `units F`. -/
@[simp] def to_unit {a : F} (h : a ≠ 0): units F :=
by refine {val := a, inv := a⁻¹, ..}; simp* at *

/-- The order of `a : units F` equals the order of `a` coerced in `F`. -/
lemma order_of_unit_eq (a : units F) : order_of a = order_of (a : F) :=
begin
  convert (@order_of_injective (units F) _ F _ (units.coe_hom F) _ a).symm,
  intros i j h,
  simp[*, units.ext_iff] at *,
end

variables {p}

/-- If the character of `F` is not `2`, `-1` is not equal to `1` in `F`. -/
lemma neg_one_ne_one_of_char_ne_2 (hp: p ≠ 2) : (-1 : F) ≠ 1 :=
begin
  intros h,
  have h' := calc ↑(2 : ℕ) = (2 : F)     : by simp
                      ... = (1 : F) + 1  : by ring
                      ... = (-1 : F) + 1 : by nth_rewrite 0 ←h
                      ... = 0            : by ring,
  have hp' := char_eq_of_prime_eq_zero p nat.prime_two h',
  contradiction
end

/-- If the character of `F` is not `2`, `-1` is not equal to `1` in `units F`. -/
lemma neg_one_ne_one_of_char_ne_2' (hp: p ≠ 2) : (-1 : units F) ≠ 1 := 
by simp [units.ext_iff]; exact neg_one_ne_one_of_char_ne_2 hp

/-- For `x : F`, `x^2 = 1 ↔ x = 1 ∨ x = -1`. -/
lemma sq_eq_one_iff_eq_one_or_eq_neg_one (x : F) :
x^2 = 1 ↔ x = 1 ∨ x = -1 :=
begin
  rw [sub_eq_zero.symm],
  have h: x ^ 2 - 1 = (x - 1) * (x + 1), {ring},
  rw [h, mul_eq_zero, sub_eq_zero, add_eq_zero_iff_eq_neg]
end

/-- For `x : units F`, `x^2 = 1 ↔ x = 1 ∨ x = -1`. -/
lemma sq_eq_one_iff_eq_one_or_eq_neg_one' (x : units F) :
x^2 = 1 ↔ x = 1 ∨ x = -1 :=
begin
  simp only [units.ext_iff],
  convert sq_eq_one_iff_eq_one_or_eq_neg_one (x : F),
  simp,
end

/-- If the character of `F` is not `2`, `-1` is the only order-2 element in `F`. -/
lemma order_of_eq_two_iff (hp: p ≠ 2) (x : F) : order_of x = 2 ↔ x = -1 := 
begin
  have g := pow_order_of_eq_one x,
  split,
  any_goals {intros h},
  { rw [h, sq_eq_one_iff_eq_one_or_eq_neg_one] at g,
    have : x ≠ 1, { intro hx, rw ←order_of_eq_one_iff at hx, linarith },
    exact or_iff_not_imp_left.1 g this },
  { have hx : x^2 = 1, {rw h, ring},
    have inst : fact (nat.prime 2), {exact ⟨nat.prime_two⟩}, 
    resetI,
    convert order_of_eq_prime hx _,
    rw h,
    exact neg_one_ne_one_of_char_ne_2 hp }
end

/-- If the character of `F` is not `2`, `-1` is the only order-2 element in ` units F`. -/
lemma order_of_eq_two_iff' (hp: p ≠ 2) (x : units F) : order_of x = 2 ↔ x = -1 := 
by simp [units.ext_iff]; rw [← order_of_eq_two_iff hp (x : F), order_of_unit_eq x]

lemma card_eq_one_mod_n_iff_n_divide_card_units (n : ℕ):
q ≡ 1 [MOD n] ↔ n ∣ fintype.card (units F) := 
begin
  rw [finite_field.card_units, nat.modeq.comm],
  convert modeq_iff_dvd' (card_pos_iff.mpr ⟨(0 : F)⟩),
end

/-- `-1` is a square in `units F` iff the cardinal `q ≡ 1 [MOD 4]`. -/
lemma neg_one_eq_sq_iff_card_eq_one_mod_four' (hp: p ≠ 2) : 
(∃ a : units F, -1 = a^2) ↔ q ≡ 1 [MOD 4] :=
begin
  rw card_eq_one_mod_n_iff_n_divide_card_units,
  split,
  { rintros ⟨a, h'⟩,
    have h := calc a^4 = a^2 * a^2 : by group
                 ... = 1: by simp [← h'],
    have h₀ := order_of_dvd_of_pow_eq_one h,
    have au := nat.le_of_dvd dec_trivial h₀,
    have g₁ : a ≠ 1, 
    { rintro rfl, simp at h', exact absurd h' (neg_one_ne_one_of_char_ne_2' hp) },
    have h₁ := mt order_of_eq_one_iff.1 g₁, 
    have g₂ : a ≠ -1, 
    { rintro rfl, simp [pow_two] at h', exact absurd h' (neg_one_ne_one_of_char_ne_2' hp) },
    have h₂ := mt (order_of_eq_two_iff' hp a).1 g₂,
    have ha : order_of a = 4, 
    { revert h₀ h₁ h₂, interval_cases (order_of a), any_goals {rw h_1, norm_num} }, 
    simp [← ha, order_of_dvd_card_univ] 
  },
  { rintro ⟨k, hF⟩,
    obtain ⟨g, hg'⟩ := is_cyclic.exists_generator (units F),
    have hg := @pow_card_eq_one (units F) g _ _,
    have eq : 4 * k = k * 2 * 2, {ring},
    rw [hF, eq, pow_mul, sq_eq_one_iff_eq_one_or_eq_neg_one'] at hg,
    use g ^ k,
    rcases hg with (hg | hg),
    { have hk₁ := card_pos_iff.mpr ⟨(1 : units F)⟩, 
      rw hF at hk₁,
      have o₁ := order_of_eq_card_of_forall_mem_gpowers hg',
      have o₂ := order_of_dvd_of_pow_eq_one hg,
      have le := nat.le_of_dvd (by linarith) o₂,
      rw [o₁, hF] at le,
      exfalso, linarith },
    { simp [← hg, pow_mul] } 
  },
end

/-- `-1` is a square in `F` iff the cardinal `q ≡ 1 [MOD 4]`. -/
lemma neg_one_eq_sq_iff_card_eq_one_mod_four (hp: p ≠ 2) : 
(∃ a : F, -1 = a^2) ↔ fintype.card F ≡ 1 [MOD 4] :=
begin
  rw [←neg_one_eq_sq_iff_card_eq_one_mod_four' hp],
  split,
  any_goals {rintros ⟨a, ha⟩},
  { have ha' : a ≠ 0,  
    {rintros rfl, simp* at *}, 
    use (to_unit ha'), 
    simpa [units.ext_iff] },
  { use a, simp [units.ext_iff] at ha, assumption },
  assumption
end

variables (F)

lemma disjoint_units_zero : disjoint {a : F | a ≠ 0} {0} :=
by simp 

lemma units_union_zero : {a : F | a ≠ 0} ∪ {0} = @set.univ F :=
by {tidy, tauto}

end basic
/- ## end basic -/

/- ## quad_residues -/
section quad_residues

variables {F p}

/-- A proposition predicating whether a given `a : F` is a quadratic residue in `F`. 
    `finite_field.is_quad_residue a` is defined to be `a ≠ 0 ∧ ∃ b, a = b^2`. -/
@[derive decidable] 
def is_quad_residue [decidable_eq F] (a : F) : Prop := a ≠ 0 ∧ ∃ b, a = b^2

/-- A proposition predicating whether a given `a : F` is a quadratic non-residue in `F`.
    `finite_field.is_non_residue a` is defined to be `a ≠ 0 ∧ ¬ ∃ b, a = b^2`. -/
@[derive decidable] 
def is_non_residue [decidable_eq F] (a : F) : Prop := a ≠ 0 ∧ ¬ ∃ b, a = b^2

instance [decidable_eq F] : decidable_pred (@is_quad_residue F _ _ _) := λ a, infer_instance

instance [decidable_eq F] : decidable_pred (@is_non_residue F _ _ _) := λ a, infer_instance

lemma is_non_residue_of_not_residue [decidable_eq F] 
{a : F} (h : a ≠ 0) (g : ¬ is_quad_residue a) : 
is_non_residue a :=
by simp [is_quad_residue, is_non_residue, *] at *

variables (F)

/-- The subtype of `F` containing quadratic residues. -/
def quad_residues [decidable_eq F] := {a : F // is_quad_residue a}
/-- The set containing quadratic residues of `F`. -/
def quad_residues_set [decidable_eq F] := {a : F | is_quad_residue a}

/-- The subtype of `F` containing quadratic non-residues. -/
def non_residues [decidable_eq F] := {a : F // is_non_residue a}
/-- The set containing quadratic non-residues of `F`. -/
def non_residues_set [decidable_eq F] := {a : F | is_non_residue a}

instance [decidable_eq F] : fintype (quad_residues F) := 
by {unfold quad_residues, apply_instance}

instance [decidable_eq F] : fintype (non_residues F) := 
by {unfold non_residues, apply_instance}

/- ### sq_function -/
section sq_function

variables (F)

/-- `sq` is the square function from `units F` to `units F`, defined as a group homomorphism. -/
def sq : (units F) →* (units F) := 
⟨λ a, a * a, by simp, (λ x y, by simp [units.ext_iff]; ring)⟩

noncomputable
lemma sq.quotient_ker_mul_equiv_range : quotient_group.quotient (sq F).ker ≃* (sq F).range :=
quotient_group.quotient_ker_equiv_range (sq F)

lemma sq.card_quotient_ker_eq_card_range [decidable_eq F] : 
fintype.card (quotient_group.quotient (sq F).ker) = fintype.card (sq F).range :=
fintype.card_congr (mul_equiv.to_equiv (sq.quotient_ker_mul_equiv_range F))

lemma sq.iso' [decidable_eq F] : 
fintype.card (units F) = 
fintype.card (quotient_group.quotient (sq F).ker) * fintype.card (sq F).ker := 
subgroup.card_eq_card_quotient_mul_card_subgroup _

/-- The cardinality of `units F` equals to the product of the cardinalities of `sq`'s range and `sq`'s kernal. -/
lemma sq.iso [decidable_eq F] : 
fintype.card (units F) = fintype.card (sq F).range * fintype.card (sq F).ker :=
by {have h:= sq.iso' F, rwa (sq.card_quotient_ker_eq_card_range F) at h,}

/-- `sq.range_equiv` constructs the natural equivalence between the range of `sq` and `{a : F // is_quad_residue a}`. -/
def sq.range_equiv [decidable_eq F] : (sq F).range ≃ {a : F // is_quad_residue a} := 
⟨ 
 λ a, ⟨a, by {have h := a.2, simp [sq] at h, rcases h with ⟨b, h⟩, 
              simp [is_quad_residue, ← h], use b, ring }⟩, 
 λ a, ⟨to_unit (a.2).1, by {obtain ⟨h, ⟨b, hab⟩⟩:= a.2, 
                            have hb : b ≠ 0, {rintros rfl, simp* at *},
                            use to_unit hb, simp [units.ext_iff, sq, ← pow_two, ← hab] }⟩, 
 λ a, by simp [units.ext_iff],
 λ a, by simp
⟩

lemma sq.card_range_eq [decidable_eq F] : fintype.card (sq F).range = fintype.card {a : F // is_quad_residue a} :=
by apply fintype.card_congr (sq.range_equiv F)

lemma sq.ker_carrier_eq : (sq F).ker.carrier = {1, -1} :=
begin
  rw ker, 
  simp [subgroup.comap, set.preimage, sq],
  ext, simp, 
  convert sq_eq_one_iff_eq_one_or_eq_neg_one' x,
  simp [pow_two, npow_rec],
end

lemma sq.card_ker_carrier_eq [decidable_eq F] (hp: p ≠ 2) : fintype.card (sq F).ker.carrier = 2 :=
begin
  simp [sq.ker_carrier_eq F],
  convert @set.card_insert _ (1 : units F) {-1} _ _ _,
  { have g: fintype.card ({-1} : set (units F)) = 1, {simp}, simp [g]},
  simp [units.ext_iff],
  exact ne.symm (neg_one_ne_one_of_char_ne_2 hp),
end

variables {F}

lemma sq.card_ker_eq [decidable_eq F] (hp: p ≠ 2) : fintype.card (sq F).ker = 2 :=
by rw [←sq.card_ker_carrier_eq F hp]; refl

end sq_function
/- ### end sq_function -/

variable (F)

lemma card_units_eq_card_residues_mul_two [decidable_eq F] (hp: p ≠ 2) :
fintype.card (units F) = fintype.card {a : F // is_quad_residue a} * 2 :=
by rwa [sq.iso, sq.card_range_eq, sq.card_ker_eq hp]

lemma card_residues_mul_two_eq [decidable_eq F] (hp: p ≠ 2) :
fintype.card {a : F // is_quad_residue a} * 2 = fintype.card F - 1 :=
by rwa [← card_units, card_units_eq_card_residues_mul_two F hp]

lemma residues_setcard_eq_fintype_card [decidable_eq F] :
set.card {a : F | is_quad_residue a} = fintype.card {a : F // is_quad_residue a} :=
set.to_finset_card {a : F | is_quad_residue a}

lemma non_residues_setcard_eq_fintype_card [decidable_eq F] :
set.card {a : F | is_non_residue a} = fintype.card {a : F // is_non_residue a} :=
set.to_finset_card {a : F | is_non_residue a}

lemma disjoint_residues_non_residues [decidable_eq F] : 
disjoint {a : F | is_quad_residue a} {a : F | is_non_residue a} :=
begin 
  simp [set.disjoint_iff_inter_eq_empty, is_non_residue, is_quad_residue], 
  ext, simp,
  rintros h b rfl _,
  use b,
end

lemma residues_union_non_residues [decidable_eq F] : 
{a : F | is_quad_residue a} ∪ {a : F | is_non_residue a} = {a : F | a ≠ 0} :=
begin
  ext,
  simp [is_non_residue, is_quad_residue, ←and_or_distrib_left],
  intros,
  convert or_not,
  simp,
end 

lemma univ_setcard_split [decidable_eq F] : 
(@set.univ F).card = {a : F | a ≠ 0}.card + ({0} : set F).card :=
set.card_disjoint_union' (disjoint_units_zero F) (units_union_zero F)

lemma zero_setcard_eq_one [decidable_eq F] : ({0} : set F).card = 1 := 
by simp [set.card]

lemma univ_setcard_eq_units_setcard_add_one [decidable_eq F] : 
(@set.univ F).card = {a : F | a ≠ 0}.card + 1 :=
by rw [univ_setcard_split,zero_setcard_eq_one]

lemma units_setcard_split [decidable_eq F] : 
{a : F | a ≠ 0}.card = {a : F | is_quad_residue a}.card + {a : F | is_non_residue a}.card  :=
set.card_disjoint_union' (disjoint_residues_non_residues F) (residues_union_non_residues F)

@[simp] lemma in_residues_sum_one_eq [decidable_eq F] : 
∑ i in {a : F | is_quad_residue a}.to_finset, (1 : ℚ) = {a : F | is_quad_residue a}.card :=
by simp only [set.card, finset.card_eq_sum_ones_ℚ]

@[simp] lemma in_non_residues_sum_neg_one_eq [decidable_eq F] : 
∑ i in {a : F | is_non_residue a}.to_finset, (-1 : ℚ) = - {a : F | is_non_residue a}.card :=
by simp only [set.card, finset.card_eq_sum_ones_ℚ, sum_neg_distrib]

variable {F}

/-- The cardinality of quadratic residues equals that of non-residues. -/
lemma card_residues_eq_card_non_residues_set [decidable_eq F] (hp : p ≠ 2):
{a : F | is_quad_residue a}.card = {a : F | is_non_residue a}.card :=
begin
  have h:= card_residues_mul_two_eq F hp,
  rw [card_eq_set_card_of_univ F, ←residues_setcard_eq_fintype_card, 
      univ_setcard_eq_units_setcard_add_one,  units_setcard_split] at h,
  simp [mul_two, *] at *,
end

/-- `fintype` version of `finite_field.card_residues_eq_card_non_residues_set` . -/
lemma card_residues_eq_card_non_residues_subtpye [decidable_eq F] (hp : p ≠ 2):
fintype.card {a : F // is_quad_residue a} = fintype.card {a : F // is_non_residue a} :=
by rwa [←residues_setcard_eq_fintype_card, ←non_residues_setcard_eq_fintype_card, 
        card_residues_eq_card_non_residues_set hp]

lemma non_residue_mul_residue_is_non_residue [decidable_eq F]
{b a : F} (hb : is_non_residue b) (ha : is_quad_residue a) : 
is_non_residue (b * a) :=
begin
  have : b * a ≠ 0, {exact mul_ne_zero hb.1 ha.1},
  refine ⟨this, _⟩,
  rcases ha.2 with ⟨c, rfl⟩, 
  rintro ⟨d, h⟩,
  have hc : c ≠ 0, {rintro rfl, simp at this, assumption},
  convert hb.2 ⟨(c⁻¹ * d), _⟩,
  rw [mul_comm] at h,
  rw [mul_pow, ← h, ←mul_assoc],
  simp*
end

lemma residue_mul_non_residue_is_non_residue [decidable_eq F]
{a b : F} (ha : is_quad_residue a) (hb : is_non_residue b): 
is_non_residue (a * b) :=
begin
  rw [mul_comm a],
  exact non_residue_mul_residue_is_non_residue hb ha,
end

/-- `finite_filed.non_residue_mul` is the map `_ * b` given a non-residue `b` defined on `{a : F // is_quad_residue a}`. -/
def non_residue_mul [decidable_eq F] {b: F} (hb : is_non_residue b) : 
{a : F // is_quad_residue a} → {a : F // is_non_residue a} :=
λ a, ⟨b * a.1, non_residue_mul_residue_is_non_residue hb a.2⟩

lemma non_residue_mul_is_injective [decidable_eq F] {b: F} (hb : is_non_residue b) : 
function.injective (non_residue_mul hb):=
begin
  intros a₁ a₂ h,
  simp [non_residue_mul] at h,
  ext,
  cases h,
  {assumption},
  exact absurd h hb.1
end

lemma non_residue_mul_is_surjective [decidable_eq F] (hp : p ≠ 2) {b: F} (hb : is_non_residue b) : 
function.surjective (non_residue_mul hb):=
begin
  by_contra f_not_surj,
  have h_card_lt := card_lt_of_injective_not_surjective (non_residue_mul hb) (non_residue_mul_is_injective hb) f_not_surj,
  have h_card_eq := card_residues_eq_card_non_residues_subtpye hp,
  exact absurd h_card_eq (ne_of_lt h_card_lt),
  assumption,
end

lemma non_residue_mul_non_residue_is_residue [decidable_eq F] (hp : p ≠ 2)
{b a : F} (hb : is_non_residue b) (ha : is_non_residue a): 
is_quad_residue (b * a) :=
begin
  have : b * a ≠ 0, {exact mul_ne_zero hb.1 ha.1},
  by_contra h',
  have h := is_non_residue_of_not_residue this h',
  clear h',
  have f_surj := non_residue_mul_is_surjective hp hb,
  simp [function.surjective] at f_surj,
  specialize f_surj (b * a) h,
  rcases f_surj with ⟨a', ha', g⟩,
  simp [non_residue_mul] at g,
  rcases g with (rfl | rfl),
  {exact absurd ha'.2 ha.2},
  {simp at this, assumption},
end

end quad_residues

/- ## end quad_residues -/

/- ## quad_char -/

section quad_char

variables {F} [decidable_eq F]

/-- `finite_field.quad_char` defines the quadratic character of `a` in a finite field `F`. -/
def quad_char (a : F) : ℚ :=
if a = 0            then 0 else 
if ∃ b : F, a = b^2 then 1 else
                        -1.

notation `χ` := quad_char  

@[simp] lemma quad_char_zero_eq_zero : χ (0 : F) = 0 := by simp [quad_char]

@[simp] lemma quad_char_one_eq_one : χ (1 : F) = 1 := 
by {simp [quad_char], intros h, specialize h 1, simp* at *}

@[simp] lemma quad_char_ne_zero_of_ne_zero {a : F} (h : a ≠ 0) : 
χ a ≠ 0 := 
by by_cases (∃ (b : F), a = b ^ 2); simp [quad_char, *] at *

@[simp] lemma quad_char_eq_zero_iff_eq_zero (a : F) :
χ a = 0 ↔ a = 0 :=
begin
  split,
  {contrapose, exact quad_char_ne_zero_of_ne_zero},
  {rintro rfl, exact quad_char_zero_eq_zero}
end

@[simp] lemma quad_char_i_sub_j_eq_zero_iff_i_eq_j (i j : F) : 
χ (i - j) = 0 ↔ i = j := 
by simp [sub_eq_zero]

@[simp] lemma quad_char_eq_one_or_neg_one_of_char_ne_zero {a : F} (h : χ a ≠ 0) : 
(χ a = 1) ∨ (χ a = -1) := 
by by_cases (∃ (b : F), a = b ^ 2); simp [quad_char, *] at *

@[simp] lemma quad_char_eq_neg_one_or_one_of_ne_zero' {a : F} (h : χ a ≠ 0) : 
(χ a = -1) ∨ (χ a = 1) := 
or.swap (quad_char_eq_one_or_neg_one_of_char_ne_zero h)

@[simp] lemma quad_char_eq_one_or_neg_one_of_ne_zero {a : F} (h : a ≠ 0) : 
(χ a = 1) ∨ (χ a = -1) := 
quad_char_eq_one_or_neg_one_of_char_ne_zero (quad_char_ne_zero_of_ne_zero h)

@[simp] lemma quad_char_suqare_eq_one_of_ne_zero {a : F} (h : a ≠ 0) : 
χ a * χ a = 1 := 
by by_cases (∃ (b : F), a = b ^ 2); simp [quad_char, *] at *

@[simp] lemma quad_char_eq_one_of {a : F} (h : a ≠ 0) (h' : ∃ (b : F), a = b ^ 2) : 
χ a = 1 := 
by simp [quad_char, *] at *

@[simp] lemma quad_char_eq_neg_one_of {a : F} (h : a ≠ 0) (h' : ¬ ∃ (b : F), a = b ^ 2) : 
χ a = -1 := 
by simp [quad_char, *] at *

@[simp] lemma quad_char_eq_one_of_quad_residue {a : F} (h : is_quad_residue a) : 
χ a = 1 := quad_char_eq_one_of h.1 h.2

@[simp] lemma quad_char_eq_neg_one_of_non_residue {a : F} (h : is_non_residue a) : 
χ a = -1 := quad_char_eq_neg_one_of h.1 h.2

@[simp] lemma nonzero_quad_char_eq_one_or_neg_one' {a b : F} (h : a ≠ b) : 
(χ (a - b) = 1) ∨ (χ (a - b) = -1) := 
by {have h':= sub_ne_zero.mpr h, simp* at *}

lemma quad_char_mul (hp : p ≠ 2) (a b : F) : χ (a * b) = χ a * χ b :=
begin
  by_cases ha: a = 0,
  any_goals {by_cases hb : b = 0},
  any_goals {simp*},
  have : a * b ≠ 0, {exact mul_ne_zero ha hb},
  by_cases hc : ∃ (c : F), a = c ^ 2,
  any_goals {by_cases hd : ∃ (d : F), b = d ^ 2},
  all_goals {simp*},
  { apply quad_char_eq_one_of this, 
    rcases hc with ⟨c, rfl⟩, 
    rcases hd with ⟨d, rfl⟩, 
    use c * d, ring },
  { apply quad_char_eq_neg_one_of_non_residue, 
    exact residue_mul_non_residue_is_non_residue ⟨ha, hc⟩ ⟨hb, hd⟩ },
  { apply quad_char_eq_neg_one_of_non_residue, 
    exact non_residue_mul_residue_is_non_residue ⟨ha, hc⟩ ⟨hb, hd⟩ },
  { apply quad_char_eq_one_of_quad_residue,
    exact non_residue_mul_non_residue_is_residue hp ⟨ha, hc⟩ ⟨hb, hd⟩ }
end

lemma quad_char_is_sym_of (h : q ≡ 1 [MOD 4]) (i : F) :
χ (-i) = χ i :=
begin
  obtain ⟨p, inst⟩ := char_p.exists F,
  resetI,
  obtain hp := char_ne_two p (or.inl h),
  have := quad_char_eq_one_of (by simp) ((neg_one_eq_sq_iff_card_eq_one_mod_four hp).2 h),
  rw [← one_mul (χ (-i)), ← this, ← quad_char_mul hp],
  congr, ring,
  assumption
end 

lemma quad_char_is_sym_of' (h : q ≡ 1 [MOD 4]) (i j : F) :
χ (j - i) = χ (i - j) :=
by convert quad_char_is_sym_of h (i - j); ring

lemma quad_char_is_skewsym_of (h : q ≡ 3 [MOD 4]) (i : F) :
χ (-i) = - χ i :=
begin
  obtain ⟨p, inst⟩ := char_p.exists F, resetI,
  obtain ⟨hp, h'⟩ := char_ne_two' p h,
  have g := mt (neg_one_eq_sq_iff_card_eq_one_mod_four hp).1 h',
  have := quad_char_eq_neg_one_of (by simp) g,
  rw [← neg_one_mul (χ i), ← this, ← quad_char_mul hp],
  ring_nf, assumption
end

lemma quad_char_is_skewsym_of' (h : q ≡ 3 [MOD 4]) (i j : F) :
χ (j - i) = - χ (i - j) :=
by convert quad_char_is_skewsym_of h (i - j); ring

variable (F)

lemma quad_char.sum_in_units_eq_zero (hp : p ≠ 2):
∑ (b : F) in univ.filter (λ b, b ≠ (0 : F)), χ b = 0 :=
begin
  rw [finset.sum_split _ (λ b : F, is_quad_residue b)],
  have h1 : ∑ (j : F) in filter (λ (b : F), is_quad_residue b) (filter (λ (b : F), b ≠ 0) univ), χ j =
            ∑ (j : F) in {a : F | is_quad_residue a}.to_finset, 1,
  { apply finset.sum_congr,
    {ext, split, all_goals {intro h, simp* at *}, use h.1},
    intros x hx,
    simp* at * },
  have h2 : ∑ (j : F) in filter (λ (x : F), ¬is_quad_residue x) (filter (λ (b : F), b ≠ 0) univ), χ j =
            ∑ (j : F) in {a : F | is_non_residue a}.to_finset, -1,
  { apply finset.sum_congr,
    {ext, split, all_goals {intro h, simp [*, is_non_residue, is_quad_residue] at *}},
    intros x hx,
    simp* at * },
  simp at h1 h2,
  rw [h1, h2, card_residues_eq_card_non_residues_set hp],
  simp,
  assumption       
end

lemma quad_char.sum_in_univ_eq_zero (hp : p ≠ 2):
∑ (a : F), χ a = 0 :=
begin
  rw [finset.sum_split _ (λ b, b ≠ (0 : F)), quad_char.sum_in_units_eq_zero F hp],
  simp,
end

variable {F}

@[simp]
lemma quad_char.sum_in_univ_eq_zero_reindex_1 (hp : p ≠ 2) {a : F}: --cite
∑ (b : F), χ (a - b) = 0 :=
begin
  rw ← quad_char.sum_in_univ_eq_zero F hp,
  refine fintype.sum_equiv ((equiv.add_left (-a)).trans (equiv.neg _)) _ _ _,
  simp[add_comm, sub_eq_add_neg],
end

@[simp]
lemma quad_char.sum_in_univ_eq_zero_reindex_2 (hp : p ≠ 2) {b : F}: --cite
∑ (a : F), χ (a - b) = 0 :=
begin
  rw ← quad_char.sum_in_univ_eq_zero F hp,
  refine fintype.sum_equiv (equiv.add_right (-b)) _ _ _,
  simp[add_comm, sub_eq_add_neg],
end

lemma quad_char_sum_mul'_aux {c : F} (hc : c ≠ 0) :
∑ (b : F) in filter (λ (b : F), ¬b = 0) univ, χ (b⁻¹ * (b + c)) =
∑ (z : F) in filter (λ (z : F), ¬z = 1) univ, χ (z) :=
begin
  refine finset.sum_bij (λ b hb, b⁻¹ * (b + c)) (λ b hb, _) (λ b hb, rfl) (λ b₁ b₂ h1 h2 h, _) (λ z hz, _),
  { simp at hb, simp [*, mul_add] at * },
  { simp at h1 h2, rw mul_add at h, rw mul_add at h, simp* at h, assumption},
  { use c * (z - 1)⁻¹, simp, simp at hz, push_neg, refine ⟨⟨hc, sub_ne_zero.mpr hz⟩, _⟩, 
    simp [*, mul_inv_rev', mul_add, mul_assoc, sub_ne_zero.mpr hz] }
end

theorem quad_char_sum_mul' {c : F} (hc : c ≠ 0) (hp : p ≠ 2): 
∑ b : F, χ (b) * χ (b + c) = -1 := 
begin
  rw [finset.sum_split _ (λ b, b ≠ (0 : F))],
  simp,
  have h: ∑ (b : F) in filter (λ (b : F), ¬b = 0) univ, χ b * χ (b + c) = 
          ∑ (b : F) in filter (λ (b : F), ¬b = 0) univ, χ b * χ b * χ (b⁻¹ * (b + c)),
  { apply finset.sum_congr rfl,
    intros b hb, simp at hb, 
    have : b * b * (b⁻¹ * (b + c)) = b * (b + c), {field_simp, ring},
    repeat {rw ←(quad_char_mul hp)}, rw ← this,
    all_goals {assumption} },
  have h': ∑ (b : F) in filter (λ (b : F), ¬b = 0) univ, χ b * χ b * χ (b⁻¹ * (b + c)) = 
           ∑ (b : F) in filter (λ (b : F), ¬b = 0) univ, χ (b⁻¹ * (b + c)),
  { apply finset.sum_congr rfl, intros b hb, simp* at *},
  rw [h, h', quad_char_sum_mul'_aux hc],
  have g:= @finset.sum_split _ _ _ (@finset.univ F _) (χ) (λ b : F, b ≠ (1 : F)) _,
  simp [quad_char.sum_in_univ_eq_zero F hp] at g,
  rw [← sub_zero (∑ (z : F) in filter (λ (b : F), ¬b = 1) univ, χ z), g],
  ring,
end 

theorem quad_char_sum_mul {a b : F} (hab : a ≠ b) (hp : p ≠ 2): 
∑ i : F, χ (a - i) * χ (b - i) = -1 := 
begin
  have hc := sub_ne_zero.mpr (ne.symm hab),
  rw ← quad_char_sum_mul' hc hp,
  refine fintype.sum_equiv ((equiv.add_left (-a)).trans (equiv.neg _)) _ _ _,
  intros,
  simp,
  congr; ring
end

end quad_char
/- ## end quad_char -/

end finite_field