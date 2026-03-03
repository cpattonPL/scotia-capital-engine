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
