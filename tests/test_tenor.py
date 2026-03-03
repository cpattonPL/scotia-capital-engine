from scotia_capital.utils.tenor import month_to_bucket

def test_q_buckets():
    assert month_to_bucket(1) == "Q1"
    assert month_to_bucket(3) == "Q1"
    assert month_to_bucket(4) == "Q2"
    assert month_to_bucket(12) == "Q4"

def test_year_buckets():
    assert month_to_bucket(13) == "Y2"
    assert month_to_bucket(24) == "Y2"
    assert month_to_bucket(25) == "Y3"

def test_tail_bucket():
    assert month_to_bucket(241) == "Y20"
    assert month_to_bucket(360) == "Y20"
