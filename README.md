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
