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
