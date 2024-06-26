/-
Copyright (c) 2019 Jan-David Salchow. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jan-David Salchow, Sébastien Gouëzel, Jean Lo
-/
import linear_algebra.finite_dimensional
import analysis.normed_space.riesz_lemma
import analysis.asymptotics

/-!
# Operator norm on the space of continuous linear maps

Define the operator norm on the space of continuous linear maps between normed spaces, and prove
its basic properties. In particular, show that this space is itself a normed space.
-/

noncomputable theory
open_locale classical nnreal


variables {𝕜 : Type*} {E : Type*} {F : Type*} {G : Type*}
[normed_group E] [normed_group F] [normed_group G]

open metric continuous_linear_map

lemma exists_pos_bound_of_bound {f : E → F} (M : ℝ) (h : ∀x, ∥f x∥ ≤ M * ∥x∥) :
  ∃ N, 0 < N ∧ ∀x, ∥f x∥ ≤ N * ∥x∥ :=
⟨max M 1, lt_of_lt_of_le zero_lt_one (le_max_right _ _), λx, calc
  ∥f x∥ ≤ M * ∥x∥ : h x
  ... ≤ max M 1 * ∥x∥ : mul_le_mul_of_nonneg_right (le_max_left _ _) (norm_nonneg _) ⟩

section normed_field
/- Most statements in this file require the field to be non-discrete, as this is necessary
to deduce an inequality `∥f x∥ ≤ C ∥x∥` from the continuity of f. However, the other direction always
holds. In this section, we just assume that `𝕜` is a normed field. In the remainder of the file,
it will be non-discrete. -/

variables [normed_field 𝕜] [normed_space 𝕜 E] [normed_space 𝕜 F] (f : E →ₗ[𝕜] F)

lemma linear_map.lipschitz_of_bound (C : ℝ) (h : ∀x, ∥f x∥ ≤ C * ∥x∥) :
  lipschitz_with (nnreal.of_real C) f :=
lipschitz_with.of_dist_le' $ λ x y, by simpa only [dist_eq_norm, f.map_sub] using h (x - y)

theorem linear_map.antilipschitz_of_bound {K : ℝ≥0} (h : ∀ x, ∥x∥ ≤ K * ∥f x∥) :
  antilipschitz_with K f :=
antilipschitz_with.of_le_mul_dist $
λ x y, by simpa only [dist_eq_norm, f.map_sub] using h (x - y)

lemma linear_map.bound_of_antilipschitz {K : ℝ≥0} (h : antilipschitz_with K f) (x) :
  ∥x∥ ≤ K * ∥f x∥ :=
by simpa only [dist_zero_right, f.map_zero] using h.le_mul_dist x 0

lemma linear_map.uniform_continuous_of_bound (C : ℝ) (h : ∀x, ∥f x∥ ≤ C * ∥x∥) :
  uniform_continuous f :=
(f.lipschitz_of_bound C h).uniform_continuous

lemma linear_map.continuous_of_bound (C : ℝ) (h : ∀x, ∥f x∥ ≤ C * ∥x∥) :
  continuous f :=
(f.lipschitz_of_bound C h).continuous

/-- Construct a continuous linear map from a linear map and a bound on this linear map.
The fact that the norm of the continuous linear map is then controlled is given in
`linear_map.mk_continuous_norm_le`. -/
def linear_map.mk_continuous (C : ℝ) (h : ∀x, ∥f x∥ ≤ C * ∥x∥) : E →L[𝕜] F :=
⟨f, linear_map.continuous_of_bound f C h⟩

/-- Reinterpret a linear map `𝕜 →ₗ[𝕜] E` as a continuous linear map. This construction
is generalized to the case of any finite dimensional domain
in `linear_map.to_continuous_linear_map`. -/
def linear_map.to_continuous_linear_map₁ (f : 𝕜 →ₗ[𝕜] E) : 𝕜 →L[𝕜] E :=
f.mk_continuous (∥f 1∥) $ λ x, le_of_eq $
by { conv_lhs { rw ← mul_one x }, rw [← smul_eq_mul, f.map_smul, norm_smul, mul_comm] }

/-- Construct a continuous linear map from a linear map and the existence of a bound on this linear
map. If you have an explicit bound, use `linear_map.mk_continuous` instead, as a norm estimate will
follow automatically in `linear_map.mk_continuous_norm_le`. -/
def linear_map.mk_continuous_of_exists_bound (h : ∃C, ∀x, ∥f x∥ ≤ C * ∥x∥) : E →L[𝕜] F :=
⟨f, let ⟨C, hC⟩ := h in linear_map.continuous_of_bound f C hC⟩

lemma continuous_of_linear_of_bound {f : E → F} (h_add : ∀ x y, f (x + y) = f x + f y)
  (h_smul : ∀ (c : 𝕜) x, f (c • x) = c • f x) {C : ℝ} (h_bound : ∀ x, ∥f x∥ ≤ C*∥x∥) :
  continuous f :=
let φ : E →ₗ[𝕜] F := ⟨f, h_add, h_smul⟩ in φ.continuous_of_bound C h_bound

@[simp, norm_cast] lemma linear_map.mk_continuous_coe (C : ℝ) (h : ∀x, ∥f x∥ ≤ C * ∥x∥) :
  ((f.mk_continuous C h) : E →ₗ[𝕜] F) = f := rfl

@[simp] lemma linear_map.mk_continuous_apply (C : ℝ) (h : ∀x, ∥f x∥ ≤ C * ∥x∥) (x : E) :
  f.mk_continuous C h x = f x := rfl

@[simp, norm_cast] lemma linear_map.mk_continuous_of_exists_bound_coe (h : ∃C, ∀x, ∥f x∥ ≤ C * ∥x∥) :
  ((f.mk_continuous_of_exists_bound h) : E →ₗ[𝕜] F) = f := rfl

@[simp] lemma linear_map.mk_continuous_of_exists_bound_apply (h : ∃C, ∀x, ∥f x∥ ≤ C * ∥x∥) (x : E) :
  f.mk_continuous_of_exists_bound h x = f x := rfl

@[simp] lemma linear_map.to_continuous_linear_map₁_coe (f : 𝕜 →ₗ[𝕜] E) :
  (f.to_continuous_linear_map₁ : 𝕜 →ₗ[𝕜] E) = f :=
rfl

@[simp] lemma linear_map.to_continuous_linear_map₁_apply (f : 𝕜 →ₗ[𝕜] E) (x) :
  f.to_continuous_linear_map₁ x = f x :=
rfl

lemma linear_map.continuous_iff_is_closed_ker {f : E →ₗ[𝕜] 𝕜} :
  continuous f ↔ is_closed (f.ker : set E) :=
begin
  -- the continuity of f obviously implies that its kernel is closed
  refine ⟨λh, (continuous_iff_is_closed.1 h) {0} (t1_space.t1 0), λh, _⟩,
  -- for the other direction, we assume that the kernel is closed
  by_cases hf : ∀x, x ∈ f.ker,
  { -- if `f = 0`, its continuity is obvious
    have : (f : E → 𝕜) = (λx, 0), by { ext x, simpa using hf x },
    rw this,
    exact continuous_const },
  { /- if `f` is not zero, we use an element `x₀ ∉ ker f` such that `∥x₀∥ ≤ 2 ∥x₀ - y∥` for all
    `y ∈ ker f`, given by Riesz's lemma, and prove that `2 ∥f x₀∥ / ∥x₀∥` gives a bound on the
    operator norm of `f`. For this, start from an arbitrary `x` and note that
    `y = x₀ - (f x₀ / f x) x` belongs to the kernel of `f`. Applying the above inequality to `x₀`
    and `y` readily gives the conclusion. -/
    push_neg at hf,
    let r : ℝ := (2 : ℝ)⁻¹,
    have : 0 ≤ r, by norm_num [r],
    have : r < 1, by norm_num [r],
    obtain ⟨x₀, x₀ker, h₀⟩ : ∃ (x₀ : E), x₀ ∉ f.ker ∧ ∀ y ∈ linear_map.ker f, r * ∥x₀∥ ≤ ∥x₀ - y∥,
      from riesz_lemma h hf this,
    have : x₀ ≠ 0,
    { assume h,
      have : x₀ ∈ f.ker, by { rw h, exact (linear_map.ker f).zero_mem },
      exact x₀ker this },
    have rx₀_ne_zero : r * ∥x₀∥ ≠ 0, by { simp [norm_eq_zero, this], norm_num },
    have : ∀x, ∥f x∥ ≤ (((r * ∥x₀∥)⁻¹) * ∥f x₀∥) * ∥x∥,
    { assume x,
      by_cases hx : f x = 0,
      { rw [hx, norm_zero],
        apply_rules [mul_nonneg, norm_nonneg, inv_nonneg.2] },
      { let y := x₀ - (f x₀ * (f x)⁻¹ ) • x,
        have fy_zero : f y = 0, by calc
          f y = f x₀ - (f x₀ * (f x)⁻¹ ) * f x : by simp [y]
          ... = 0 :
            by { rw [mul_assoc, inv_mul_cancel hx, mul_one, sub_eq_zero_of_eq], refl },
        have A : r * ∥x₀∥ ≤ ∥f x₀∥ * ∥f x∥⁻¹ * ∥x∥, from calc
          r * ∥x₀∥ ≤ ∥x₀ - y∥ : h₀ _ (linear_map.mem_ker.2 fy_zero)
          ... = ∥(f x₀ * (f x)⁻¹ ) • x∥ : by { dsimp [y], congr, abel }
          ... = ∥f x₀∥ * ∥f x∥⁻¹ * ∥x∥ :
            by rw [norm_smul, normed_field.norm_mul, normed_field.norm_inv],
        calc
          ∥f x∥ = (r * ∥x₀∥)⁻¹ * (r * ∥x₀∥) * ∥f x∥ : by rwa [inv_mul_cancel, one_mul]
          ... ≤ (r * ∥x₀∥)⁻¹ * (∥f x₀∥ * ∥f x∥⁻¹ * ∥x∥) * ∥f x∥ : begin
            apply mul_le_mul_of_nonneg_right (mul_le_mul_of_nonneg_left A _) (norm_nonneg _),
            exact inv_nonneg.2 (mul_nonneg (by norm_num) (norm_nonneg _))
          end
          ... = (∥f x∥ ⁻¹ * ∥f x∥) * (((r * ∥x₀∥)⁻¹) * ∥f x₀∥) * ∥x∥ : by ring
          ... = (((r * ∥x₀∥)⁻¹) * ∥f x₀∥) * ∥x∥ :
            by { rw [inv_mul_cancel, one_mul], simp [norm_eq_zero, hx] } } },
    exact linear_map.continuous_of_bound f _ this }
end

end normed_field

section add_monoid_hom

lemma add_monoid_hom.isometry_of_norm (f : E →+ F) (hf : ∀ x, ∥f x∥ = ∥x∥) : isometry f :=
begin
  intros x y,
  simp_rw [edist_dist],
  congr',
  simp_rw [dist_eq_norm, ←add_monoid_hom.map_sub],
  exact hf (x - y),
end

end add_monoid_hom

variables [nondiscrete_normed_field 𝕜] [normed_space 𝕜 E] [normed_space 𝕜 F] [normed_space 𝕜 G]
(c : 𝕜) (f g : E →L[𝕜] F) (h : F →L[𝕜] G) (x y z : E)
include 𝕜

lemma linear_map.bound_of_shell (f : E →ₗ[𝕜] F) {ε C : ℝ} (ε_pos : 0 < ε) {c : 𝕜} (hc : 1 < ∥c∥)
  (hf : ∀ x, ε / ∥c∥ ≤ ∥x∥ → ∥x∥ < ε → ∥f x∥ ≤ C * ∥x∥) (x : E) :
  ∥f x∥ ≤ C * ∥x∥ :=
begin
  by_cases hx : x = 0, { simp [hx] },
  rcases rescale_to_shell hc ε_pos hx with ⟨δ, hδ, δxle, leδx, δinv⟩,
  simpa only [f.map_smul, norm_smul, mul_left_comm C, mul_le_mul_left (norm_pos_iff.2 hδ)]
    using hf (δ • x) leδx δxle
end

/-- A continuous linear map between normed spaces is bounded when the field is nondiscrete. The
continuity ensures boundedness on a ball of some radius `ε`. The nondiscreteness is then used to
rescale any element into an element of norm in `[ε/C, ε]`, whose image has a controlled norm. The
norm control for the original element follows by rescaling. -/
lemma linear_map.bound_of_continuous (f : E →ₗ[𝕜] F) (hf : continuous f) :
  ∃ C, 0 < C ∧ (∀ x : E, ∥f x∥ ≤ C * ∥x∥) :=
begin
  have : continuous_at f 0 := continuous_iff_continuous_at.1 hf _,
  rcases (nhds_basis_closed_ball.tendsto_iff nhds_basis_closed_ball).1 this 1 zero_lt_one
    with ⟨ε, ε_pos, hε⟩,
  simp only [mem_closed_ball, dist_zero_right, f.map_zero] at hε,
  rcases normed_field.exists_one_lt_norm 𝕜 with ⟨c, hc⟩,
  refine ⟨ε⁻¹ * ∥c∥, mul_pos (inv_pos.2 ε_pos) (lt_trans zero_lt_one hc), _⟩,
  suffices : ∀ x, ε / ∥c∥ ≤ ∥x∥ → ∥x∥ < ε → ∥f x∥ ≤ ε⁻¹ * ∥c∥ * ∥x∥,
    from f.bound_of_shell ε_pos hc this,
  intros x hle hlt,
  refine (hε _ hlt.le).trans _,
  rwa [mul_assoc, ← div_le_iff' (inv_pos.2 ε_pos), div_eq_mul_inv, inv_inv', one_mul,
    ← div_le_iff' (zero_lt_one.trans hc)]
end

namespace continuous_linear_map

theorem bound : ∃ C, 0 < C ∧ (∀ x : E, ∥f x∥ ≤ C * ∥x∥) :=
f.to_linear_map.bound_of_continuous f.2

section
open asymptotics filter

theorem is_O_id (l : filter E) : is_O f (λ x, x) l :=
let ⟨M, hMp, hM⟩ := f.bound in is_O_of_le' l hM

theorem is_O_comp {α : Type*} (g : F →L[𝕜] G) (f : α → F) (l : filter α) :
  is_O (λ x', g (f x')) f l :=
(g.is_O_id ⊤).comp_tendsto le_top

theorem is_O_sub (f : E →L[𝕜] F) (l : filter E) (x : E) :
  is_O (λ x', f (x' - x)) (λ x', x' - x) l :=
f.is_O_comp _ l

/-- A linear map which is a homothety is a continuous linear map.
    Since the field `𝕜` need not have `ℝ` as a subfield, this theorem is not directly deducible from
    the corresponding theorem about isometries plus a theorem about scalar multiplication.  Likewise
    for the other theorems about homotheties in this file.
 -/
def of_homothety (f : E →ₗ[𝕜] F) (a : ℝ) (hf : ∀x, ∥f x∥ = a * ∥x∥) : E →L[𝕜] F :=
f.mk_continuous a (λ x, le_of_eq (hf x))

variable (𝕜)

lemma to_span_singleton_homothety (x : E) (c : 𝕜) : ∥linear_map.to_span_singleton 𝕜 E x c∥ = ∥x∥ * ∥c∥ :=
by {rw mul_comm, exact norm_smul _ _}

/-- Given an element `x` of a normed space `E` over a field `𝕜`, the natural continuous
    linear map from `E` to the span of `x`.-/
def to_span_singleton (x : E) : 𝕜 →L[𝕜] E :=
of_homothety (linear_map.to_span_singleton 𝕜 E x) ∥x∥ (to_span_singleton_homothety 𝕜 x)

end

section op_norm
open set real


/-- The operator norm of a continuous linear map is the inf of all its bounds. -/
def op_norm := Inf {c | 0 ≤ c ∧ ∀ x, ∥f x∥ ≤ c * ∥x∥}
instance has_op_norm : has_norm (E →L[𝕜] F) := ⟨op_norm⟩

lemma norm_def : ∥f∥ = Inf {c | 0 ≤ c ∧ ∀ x, ∥f x∥ ≤ c * ∥x∥} := rfl

-- So that invocations of `real.Inf_le` make sense: we show that the set of
-- bounds is nonempty and bounded below.
lemma bounds_nonempty {f : E →L[𝕜] F} :
  ∃ c, c ∈ { c | 0 ≤ c ∧ ∀ x, ∥f x∥ ≤ c * ∥x∥ } :=
let ⟨M, hMp, hMb⟩ := f.bound in ⟨M, le_of_lt hMp, hMb⟩

lemma bounds_bdd_below {f : E →L[𝕜] F} :
  bdd_below { c | 0 ≤ c ∧ ∀ x, ∥f x∥ ≤ c * ∥x∥ } :=
⟨0, λ _ ⟨hn, _⟩, hn⟩

lemma op_norm_nonneg : 0 ≤ ∥f∥ :=
lb_le_Inf _ bounds_nonempty (λ _ ⟨hx, _⟩, hx)

/-- The fundamental property of the operator norm: `∥f x∥ ≤ ∥f∥ * ∥x∥`. -/
theorem le_op_norm : ∥f x∥ ≤ ∥f∥ * ∥x∥ :=
classical.by_cases
  (λ heq : x = 0, by { rw heq, simp })
  (λ hne, have hlt : 0 < ∥x∥, from norm_pos_iff.2 hne,
    (div_le_iff hlt).mp ((le_Inf _ bounds_nonempty bounds_bdd_below).2
    (λ c ⟨_, hc⟩, (div_le_iff hlt).mpr $ by { apply hc })))

theorem le_op_norm_of_le {c : ℝ} {x} (h : ∥x∥ ≤ c) : ∥f x∥ ≤ ∥f∥ * c :=
le_trans (f.le_op_norm x) (mul_le_mul_of_nonneg_left h f.op_norm_nonneg)

theorem le_of_op_norm_le {c : ℝ} (h : ∥f∥ ≤ c) (x : E) : ∥f x∥ ≤ c * ∥x∥ :=
(f.le_op_norm x).trans (mul_le_mul_of_nonneg_right h (norm_nonneg x))

/-- continuous linear maps are Lipschitz continuous. -/
theorem lipschitz : lipschitz_with ⟨∥f∥, op_norm_nonneg f⟩ f :=
lipschitz_with.of_dist_le_mul $ λ x y,
  by { rw [dist_eq_norm, dist_eq_norm, ←map_sub], apply le_op_norm }

lemma ratio_le_op_norm : ∥f x∥ / ∥x∥ ≤ ∥f∥ :=
div_le_iff_of_nonneg_of_le (norm_nonneg _) f.op_norm_nonneg (le_op_norm _ _)

/-- The image of the unit ball under a continuous linear map is bounded. -/
lemma unit_le_op_norm : ∥x∥ ≤ 1 → ∥f x∥ ≤ ∥f∥ :=
mul_one ∥f∥ ▸ f.le_op_norm_of_le

/-- If one controls the norm of every `A x`, then one controls the norm of `A`. -/
lemma op_norm_le_bound {M : ℝ} (hMp: 0 ≤ M) (hM : ∀ x, ∥f x∥ ≤ M * ∥x∥) :
  ∥f∥ ≤ M :=
Inf_le _ bounds_bdd_below ⟨hMp, hM⟩

theorem op_norm_le_of_lipschitz {f : E →L[𝕜] F} {K : ℝ≥0} (hf : lipschitz_with K f) :
  ∥f∥ ≤ K :=
f.op_norm_le_bound K.2 $ λ x, by simpa only [dist_zero_right, f.map_zero] using hf.dist_le_mul x 0

lemma op_norm_le_of_shell {f : E →L[𝕜] F} {ε C : ℝ} (ε_pos : 0 < ε) (hC : 0 ≤ C)
  {c : 𝕜} (hc : 1 < ∥c∥) (hf : ∀ x, ε / ∥c∥ ≤ ∥x∥ → ∥x∥ < ε → ∥f x∥ ≤ C * ∥x∥) :
  ∥f∥ ≤ C :=
f.op_norm_le_bound hC $ (f : E →ₗ[𝕜] F).bound_of_shell ε_pos hc hf

lemma op_norm_le_of_ball {f : E →L[𝕜] F} {ε : ℝ} {C : ℝ} (ε_pos : 0 < ε) (hC : 0 ≤ C)
  (hf : ∀ x ∈ ball (0 : E) ε, ∥f x∥ ≤ C * ∥x∥) : ∥f∥ ≤ C :=
begin
  rcases normed_field.exists_one_lt_norm 𝕜 with ⟨c, hc⟩,
  refine op_norm_le_of_shell ε_pos hC hc (λ x _ hx, hf x _),
  rwa ball_0_eq
end

lemma op_norm_le_of_shell' {f : E →L[𝕜] F} {ε C : ℝ} (ε_pos : 0 < ε) (hC : 0 ≤ C)
  {c : 𝕜} (hc : ∥c∥ < 1) (hf : ∀ x, ε * ∥c∥ ≤ ∥x∥ → ∥x∥ < ε → ∥f x∥ ≤ C * ∥x∥) :
  ∥f∥ ≤ C :=
begin
  by_cases h0 : c = 0,
  { refine op_norm_le_of_ball ε_pos hC (λ x hx, hf x _ _),
    { simp [h0] },
    { rwa ball_0_eq at hx } },
  { rw [← inv_inv' c, normed_field.norm_inv,
      inv_lt_one_iff_of_pos (norm_pos_iff.2 $ inv_ne_zero h0)] at hc,
    refine op_norm_le_of_shell ε_pos hC hc _,
    rwa [normed_field.norm_inv, div_eq_mul_inv, inv_inv'] }
end

lemma op_norm_eq_of_bounds {φ : E →L[𝕜] F} {M : ℝ} (M_nonneg : 0 ≤ M)
  (h_above : ∀ x, ∥φ x∥ ≤ M*∥x∥) (h_below : ∀ N ≥ 0, (∀ x, ∥φ x∥ ≤ N*∥x∥) → M ≤ N) :
  ∥φ∥ = M :=
le_antisymm (φ.op_norm_le_bound M_nonneg h_above)
  ((le_cInf_iff continuous_linear_map.bounds_bdd_below ⟨M, M_nonneg, h_above⟩).mpr $
   λ N ⟨N_nonneg, hN⟩, h_below N N_nonneg hN)

/-- The operator norm satisfies the triangle inequality. -/
theorem op_norm_add_le : ∥f + g∥ ≤ ∥f∥ + ∥g∥ :=
show ∥f + g∥ ≤ (coe : ℝ≥0 → ℝ) (⟨_, f.op_norm_nonneg⟩ + ⟨_, g.op_norm_nonneg⟩),
from op_norm_le_of_lipschitz (f.lipschitz.add g.lipschitz)

/-- An operator is zero iff its norm vanishes. -/
theorem op_norm_zero_iff : ∥f∥ = 0 ↔ f = 0 :=
iff.intro
  (λ hn, continuous_linear_map.ext (λ x, norm_le_zero_iff.1
    (calc _ ≤ ∥f∥ * ∥x∥ : le_op_norm _ _
     ...     = _ : by rw [hn, zero_mul])))
  (λ hf, le_antisymm (Inf_le _ bounds_bdd_below
    ⟨ge_of_eq rfl, λ _, le_of_eq (by { rw [zero_mul, hf], exact norm_zero })⟩)
    (op_norm_nonneg _))

/-- The norm of the identity is at most `1`. It is in fact `1`, except when the space is trivial
where it is `0`. It means that one can not do better than an inequality in general. -/
lemma norm_id_le : ∥id 𝕜 E∥ ≤ 1 :=
op_norm_le_bound _ zero_le_one (λx, by simp)

/-- If a space is non-trivial, then the norm of the identity equals `1`. -/
lemma norm_id [nontrivial E] : ∥id 𝕜 E∥ = 1 :=
le_antisymm norm_id_le $ let ⟨x, hx⟩ := exists_ne (0 : E) in
have _ := (id 𝕜 E).ratio_le_op_norm x,
by rwa [id_apply, div_self (ne_of_gt $ norm_pos_iff.2 hx)] at this

@[simp] lemma norm_id_field : ∥id 𝕜 𝕜∥ = 1 :=
norm_id

@[simp] lemma norm_id_field' : ∥(1 : 𝕜 →L[𝕜] 𝕜)∥ = 1 :=
norm_id_field

lemma op_norm_smul_le : ∥c • f∥ ≤ ∥c∥ * ∥f∥ :=
((c • f).op_norm_le_bound
  (mul_nonneg (norm_nonneg _) (op_norm_nonneg _)) (λ _,
  begin
    erw [norm_smul, mul_assoc],
    exact mul_le_mul_of_nonneg_left (le_op_norm _ _) (norm_nonneg _)
  end))

lemma op_norm_neg : ∥-f∥ = ∥f∥ := by { rw norm_def, apply congr_arg, ext, simp }

/-- Continuous linear maps themselves form a normed space with respect to
    the operator norm. -/
instance to_normed_group : normed_group (E →L[𝕜] F) :=
normed_group.of_core _ ⟨op_norm_zero_iff, op_norm_add_le, op_norm_neg⟩

instance to_normed_space : normed_space 𝕜 (E →L[𝕜] F) :=
⟨op_norm_smul_le⟩

/-- The operator norm is submultiplicative. -/
lemma op_norm_comp_le (f : E →L[𝕜] F) : ∥h.comp f∥ ≤ ∥h∥ * ∥f∥ :=
(Inf_le _ bounds_bdd_below
  ⟨mul_nonneg (op_norm_nonneg _) (op_norm_nonneg _), λ x,
    by { rw mul_assoc, exact h.le_op_norm_of_le (f.le_op_norm x) } ⟩)

/-- Continuous linear maps form a normed ring with respect to the operator norm. -/
instance to_normed_ring : normed_ring (E →L[𝕜] E) :=
{ norm_mul := op_norm_comp_le,
  .. continuous_linear_map.to_normed_group }

/-- For a nonzero normed space `E`, continuous linear endomorphisms form a normed algebra with
respect to the operator norm. -/
instance to_normed_algebra [nontrivial E] : normed_algebra 𝕜 (E →L[𝕜] E) :=
{ norm_algebra_map_eq := λ c, show ∥c • id 𝕜 E∥ = ∥c∥,
    by {rw [norm_smul, norm_id], simp},
  .. continuous_linear_map.algebra }

/-- A continuous linear map is automatically uniformly continuous. -/
protected theorem uniform_continuous : uniform_continuous f :=
f.lipschitz.uniform_continuous

variable {f}
/-- A continuous linear map is an isometry if and only if it preserves the norm. -/
lemma isometry_iff_norm_image_eq_norm :
  isometry f ↔ ∀x, ∥f x∥ = ∥x∥ :=
begin
  rw isometry_emetric_iff_metric,
  split,
  { assume H x,
    have := H x 0,
    rwa [dist_eq_norm, dist_eq_norm, f.map_zero, sub_zero, sub_zero] at this },
  { assume H x y,
    rw [dist_eq_norm, dist_eq_norm, ← f.map_sub, H] }
end

lemma homothety_norm [nontrivial E] (f : E →L[𝕜] F) {a : ℝ} (hf : ∀x, ∥f x∥ = a * ∥x∥) :
  ∥f∥ = a :=
begin
  obtain ⟨x, hx⟩ : ∃ (x : E), x ≠ 0 := exists_ne 0,
  have ha : 0 ≤ a,
  { apply nonneg_of_mul_nonneg_right,
    rw ← hf x,
    apply norm_nonneg,
    exact norm_pos_iff.mpr hx },
  refine le_antisymm_iff.mpr ⟨_, _⟩,
  { exact continuous_linear_map.op_norm_le_bound f ha (λ y, le_of_eq (hf y)) },
  { rw continuous_linear_map.norm_def,
    apply real.lb_le_Inf _ continuous_linear_map.bounds_nonempty,
    intros c h, rw mem_set_of_eq at h,
    apply (mul_le_mul_right (norm_pos_iff.mpr hx)).mp,
    rw ← hf x, exact h.2 x }
end

lemma to_span_singleton_norm (x : E) : ∥to_span_singleton 𝕜 x∥ = ∥x∥ :=
homothety_norm _ (to_span_singleton_homothety 𝕜 x)

variable (f)

theorem uniform_embedding_of_bound {K : ℝ≥0} (hf : ∀ x, ∥x∥ ≤ K * ∥f x∥) :
  uniform_embedding f :=
(f.to_linear_map.antilipschitz_of_bound hf).uniform_embedding f.uniform_continuous

/-- If a continuous linear map is a uniform embedding, then it is expands the distances
by a positive factor.-/
theorem antilipschitz_of_uniform_embedding (hf : uniform_embedding f) :
  ∃ K, antilipschitz_with K f :=
begin
  obtain ⟨ε, εpos, hε⟩ : ∃ (ε : ℝ) (H : ε > 0), ∀ {x y : E}, dist (f x) (f y) < ε → dist x y < 1,
    from (uniform_embedding_iff.1 hf).2.2 1 zero_lt_one,
  let δ := ε/2,
  have δ_pos : δ > 0 := half_pos εpos,
  have H : ∀{x}, ∥f x∥ ≤ δ → ∥x∥ ≤ 1,
  { assume x hx,
    have : dist x 0 ≤ 1,
    { refine (hε _).le,
      rw [f.map_zero, dist_zero_right],
      exact hx.trans_lt (half_lt_self εpos) },
    simpa using this },
  rcases normed_field.exists_one_lt_norm 𝕜 with ⟨c, hc⟩,
  refine ⟨⟨δ⁻¹, _⟩ * nnnorm c, f.to_linear_map.antilipschitz_of_bound $ λx, _⟩,
  exact inv_nonneg.2 (le_of_lt δ_pos),
  by_cases hx : f x = 0,
  { have : f x = f 0, by { simp [hx] },
    have : x = 0 := (uniform_embedding_iff.1 hf).1 this,
    simp [this] },
  { rcases rescale_to_shell hc δ_pos hx with ⟨d, hd, dxlt, ledx, dinv⟩,
    rw [← f.map_smul d] at dxlt,
    have : ∥d • x∥ ≤ 1 := H dxlt.le,
    calc ∥x∥ = ∥d∥⁻¹ * ∥d • x∥ :
      by rwa [← normed_field.norm_inv, ← norm_smul, ← mul_smul, inv_mul_cancel, one_smul]
    ... ≤ ∥d∥⁻¹ * 1 :
      mul_le_mul_of_nonneg_left this (inv_nonneg.2 (norm_nonneg _))
    ... ≤ δ⁻¹ * ∥c∥ * ∥f x∥ :
      by rwa [mul_one] }
end

section completeness

open_locale topological_space
open filter

/-- If the target space is complete, the space of continuous linear maps with its norm is also
complete. -/
instance [complete_space F] : complete_space (E →L[𝕜] F) :=
begin
  -- We show that every Cauchy sequence converges.
  refine metric.complete_of_cauchy_seq_tendsto (λ f hf, _),
  -- We now expand out the definition of a Cauchy sequence,
  rcases cauchy_seq_iff_le_tendsto_0.1 hf with ⟨b, b0, b_bound, b_lim⟩, clear hf,
  -- and establish that the evaluation at any point `v : E` is Cauchy.
  have cau : ∀ v, cauchy_seq (λ n, f n v),
  { assume v,
    apply cauchy_seq_iff_le_tendsto_0.2 ⟨λ n, b n * ∥v∥, λ n, _, _, _⟩,
    { exact mul_nonneg (b0 n) (norm_nonneg _) },
    { assume n m N hn hm,
      rw dist_eq_norm,
      apply le_trans ((f n - f m).le_op_norm v) _,
      exact mul_le_mul_of_nonneg_right (b_bound n m N hn hm) (norm_nonneg v) },
    { simpa using b_lim.mul tendsto_const_nhds } },
  -- We assemble the limits points of those Cauchy sequences
  -- (which exist as `F` is complete)
  -- into a function which we call `G`.
  choose G hG using λv, cauchy_seq_tendsto_of_complete (cau v),
  -- Next, we show that this `G` is linear,
  let Glin : E →ₗ[𝕜] F :=
  { to_fun := G,
    map_add' := λ v w, begin
      have A := hG (v + w),
      have B := (hG v).add (hG w),
      simp only [map_add] at A B,
      exact tendsto_nhds_unique A B,
    end,
    map_smul' := λ c v, begin
      have A := hG (c • v),
      have B := filter.tendsto.smul (@tendsto_const_nhds _ ℕ _ c _) (hG v),
      simp only [map_smul] at A B,
      exact tendsto_nhds_unique A B
    end },
  -- and that `G` has norm at most `(b 0 + ∥f 0∥)`.
  have Gnorm : ∀ v, ∥G v∥ ≤ (b 0 + ∥f 0∥) * ∥v∥,
  { assume v,
    have A : ∀ n, ∥f n v∥ ≤ (b 0 + ∥f 0∥) * ∥v∥,
    { assume n,
      apply le_trans ((f n).le_op_norm _) _,
      apply mul_le_mul_of_nonneg_right _ (norm_nonneg v),
      calc ∥f n∥ = ∥(f n - f 0) + f 0∥ : by { congr' 1, abel }
      ... ≤ ∥f n - f 0∥ + ∥f 0∥ : norm_add_le _ _
      ... ≤ b 0 + ∥f 0∥ : begin
        apply add_le_add_right,
        simpa [dist_eq_norm] using b_bound n 0 0 (zero_le _) (zero_le _)
      end },
    exact le_of_tendsto (hG v).norm (eventually_of_forall A) },
  -- Thus `G` is continuous, and we propose that as the limit point of our original Cauchy sequence.
  let Gcont := Glin.mk_continuous _ Gnorm,
  use Gcont,
  -- Our last task is to establish convergence to `G` in norm.
  have : ∀ n, ∥f n - Gcont∥ ≤ b n,
  { assume n,
    apply op_norm_le_bound _ (b0 n) (λ v, _),
    have A : ∀ᶠ m in at_top, ∥(f n - f m) v∥ ≤ b n * ∥v∥,
    { refine eventually_at_top.2 ⟨n, λ m hm, _⟩,
      apply le_trans ((f n - f m).le_op_norm _) _,
      exact mul_le_mul_of_nonneg_right (b_bound n m n (le_refl _) hm) (norm_nonneg v) },
    have B : tendsto (λ m, ∥(f n - f m) v∥) at_top (𝓝 (∥(f n - Gcont) v∥)) :=
      tendsto.norm (tendsto_const_nhds.sub (hG v)),
    exact le_of_tendsto B A },
  erw tendsto_iff_norm_tendsto_zero,
  exact squeeze_zero (λ n, norm_nonneg _) this b_lim,
end

end completeness

section uniformly_extend

variables [complete_space F] (e : E →L[𝕜] G) (h_dense : dense_range e)

section
variables (h_e : uniform_inducing e)

/-- Extension of a continuous linear map `f : E →L[𝕜] F`, with `E` a normed space and `F` a complete
    normed space, along a uniform and dense embedding `e : E →L[𝕜] G`.  -/
def extend : G →L[𝕜] F :=
/- extension of `f` is continuous -/
have cont : _ := (uniform_continuous_uniformly_extend h_e h_dense f.uniform_continuous).continuous,
/- extension of `f` agrees with `f` on the domain of the embedding `e` -/
have eq : _ := uniformly_extend_of_ind h_e h_dense f.uniform_continuous,
{ to_fun := (h_e.dense_inducing h_dense).extend f,
  map_add' :=
  begin
    refine h_dense.induction_on₂ _ _,
    { exact is_closed_eq (cont.comp continuous_add)
        ((cont.comp continuous_fst).add (cont.comp continuous_snd)) },
    { assume x y, simp only [eq, ← e.map_add], exact f.map_add _ _  },
  end,
  map_smul' := λk,
  begin
    refine (λ b, h_dense.induction_on b _ _),
    { exact is_closed_eq (cont.comp (continuous_const.smul continuous_id))
        ((continuous_const.smul continuous_id).comp cont) },
    { assume x, rw ← map_smul, simp only [eq], exact map_smul _ _ _  },
  end,
  cont := cont
}

lemma extend_unique (g : G →L[𝕜] F) (H : g.comp e = f) : extend f e h_dense h_e = g :=
continuous_linear_map.injective_coe_fn $
  uniformly_extend_unique h_e h_dense (continuous_linear_map.ext_iff.1 H) g.continuous

@[simp] lemma extend_zero : extend (0 : E →L[𝕜] F) e h_dense h_e = 0 :=
extend_unique _ _ _ _ _ (zero_comp _)

end

section
variables {N : ℝ≥0} (h_e : ∀x, ∥x∥ ≤ N * ∥e x∥)

local notation `ψ` := f.extend e h_dense (uniform_embedding_of_bound _ h_e).to_uniform_inducing

/-- If a dense embedding `e : E →L[𝕜] G` expands the norm by a constant factor `N⁻¹`, then the norm
    of the extension of `f` along `e` is bounded by `N * ∥f∥`. -/
lemma op_norm_extend_le : ∥ψ∥ ≤ N * ∥f∥ :=
begin
  have uni : uniform_inducing e := (uniform_embedding_of_bound _ h_e).to_uniform_inducing,
  have eq : ∀x, ψ (e x) = f x := uniformly_extend_of_ind uni h_dense f.uniform_continuous,
  by_cases N0 : 0 ≤ N,
  { refine op_norm_le_bound ψ _ (is_closed_property h_dense (is_closed_le _ _) _),
    { exact mul_nonneg N0 (norm_nonneg _) },
    { exact continuous_norm.comp (cont ψ) },
    { exact continuous_const.mul continuous_norm },
    { assume x,
      rw eq,
      calc ∥f x∥ ≤ ∥f∥ * ∥x∥ : le_op_norm _ _
        ... ≤ ∥f∥ * (N * ∥e x∥) : mul_le_mul_of_nonneg_left (h_e x) (norm_nonneg _)
        ... ≤ N * ∥f∥ * ∥e x∥ : by rw [mul_comm ↑N ∥f∥, mul_assoc] } },
  { have he : ∀ x : E, x = 0,
    { assume x,
      have N0 : N ≤ 0 := le_of_lt (lt_of_not_ge N0),
      rw ← norm_le_zero_iff,
      exact le_trans (h_e x) (mul_nonpos_of_nonpos_of_nonneg N0 (norm_nonneg _)) },
    have hf : f = 0, { ext, simp only [he x, zero_apply, map_zero] },
    have hψ : ψ = 0, { rw hf, apply extend_zero },
    rw [hψ, hf, norm_zero, norm_zero, mul_zero] }
end

end

end uniformly_extend

end op_norm

end continuous_linear_map

/-- If a continuous linear map is constructed from a linear map via the constructor `mk_continuous`,
then its norm is bounded by the bound given to the constructor if it is nonnegative. -/
lemma linear_map.mk_continuous_norm_le (f : E →ₗ[𝕜] F) {C : ℝ} (hC : 0 ≤ C) (h : ∀x, ∥f x∥ ≤ C * ∥x∥) :
  ∥f.mk_continuous C h∥ ≤ C :=
continuous_linear_map.op_norm_le_bound _ hC h

namespace continuous_linear_map

/-- The norm of the tensor product of a scalar linear map and of an element of a normed space
is the product of the norms. -/
@[simp] lemma norm_smul_right_apply (c : E →L[𝕜] 𝕜) (f : F) :
  ∥smul_right c f∥ = ∥c∥ * ∥f∥ :=
begin
  refine le_antisymm _ _,
  { apply op_norm_le_bound _ (mul_nonneg (norm_nonneg _) (norm_nonneg _)) (λx, _),
    calc
     ∥(c x) • f∥ = ∥c x∥ * ∥f∥ : norm_smul _ _
     ... ≤ (∥c∥ * ∥x∥) * ∥f∥ :
       mul_le_mul_of_nonneg_right (le_op_norm _ _) (norm_nonneg _)
     ... = ∥c∥ * ∥f∥ * ∥x∥ : by ring },
  { by_cases h : ∥f∥ = 0,
    { rw h, simp [norm_nonneg] },
    { have : 0 < ∥f∥ := lt_of_le_of_ne (norm_nonneg _) (ne.symm h),
      rw ← le_div_iff this,
      apply op_norm_le_bound _ (div_nonneg (norm_nonneg _) (norm_nonneg f)) (λx, _),
      rw [div_mul_eq_mul_div, le_div_iff this],
      calc ∥c x∥ * ∥f∥ = ∥c x • f∥ : (norm_smul _ _).symm
      ... = ∥((smul_right c f) : E → F) x∥ : rfl
      ... ≤ ∥smul_right c f∥ * ∥x∥ : le_op_norm _ _ } },
end

/-- Given `c : c : E →L[𝕜] 𝕜`, `c.smul_rightL` is the continuous linear map from `F` to `E →L[𝕜] F`
sending `f` to `λ e, c e • f`. -/
def smul_rightL (c : E →L[𝕜] 𝕜) : F →L[𝕜] (E →L[𝕜] F) :=
(c.smul_rightₗ : F →ₗ[𝕜] (E →L[𝕜] F)).mk_continuous _ (λ f, le_of_eq $ c.norm_smul_right_apply f)

@[simp] lemma norm_smul_rightL_apply (c : E →L[𝕜] 𝕜) (f : F) :
  ∥c.smul_rightL f∥ = ∥c∥ * ∥f∥ :=
by simp [continuous_linear_map.smul_rightL, continuous_linear_map.smul_rightₗ]

@[simp] lemma norm_smul_rightL (c : E →L[𝕜] 𝕜) [nontrivial F] :
  ∥(c.smul_rightL : F →L[𝕜] (E →L[𝕜] F))∥ = ∥c∥ :=
continuous_linear_map.homothety_norm _ c.norm_smul_right_apply

variables (𝕜 F)

/-- The linear map obtained by applying a continuous linear map at a given vector. -/
def applyₗ (v : E) : (E →L[𝕜] F) →ₗ[𝕜] F :=
{ to_fun := λ f, f v,
  map_add' := λ f g, f.add_apply g v,
  map_smul' := λ x f, f.smul_apply x v }

lemma continuous_applyₗ (v : E) : continuous (continuous_linear_map.applyₗ 𝕜 F v) :=
begin
  apply (continuous_linear_map.applyₗ 𝕜 F v).continuous_of_bound,
  intro f,
  rw mul_comm,
  exact f.le_op_norm v,
end

/-- The continuous linear map obtained by applying a continuous linear map at a given vector. -/
def apply (v : E) : (E →L[𝕜] F) →L[𝕜] F :=
⟨continuous_linear_map.applyₗ 𝕜 F v, continuous_linear_map.continuous_applyₗ _ _ _⟩

variables {𝕜 F}

section multiplication_linear
variables (𝕜) (𝕜' : Type*) [normed_ring 𝕜'] [normed_algebra 𝕜 𝕜']

/-- Left-multiplication in a normed algebra, considered as a continuous linear map. -/
def lmul_left : 𝕜' → (𝕜' →L[𝕜] 𝕜') :=
λ x, (algebra.lmul_left 𝕜 x).mk_continuous ∥x∥
(λ y, by {rw algebra.lmul_left_apply, exact norm_mul_le x y})

/-- Right-multiplication in a normed algebra, considered as a continuous linear map. -/
def lmul_right : 𝕜' → (𝕜' →L[𝕜] 𝕜') :=
λ x, (algebra.lmul_right 𝕜 x).mk_continuous ∥x∥
(λ y, by {rw [algebra.lmul_right_apply, mul_comm], exact norm_mul_le y x})

/-- Simultaneous left- and right-multiplication in a normed algebra, considered as a continuous
linear map. -/
def lmul_left_right (vw : 𝕜' × 𝕜') : 𝕜' →L[𝕜] 𝕜' :=
(lmul_right 𝕜 𝕜' vw.2).comp (lmul_left 𝕜 𝕜' vw.1)

@[simp] lemma lmul_left_apply (x y : 𝕜') : lmul_left 𝕜 𝕜' x y = x * y := rfl
@[simp] lemma lmul_right_apply (x y : 𝕜') : lmul_right 𝕜 𝕜' x y = y * x := rfl
@[simp] lemma lmul_left_right_apply (vw : 𝕜' × 𝕜') (x : 𝕜') :
  lmul_left_right 𝕜 𝕜' vw x = vw.1 * x * vw.2 := rfl

end multiplication_linear

section restrict_scalars

variable (𝕜)
variables {𝕜' : Type*} [normed_field 𝕜'] [normed_algebra 𝕜 𝕜']
variables {E' : Type*} [normed_group E'] [normed_space 𝕜 E'] [normed_space 𝕜' E']
variables [is_scalar_tower 𝕜 𝕜' E']
variables {F' : Type*} [normed_group F'] [normed_space 𝕜 F'] [normed_space 𝕜' F']
variables [is_scalar_tower 𝕜 𝕜' F']

/-- `𝕜`-linear continuous function induced by a `𝕜'`-linear continuous function when `𝕜'` is a
normed algebra over `𝕜`. -/
def restrict_scalars (f : E' →L[𝕜'] F') :
  E' →L[𝕜] F' :=
{ cont := f.cont,
  ..linear_map.restrict_scalars 𝕜 (f.to_linear_map) }

@[simp, norm_cast] lemma restrict_scalars_coe_eq_coe (f : E' →L[𝕜'] F') :
  (f.restrict_scalars 𝕜 : E' →ₗ[𝕜] F') =
  (f : E' →ₗ[𝕜'] F').restrict_scalars 𝕜 := rfl

@[simp, norm_cast squash] lemma restrict_scalars_coe_eq_coe' (f : E' →L[𝕜'] F') :
  (f.restrict_scalars 𝕜 : E' → F') = f := rfl

end restrict_scalars

section extend_scalars

variables {𝕜' : Type*} [normed_field 𝕜'] [normed_algebra 𝕜 𝕜']
variables {F' : Type*} [normed_group F'] [normed_space 𝕜 F'] [normed_space 𝕜' F']
variables [is_scalar_tower 𝕜 𝕜' F']

instance has_scalar_extend_scalars : has_scalar 𝕜' (E →L[𝕜] F') :=
{ smul := λ c f, (c • f.to_linear_map).mk_continuous (∥c∥ * ∥f∥)
begin
  assume x,
  calc ∥c • (f x)∥ = ∥c∥ * ∥f x∥ : norm_smul c _
  ... ≤ ∥c∥ * (∥f∥ * ∥x∥) : mul_le_mul_of_nonneg_left (le_op_norm f x) (norm_nonneg _)
  ... = ∥c∥ * ∥f∥ * ∥x∥ : (mul_assoc _ _ _).symm
end }

instance module_extend_scalars : module 𝕜' (E →L[𝕜] F') :=
{ smul_zero := λ _, ext $ λ _, smul_zero _,
  zero_smul := λ _, ext $ λ _, zero_smul _ _,
  one_smul  := λ _, ext $ λ _, one_smul _ _,
  mul_smul  := λ _ _ _, ext $ λ _, mul_smul _ _ _,
  add_smul  := λ _ _ _, ext $ λ _, add_smul _ _ _,
  smul_add  := λ _ _ _, ext $ λ _, smul_add _ _ _ }

instance normed_space_extend_scalars : normed_space 𝕜' (E →L[𝕜] F') :=
{ norm_smul_le := λ c f,
    linear_map.mk_continuous_norm_le _ (mul_nonneg (norm_nonneg _) (norm_nonneg _)) _ }

/-- When `f` is a continuous linear map taking values in `S`, then `λb, f b • x` is a
continuous linear map. -/
def smul_algebra_right (f : E →L[𝕜] 𝕜') (x : F') : E →L[𝕜] F' :=
{ cont := by continuity!, .. f.to_linear_map.smul_algebra_right x }

@[simp] theorem smul_algebra_right_apply (f : E →L[𝕜] 𝕜') (x : F') (c : E) :
  smul_algebra_right f x c = f c • x := rfl

end extend_scalars

end continuous_linear_map

/-- The continuous linear map of inclusion from a submodule of `K` into `E`. -/
def submodule.subtype_continuous (K : submodule 𝕜 E) : K →L[𝕜] E :=
linear_map.mk_continuous
  K.subtype
  1
  (λ x, by { simp only [one_mul, submodule.subtype_apply], refl })

@[simp] lemma submodule.subtype_continuous_apply (K : submodule 𝕜 E) (v : K) :
  submodule.subtype_continuous K v = (v : E) :=
rfl

section has_sum

-- Results in this section hold for continuous additive monoid homomorphisms or equivalences but we
-- don't have bundled continuous additive homomorphisms.

variables {ι R M M₂ : Type*} [semiring R] [add_comm_monoid M] [semimodule R M]
  [add_comm_monoid M₂] [semimodule R M₂] [topological_space M] [topological_space M₂]

omit 𝕜

/-- Applying a continuous linear map commutes with taking an (infinite) sum. -/
protected lemma continuous_linear_map.has_sum {f : ι → M} (φ : M →L[R] M₂) {x : M}
  (hf : has_sum f x) :
  has_sum (λ (b:ι), φ (f b)) (φ x) :=
by simpa only using hf.map φ.to_linear_map.to_add_monoid_hom φ.continuous

alias continuous_linear_map.has_sum ← has_sum.mapL

protected lemma continuous_linear_map.summable {f : ι → M} (φ : M →L[R] M₂) (hf : summable f) :
  summable (λ b:ι, φ (f b)) :=
(hf.has_sum.mapL φ).summable

alias continuous_linear_map.summable ← summable.mapL

protected lemma continuous_linear_map.map_tsum [t2_space M₂] {f : ι → M}
  (φ : M →L[R] M₂) (hf : summable f) : φ (∑' z, f z) = ∑' z, φ (f z) :=
(hf.has_sum.mapL φ).tsum_eq.symm

/-- Applying a continuous linear map commutes with taking an (infinite) sum. -/
protected lemma continuous_linear_equiv.has_sum {f : ι → M} (e : M ≃L[R] M₂) {y : M₂} :
  has_sum (λ (b:ι), e (f b)) y ↔ has_sum f (e.symm y) :=
⟨λ h, by simpa only [e.symm.coe_coe, e.symm_apply_apply] using h.mapL (e.symm : M₂ →L[R] M),
  λ h, by simpa only [e.coe_coe, e.apply_symm_apply] using (e : M →L[R] M₂).has_sum h⟩

protected lemma continuous_linear_equiv.summable {f : ι → M} (e : M ≃L[R] M₂) :
  summable (λ b:ι, e (f b)) ↔ summable f :=
⟨λ hf, (e.has_sum.1 hf.has_sum).summable, (e : M →L[R] M₂).summable⟩

lemma continuous_linear_equiv.tsum_eq_iff [t2_space M] [t2_space M₂] {f : ι → M}
  (e : M ≃L[R] M₂) {y : M₂} : (∑' z, e (f z)) = y ↔ (∑' z, f z) = e.symm y :=
begin
  by_cases hf : summable f,
  { exact ⟨λ h, (e.has_sum.mp ((e.summable.mpr hf).has_sum_iff.mpr h)).tsum_eq,
      λ h, (e.has_sum.mpr (hf.has_sum_iff.mpr h)).tsum_eq⟩ },
  { have hf' : ¬summable (λ z, e (f z)) := λ h, hf (e.summable.mp h),
    rw [tsum_eq_zero_of_not_summable hf, tsum_eq_zero_of_not_summable hf'],
    exact ⟨by { rintro rfl, simp }, λ H, by simpa using (congr_arg (λ z, e z) H)⟩ }
end

protected lemma continuous_linear_equiv.map_tsum [t2_space M] [t2_space M₂] {f : ι → M}
  (e : M ≃L[R] M₂) : e (∑' z, f z) = ∑' z, e (f z) :=
by { refine symm (e.tsum_eq_iff.mpr _), rw e.symm_apply_apply _ }

end has_sum

namespace continuous_linear_equiv

variable (e : E ≃L[𝕜] F)

protected lemma lipschitz : lipschitz_with (nnnorm (e : E →L[𝕜] F)) e :=
(e : E →L[𝕜] F).lipschitz

protected lemma antilipschitz : antilipschitz_with (nnnorm (e.symm : F →L[𝕜] E)) e :=
e.symm.lipschitz.to_right_inverse e.left_inv

theorem is_O_comp {α : Type*} (f : α → E) (l : filter α) :
  asymptotics.is_O (λ x', e (f x')) f l :=
(e : E →L[𝕜] F).is_O_comp f l

theorem is_O_sub (l : filter E) (x : E) :
  asymptotics.is_O (λ x', e (x' - x)) (λ x', x' - x) l :=
(e : E →L[𝕜] F).is_O_sub l x

theorem is_O_comp_rev {α : Type*} (f : α → E) (l : filter α) :
  asymptotics.is_O f (λ x', e (f x')) l :=
(e.symm.is_O_comp _ l).congr_left $ λ _, e.symm_apply_apply _

theorem is_O_sub_rev (l : filter E) (x : E) :
  asymptotics.is_O (λ x', x' - x) (λ x', e (x' - x)) l :=
e.is_O_comp_rev _ _

/-- A continuous linear equiv is a uniform embedding. -/
lemma uniform_embedding : uniform_embedding e :=
e.antilipschitz.uniform_embedding e.lipschitz.uniform_continuous

lemma one_le_norm_mul_norm_symm [nontrivial E] :
  1 ≤ ∥(e : E →L[𝕜] F)∥ * ∥(e.symm : F →L[𝕜] E)∥ :=
begin
  rw [mul_comm],
  convert (e.symm : F →L[𝕜] E).op_norm_comp_le (e : E →L[𝕜] F),
  rw [e.coe_symm_comp_coe, continuous_linear_map.norm_id]
end

lemma norm_pos [nontrivial E] : 0 < ∥(e : E →L[𝕜] F)∥ :=
pos_of_mul_pos_right (lt_of_lt_of_le zero_lt_one e.one_le_norm_mul_norm_symm) (norm_nonneg _)

lemma norm_symm_pos [nontrivial E] : 0 < ∥(e.symm : F →L[𝕜] E)∥ :=
pos_of_mul_pos_left (lt_of_lt_of_le zero_lt_one e.one_le_norm_mul_norm_symm) (norm_nonneg _)

lemma subsingleton_or_norm_symm_pos : subsingleton E ∨ 0 < ∥(e.symm : F →L[𝕜] E)∥ :=
begin
  rcases subsingleton_or_nontrivial E with _i|_i; resetI,
  { left, apply_instance },
  { right, exact e.norm_symm_pos }
end

lemma subsingleton_or_nnnorm_symm_pos : subsingleton E ∨ 0 < (nnnorm $ (e.symm : F →L[𝕜] E)) :=
subsingleton_or_norm_symm_pos e

lemma homothety_inverse (a : ℝ) (ha : 0 < a) (f : E ≃ₗ[𝕜] F) :
  (∀ (x : E), ∥f x∥ = a * ∥x∥) → (∀ (y : F), ∥f.symm y∥ = a⁻¹ * ∥y∥) :=
begin
  intros hf y,
  calc ∥(f.symm) y∥ = a⁻¹ * (a * ∥ (f.symm) y∥) : _
  ... =  a⁻¹ * ∥f ((f.symm) y)∥ : by rw hf
  ... = a⁻¹ * ∥y∥ : by simp,
  rw [← mul_assoc, inv_mul_cancel (ne_of_lt ha).symm, one_mul],
end

variable (𝕜)

/-- A linear equivalence which is a homothety is a continuous linear equivalence. -/
def of_homothety (f : E ≃ₗ[𝕜] F) (a : ℝ) (ha : 0 < a) (hf : ∀x, ∥f x∥ = a * ∥x∥) : E ≃L[𝕜] F :=
{ to_linear_equiv := f,
  continuous_to_fun := f.to_linear_map.continuous_of_bound a (λ x, le_of_eq (hf x)),
  continuous_inv_fun := f.symm.to_linear_map.continuous_of_bound a⁻¹
    (λ x, le_of_eq (homothety_inverse a ha f hf x)) }

lemma to_span_nonzero_singleton_homothety (x : E) (h : x ≠ 0) (c : 𝕜) :
  ∥linear_equiv.to_span_nonzero_singleton 𝕜 E x h c∥ = ∥x∥ * ∥c∥ :=
continuous_linear_map.to_span_singleton_homothety _ _ _

/-- Given a nonzero element `x` of a normed space `E` over a field `𝕜`, the natural
    continuous linear equivalence from `E` to the span of `x`.-/
def to_span_nonzero_singleton (x : E) (h : x ≠ 0) : 𝕜 ≃L[𝕜] (𝕜 ∙ x) :=
of_homothety 𝕜
  (linear_equiv.to_span_nonzero_singleton 𝕜 E x h)
  ∥x∥
  (norm_pos_iff.mpr h)
  (to_span_nonzero_singleton_homothety 𝕜 x h)

/-- Given a nonzero element `x` of a normed space `E` over a field `𝕜`, the natural continuous
    linear map from the span of `x` to `𝕜`.-/
abbreviation coord (x : E) (h : x ≠ 0) : (𝕜 ∙ x) →L[𝕜] 𝕜 :=
  (to_span_nonzero_singleton 𝕜 x h).symm

lemma coord_norm (x : E) (h : x ≠ 0) : ∥coord 𝕜 x h∥ = ∥x∥⁻¹ :=
begin
  have hx : 0 < ∥x∥ := (norm_pos_iff.mpr h),
  haveI : nontrivial (𝕜 ∙ x) := submodule.nontrivial_span_singleton h,
  exact continuous_linear_map.homothety_norm _
        (λ y, homothety_inverse _ hx _ (to_span_nonzero_singleton_homothety 𝕜 x h) _)
end

lemma coord_self (x : E) (h : x ≠ 0) :
  (coord 𝕜 x h) (⟨x, submodule.mem_span_singleton_self x⟩ : 𝕜 ∙ x) = 1 :=
linear_equiv.coord_self 𝕜 E x h

end continuous_linear_equiv

lemma linear_equiv.uniform_embedding (e : E ≃ₗ[𝕜] F) (h₁ : continuous e) (h₂ : continuous e.symm) :
  uniform_embedding e :=
continuous_linear_equiv.uniform_embedding
{ continuous_to_fun := h₁,
  continuous_inv_fun := h₂,
  .. e }

/-- Construct a continuous linear equivalence from a linear equivalence together with
bounds in both directions. -/
def linear_equiv.to_continuous_linear_equiv_of_bounds (e : E ≃ₗ[𝕜] F) (C_to C_inv : ℝ)
  (h_to : ∀ x, ∥e x∥ ≤ C_to * ∥x∥) (h_inv : ∀ x : F, ∥e.symm x∥ ≤ C_inv * ∥x∥) : E ≃L[𝕜] F :=
{ to_linear_equiv := e,
  continuous_to_fun := e.to_linear_map.continuous_of_bound C_to h_to,
  continuous_inv_fun := e.symm.to_linear_map.continuous_of_bound C_inv h_inv }

namespace continuous_linear_map
variables (𝕜) (𝕜' : Type*) [normed_ring 𝕜'] [normed_algebra 𝕜 𝕜']

@[simp] lemma lmul_left_norm (v : 𝕜') : ∥lmul_left 𝕜 𝕜' v∥ = ∥v∥ :=
begin
  refine le_antisymm _ _,
  { exact linear_map.mk_continuous_norm_le _ (norm_nonneg v) _ },
  { simpa [@normed_algebra.norm_one 𝕜 _ 𝕜' _ _] using le_op_norm (lmul_left 𝕜 𝕜' v) (1:𝕜') }
end

@[simp] lemma lmul_right_norm (v : 𝕜') : ∥lmul_right 𝕜 𝕜' v∥ = ∥v∥ :=
begin
  refine le_antisymm _ _,
  { exact linear_map.mk_continuous_norm_le _ (norm_nonneg v) _ },
  { simpa [@normed_algebra.norm_one 𝕜 _ 𝕜' _ _] using le_op_norm (lmul_right 𝕜 𝕜' v) (1:𝕜') }
end

lemma lmul_left_right_norm_le (vw : 𝕜' × 𝕜') :
  ∥lmul_left_right 𝕜 𝕜' vw∥ ≤ ∥vw.1∥ * ∥vw.2∥ :=
by simpa [mul_comm] using op_norm_comp_le (lmul_right 𝕜 𝕜' vw.2) (lmul_left 𝕜 𝕜' vw.1)

end continuous_linear_map
