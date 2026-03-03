def percent_to_decimal(value_percent: float) -> float:
    return value_percent / 100.0

def monthly_discount_factor(month: int, annual_rate_percent: float) -> float:
    if month < 1:
        raise ValueError("Month must be >= 1")

    i = percent_to_decimal(annual_rate_percent)
    return (1 + i) ** (-month / 12)
