from scotia_capital.utils.discount import monthly_discount_factor

def test_discount_month_12():
    df = monthly_discount_factor(12, 6.0)
    assert round(df, 6) == round((1.06) ** -1, 6)
