from dataclasses import dataclass

from scotia_capital.config.constants import LEVERAGE_MULTIPLIER
from scotia_capital.domain.enums import CommitmentType


@dataclass(frozen=True)
class LeverageResult:
    drawn: float
    undrawn: float
    undrawn_factor: float
    leverage_exposure: float
    leverage_addon: float  # 0.25% * leverage_exposure


def undrawn_factor_for_loans(commitment_type: CommitmentType, original_term_months: int) -> float:
    """
    Per Scotia leverage exposure rules for loans:

    - Drawn factor A = 100% (handled in compute)
    - Undrawn factor depends on commitment type and term:
        * Committed: 20% if term <= 12 months, else 50%
        * Uncommitted & Advised: 10%
        * Uncommitted & Unadvised: 10%
    """
    if original_term_months <= 0:
        raise ValueError("original_term_months must be >= 1")

    if commitment_type == CommitmentType.COMMITTED:
        return 0.20 if original_term_months <= 12 else 0.50

    if commitment_type in (CommitmentType.UNCOMMITTED_ADVISED, CommitmentType.UNCOMMITTED_UNADVISED):
        return 0.10

    raise ValueError(f"Unsupported commitment type: {commitment_type}")


def leverage_exposure(balance_0: float, commitment: float, commitment_type: CommitmentType, original_term_months: int) -> LeverageResult:
    """
    Leverage Exposure = Drawn + Undrawn
      Drawn = A * balance_0 where A = 100%
      Undrawn = factor * max(commitment - balance_0, 0)

    Leverage add-on = 0.25% * Leverage Exposure
    """
    drawn = balance_0
    undrawn = max(commitment - balance_0, 0.0)
    f = undrawn_factor_for_loans(commitment_type=commitment_type, original_term_months=original_term_months)
    le = drawn + f * undrawn
    addon = LEVERAGE_MULTIPLIER * le
    return LeverageResult(
        drawn=drawn,
        undrawn=undrawn,
        undrawn_factor=f,
        leverage_exposure=le,
        leverage_addon=addon,
    )
