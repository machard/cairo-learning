# What is it

A simple pool where anyone can deposit/withdraw any token.
Anyone can flashloan deposited token for a small price.
The fee generated from the flashloans are distributed proportionnally to the depositors.

<img width="1089" alt="Screenshot 2022-09-19 at 16 49 14" src="https://user-images.githubusercontent.com/5071029/191113798-0add61f1-fb0e-4d19-909a-e62b915d2315.png">

# TODO:

- check safety (SafeUint256, SafeCmp, wad or ray)
- add more test scenarios (specifically failing scenarios)
- check usage of locals/tempvar
- Redo with ERC-4626 vault spec
- update to match nethermind code guidelines
