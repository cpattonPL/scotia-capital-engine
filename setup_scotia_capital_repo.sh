#!/bin/bash

set -e

REPO_NAME="."

echo "Creating project directory..."
mkdir -p $REPO_NAME
cd $REPO_NAME

echo "Creating folder structure..."
mkdir -p src/scotia_capital/{domain,utils,config} tests

echo "Creating root files..."
cat > README.md << 'EOF'
# Scotia Capital Engine

Capital calculation engine supporting:

- IFRS9 ECL (scenario-weighted, monthly engine)
- Basel-LL (user PD/LGD)
- IRB (AIRB + FIRB)
- Specialized lending slotting
- Standardized RWA (for output floor)
- Leverage exposure add-on (0.25%)

All percent inputs are provided in percent form (e.g. 2.50000%)
and converted internally to decimal.
EOF

cat > requirements.txt << 'EOF'
streamlit
pandas
numpy
scipy
pytest
EOF

cat > .gitignore << 'EOF'
__pycache__/
*.pyc
.env
.venv/
.vscode/
EOF

echo "Creating package files..."

cat > src/scotia_capital/__init__.py << 'EOF'
__version__ = "0.1.0"
EOF

cat > src/scotia_capital/domain/enums.py << 'EOF'
from enum import Enum

class ExposureType(str, Enum):
    CORPORATE = "Corporate"
    SOVEREIGN = "Sovereign"
    BANK = "Bank"

class IRBApproach(str, Enum):
    AIRB = "AIRB"
    FIRB = "FIRB"

class PDInterpretation(str, Enum):
    MARGINAL = "Marginal"
    CUMULATIVE = "Cumulative"

class CommitmentType(str, Enum):
    COMMITTED = "Committed"
    UNCOMMITTED_ADVISED = "Uncommitted & Advised"
    UNCOMMITTED_UNADVISED = "Uncommitted & Unadvised"
EOF

cat > src/scotia_capital/utils/tenor.py << 'EOF'
def month_to_bucket(month: int) -> str:
    if month <= 0:
        raise ValueError("Month must be >= 1")

    if month <= 12:
        quarter = (month - 1) // 3 + 1
        return f"Q{quarter}"

    if month >= 241:
        return "Y20"

    year_index = (month - 1) // 12 + 1
    return f"Y{year_index}"
EOF

cat > src/scotia_capital/utils/discount.py << 'EOF'
def percent_to_decimal(value_percent: float) -> float:
    return value_percent / 100.0

def monthly_discount_factor(month: int, annual_rate_percent: float) -> float:
    if month < 1:
        raise ValueError("Month must be >= 1")

    i = percent_to_decimal(annual_rate_percent)
    return (1 + i) ** (-month / 12)
EOF

cat > src/scotia_capital/config/constants.py << 'EOF'
SCENARIO_DEFAULT_WEIGHTS = {
    "Optimistic": 0.10,
    "Realistic": 0.65,
    "Pessimistic": 0.20,
    "Pess_Front_Loaded": 0.05,
}

LEVERAGE_MULTIPLIER = 0.0025
EOF

cat > tests/test_tenor.py << 'EOF'
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
EOF

cat > tests/test_discount.py << 'EOF'
from scotia_capital.utils.discount import monthly_discount_factor

def test_discount_month_12():
    df = monthly_discount_factor(12, 6.0)
    assert round(df, 6) == round((1.06) ** -1, 6)
EOF

echo ""
echo "Repo scaffold created successfully!"
echo "Next steps:"
echo "1) cd $REPO_NAME"
echo "2) python -m venv .venv && source .venv/bin/activate"
echo "3) pip install -r requirements.txt"
echo "4) PYTHONPATH=src pytest -q"
