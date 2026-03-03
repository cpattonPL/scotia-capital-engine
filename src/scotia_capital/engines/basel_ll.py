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
