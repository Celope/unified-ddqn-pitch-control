# OpenFAST output files

`<phase>_<wind>_<controller>[_<configuration>].out`

- **phase**: `train` (training wind), `val` (validation), `test` (unseen realizations)
- **wind**: `saw08/saw10/saw15` = 8/10/15 m/s sawtooth; `11ti10`, `15ti10` = 11/15 m/s, TI = 10 %
- **controller**: `rosco` or `ddqn`
- **configuration (validation/test)**: nominal pitch rate in °/s (`0.4dps` = no scaling, κ = 1).
  `0.8-0.3dps` = two-level adaptive rule (0.8 °/s when |P − P_rated| > 0.1 MW, otherwise 0.3 °/s).
  `off-1-below` = −1° pitch offset when v < v_rated; `off+1-above` = +1° offset when v > v_rated.
- **configuration (training)**: `db` = pitch increment Δβ [deg]; `pr` = policy-refinement duration [s];
  `eps` = ε0; `dec` = exponent of ε_decay (10^-x). All training runs share the hyperparameters of the paper (Table 2).
