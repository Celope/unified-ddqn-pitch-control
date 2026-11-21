# Results — Unified wind turbine collective pitch control using DDQN

All notebooks read the OpenFAST outputs from `Data/` through `utils.py`
(evaluation window 200–5200 s for validation and test, 200–2000 s for the training-wind comparison).

| Notebook | Paper content |
|---|---|
| `01_training_selection.ipynb` | Table 3, choice of Δβ, ε0 and ε_decay (training wind, NEVI) |
| `02_validation_results.ipynb` | Table 4, validation without scaling; check of the 0.1 MW threshold |
| `03_pitch_rate_scaling.ipynb` | Fixed-rate sweeps, two-level adaptive rule (0.8/0.3 °/s) and its activity, Table 5 (validation block), diagnostic offset test, data for Fig. 5 |
| `04_test_results.ipynb` | Table 5 (test block), test on unseen turbulent winds, and check that the test winds differ from the training and validation winds |
| `05_paper_figures.ipynb` | Figures 2–5, saved to `Figures/` |

In the manuscript, Table 5 combines the validation block (03) and the test block (04) in a single table.

Run 03 before 05: Figure 5 is drawn from `Figures/fig5_data.csv`, which 03 writes.

Requirements: `openfast_toolbox`, `numpy` (≥ 2.0), `pandas`, `matplotlib`.
