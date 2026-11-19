# OpenFAST output files

`<phase>_<wind>_<controller>[_<configuration>].out`

- **phase**: `train` (training wind), `val` (validation), `test` (unseen realizations)
- **wind**: `saw08/saw10/saw15` = 8/10/15 m/s sawtooth; `11ti10`, `15ti10` = 11/15 m/s, TI = 10 %
- **controller**: `rosco` or `ddqn`
- **configuration (validation/test)**: nominal pitch rate in °/s after the start-up
  (`0.4dps` = no scaling, κ = 1; see the main README, Section 8, for the start-up of each scenario).
  `0.8-0.3dps` = two-level adaptive rule (0.8 °/s when |P − P_rated| > 0.1 MW, otherwise 0.3 °/s).
  `off-1-below` = −1° pitch offset when v < v_rated (diagnostic test in the paper).
  `off-0.5-below`, `off+0.5-below`, `off+1-above` = complementary offset tests, not reported in the paper.
- **configuration (training)**: `db` = pitch increment Δβ [deg]; `pr` = policy-refinement duration [s];
  `eps` = ε0; `dec` = exponent of ε_decay (10^-x). All training runs share the hyperparameters of the paper (Table 2).

ROSCO runs last 5500 s and DDQN validation/test runs 5250 s; the metrics use 200–5200 s.
Some training-wind runs end earlier: the Δβ = 0.125°, 0.025° and 0.005° runs were simulated for about
2100 s, and the ε_decay = 10^-2.75 and 10^-3.75 runs stopped before 2000 s (see `01_training_selection.ipynb`).
