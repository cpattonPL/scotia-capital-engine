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
