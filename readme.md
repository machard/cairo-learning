# What is it

A simple pool where anyone can deposit/withdraw any token.
Anyone can flashloan deposited token for a small price.
The fee generated from the flashloans are distributed proportionnally to the depositors.

# TODO:

- check safety (SafeUint256, SafeCmp, wad or ray)
- add more test scenarios (specifically failing scenarios)
- check usage of locals/tempvar
- Redo with ERC-4626 vault spec