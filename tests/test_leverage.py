from scotia_capital.engines.leverage import leverage_exposure, undrawn_factor_for_loans
from scotia_capital.domain.enums import CommitmentType


def test_undrawn_factor_committed_short_term():
    assert undrawn_factor_for_loans(CommitmentType.COMMITTED, original_term_months=12) == 0.20


def test_undrawn_factor_committed_long_term():
    assert undrawn_factor_for_loans(CommitmentType.COMMITTED, original_term_months=13) == 0.50


def test_undrawn_factor_uncommitted():
    assert undrawn_factor_for_loans(CommitmentType.UNCOMMITTED_ADVISED, original_term_months=6) == 0.10
    assert undrawn_factor_for_loans(CommitmentType.UNCOMMITTED_UNADVISED, original_term_months=24) == 0.10


def test_leverage_exposure_calc():
    # balance 100, commitment 150 => undrawn 50
    # committed, 24 months => factor 0.5
    res = leverage_exposure(
        balance_0=100.0,
        commitment=150.0,
        commitment_type=CommitmentType.COMMITTED,
        original_term_months=24,
    )
    assert res.drawn == 100.0
    assert res.undrawn == 50.0
    assert res.undrawn_factor == 0.50
    assert res.leverage_exposure == 100.0 + 0.50 * 50.0
    # add-on 0.25%
    assert round(res.leverage_addon, 10) == round(0.0025 * res.leverage_exposure, 10)
