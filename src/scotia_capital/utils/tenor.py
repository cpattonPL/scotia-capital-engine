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
