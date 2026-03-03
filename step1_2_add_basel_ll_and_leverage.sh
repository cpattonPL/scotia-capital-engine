#!/bin/bash
set -euo pipefail

# Run this from the root of your repo (the folder that contains src/ and tests/).
if [ ! -d "src/scotia_capital" ]; then
  echo "ERROR: src/scotia_capital not found. Run this script from the repo root."
  exit 1
fi

echo "Creating engines package..."
mkdir -p src/scotia_capital/engines
touch src/scotia_capital/engines/__init__.py

echo "Writing Basel-LL engine..."
cat > src/scotia_capital/engines/basel_ll.py << 'EOF'
from dataclasses import dataclass

from scotia_capital.utils.discount import percent_to_decimal


@dataclass(frozen=True)
class BaselLLResult:
    """
    Basel-LL (Basel-LL / ACL proxy) per your v1 definition:
      - EAD_0 = Balance_0 + UGD * Undrawn_0
      - BaselLL = PD * LGD * EAD_0

    All percent inputs are provided in percent form (e.g., 2.50000 for 2.50000%)
    and converted internally to decimals.
    """
    ead_0: float
    basel_ll: float


def compute_undrawn_0(commitment: float, balance_0: float) -> float:
    """
    Default undrawn at reporting date. Caller may override upstream if needed.
    """
    return max(commitment - balance_0, 0.0)


def compute_ead_0(balance_0: float, undrawn_0: float, ugd_percent: float) -> float:
    ugd = percent_to_decimal(ugd_percent)
    return balance_0 + ugd * undrawn_0


def basel_ll(pd_percent: float, lgd_percent: float, balance_0: float, commitment: float, ugd_percent: float) -> BaselLLResult:
    """
    Convenience wrapper computing Undrawn_0 from commitment - balance_0.
    """
    pd = percent_to_decimal(pd_percent)
    lgd = percent_to_decimal(lgd_percent)
    undrawn_0 = compute_undrawn_0(commitment=commitment, balance_0=balance_0)
    ead_0 = compute_ead_0(balance_0=balance_0, undrawn_0=undrawn_0, ugd_percent=ugd_percent)
    return BaselLLResult(ead_0=ead_0, basel_ll=pd * lgd * ead_0)
EOF

echo "Writing Leverage exposure engine..."
cat > src/scotia_capital/engines/leverage.py << 'EOF'
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
EOF

echo "Updating domain outputs (adds LeverageOutput types for future UI)..."
cat > src/scotia_capital/domain/outputs.py << 'EOF'
from dataclasses import dataclass


@dataclass(frozen=True)
class BaselLLOutput:
    ead_0: float
    basel_ll: float


@dataclass(frozen=True)
class LeverageOutput:
    drawn: float
    undrawn: float
    undrawn_factor: float
    leverage_exposure: float
    leverage_addon: float


@dataclass(frozen=True)
class DiscountOutput:
    month: int
    discount_factor: float
EOF

echo "Adding tests..."
cat > tests/test_basel_ll.py << 'EOF'
from scotia_capital.engines.basel_ll import basel_ll, compute_ead_0


def test_ead_0():
    # Balance 100, undrawn 50, UGD 60% => EAD0 = 100 + 0.6*50 = 130
    assert compute_ead_0(balance_0=100.0, undrawn_0=50.0, ugd_percent=60.0) == 130.0


def test_basel_ll_basic():
    # PD 2%, LGD 45%, EAD0 computed from balance+UGD*undrawn
    res = basel_ll(pd_percent=2.0, lgd_percent=45.0, balance_0=100.0, commitment=150.0, ugd_percent=60.0)
    # EAD0 = 130; BaselLL = 0.02 * 0.45 * 130 = 1.17
    assert round(res.ead_0, 6) == 130.0
    assert round(res.basel_ll, 6) == round(0.02 * 0.45 * 130.0, 6)
EOF

cat > tests/test_leverage.py << 'EOF'
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
EOF

echo "Done."
echo ""
echo "Run tests:"
echo "  PYTHONPATH=src pytest -q"
