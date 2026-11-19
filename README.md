# Unified wind turbine collective pitch control using double deep Q-networks

This repository trains and evaluates a double deep Q-network (DDQN) collective pitch
controller for the IEA Wind 3.4 MW reference turbine (IEA-3.4-130-RWT) in OpenFAST, coupled
through Simulink. A single policy with three incremental pitch actions (−Δβ, 0, +Δβ) operates
across regions 2, 2.5 and 3, while ROSCO's generator-torque controller remains active.
Training follows the two-stage framework (policy transfer from ROSCO, then policy refinement)
of Espinoza et al., *ISA Transactions* 169 (2026) 428–435, doi:10.1016/j.isatra.2026.01.015.

## 1. Repository layout

```
├── IEA3.4-RWT-OpenFAST/        OpenFAST model, ROSCO (libdiscon.dll + DISCON.IN), wind files
│   ├── check_last_run.ipynb    plots and statistics of the last run (IEA-3.4-130-RWT.SFunc.out)
│   └── Wind/                   sawtooth .wnd files and TurbSim .bts/.inp files
│       ├── train_wind/         11 m/s, TI = 10 % (training)
│       ├── val_wind/           11 and 15 m/s, TI = 10 % (validation)
│       └── test_wind/          11 and 15 m/s, TI = 10 %, new seeds (test)
├── Simulink/
│   ├── OpenLoop_2step.mdl      OpenFAST S-function, RL Agent, reward, action mapping, κ and offset
│   ├── Run_OpenLoop_tl_2step.m stage 1: policy transfer
│   ├── Run_OpenLoop_pr_2step.m stage 2: policy refinement + evaluation
│   └── agent/                  trained agents and training statistics
└── Results/                    notebooks that reproduce every table and figure (see Results/README.md)
    ├── Data/                   OpenFAST .out files used by the notebooks
    └── Figures/                figures of the paper
```

## 2. Data

The OpenFAST output files (`Results/Data/*.out`, ~2 GB) and the TurbSim wind fields
(`IEA3.4-RWT-OpenFAST/Wind/**/*.bts`, ~250 MB) are not stored in this repository.
They are available on Zenodo: **DOI: TODO (add after the Zenodo record is created)**.

| Archive | Content | Extract to |
|---|---|---|
| `Results_Data.7z` | All `.out` files used by the notebooks (Section 9) | `Results/Data/` |
| `Wind_bts.7z` | TurbSim `.bts` files (training, validation, test) | `IEA3.4-RWT-OpenFAST/Wind/`, keeping the `train_wind/`, `val_wind/`, `test_wind/` folders |

The `.bts` files can also be regenerated with TurbSim (`TurbSim.exe` is included in
`Wind/train_wind/` and `Wind/test_wind/`) from the `.inp` files stored next to them, which
contain the random seeds:

```
TurbSim.exe IEAonshore_11mps_10_train.inp
```

The notebooks in `Results/` only need the `.out` files; the `.bts` files are needed only to
run new OpenFAST simulations.

## 3. Requirements

**Simulation**
- MATLAB R2025a with Simulink, Reinforcement Learning Toolbox and Deep Learning Toolbox.
- OpenFAST v4.0.2 Simulink interface. From the [OpenFAST releases](https://github.com/OpenFAST/openfast/releases)
  download `OpenFAST-Simulink_x64.dll` and `FAST_SFunc.mexw64`, copy both to one folder
  (e.g. `lib/openfast/`) and add it to the MATLAB path.
- ROSCO controller: `libdiscon.dll` is included in `IEA3.4-RWT-OpenFAST/`
  ([NREL/ROSCO releases](https://github.com/NREL/ROSCO/releases)).
- TurbSim, only to regenerate the `.bts` files from their `.inp` files.

**Analysis**
- Python with `openfast_toolbox`, `numpy` (≥ 2.0), `pandas`, `matplotlib`.

The turbine model comes from the [IEA-3.4-130-RWT repository](https://github.com/WISDEM/IEA-3.4-130-RWT);
ROSCO is used with the official IEA-3.4 `DISCON.IN`, without retuning.

## 4. OpenFAST configuration

Fixed settings: time step `DT = 0.025 s` (`IEA-3.4-130-RWT.fst`), ROSCO DLL as generator-torque
controller (`VSContrl = 5`), pitch rate limiter 7 °/s (variable `rate` in the scripts). The limiter
acts only as a safety bound: the incremental actions keep the commanded pitch rate below it.

The pitch-control source is selected with `PCMode` in `IEA-3.4-130-RWT_ServoDyn.dat`:

| Mode | `PCMode` | `VSContrl` | Pitch controlled by |
|---|---|---|---|
| ROSCO baseline (reference runs) | 5 | 5 | ROSCO |
| Stage 1 — policy transfer (training) | 5 | 5 | ROSCO, live; the agent learns from its actions |
| Stage 2 — policy refinement (training) | 4 | 5 | DDQN agent (Simulink) |
| Evaluation (validation / test) | 4 | 5 | DDQN agent (Simulink) |

## 5. Wind files (`IEA-3.4-130-RWT_InflowFile.dat`)

| Wind type | `WindType` | File parameter |
|---|---|---|
| Sawtooth (uniform `.wnd`) | 2 | `Filename_Uni` |
| Turbulent TurbSim (`.bts`) | 3 | `FileName_BTS` |

| Scenario | Phase | File |
|---|---|---|
| 11 m/s, TI = 10 % | Training | `Wind/train_wind/IEAonshore_11mps_10_train.bts` |
| 8 m/s sawtooth | Validation | `Wind/8 sawtooth.wnd` |
| 10 m/s sawtooth | Validation | `Wind/10 sawtooth.wnd` |
| 15 m/s sawtooth | Validation | `Wind/15 sawtooth.wnd` |
| 11 m/s, TI = 10 % | Validation | `Wind/val_wind/IEAonshore_11mps_10_val.bts` |
| 15 m/s, TI = 10 % | Validation | `Wind/val_wind/IEAonshore_15mps_10_val.bts` |
| 11 m/s, TI = 10 % | Test | `Wind/test_wind/IEAonshore_11mps_10_test.bts` |
| 15 m/s, TI = 10 % | Test | `Wind/test_wind/IEAonshore_15mps_10_test.bts` |

Each `.bts` file has its TurbSim input (`.inp`, with the random seed) and summary (`.sum`) next to it.

**Sawtooth files** are created with `Wind/generador sawtooth wind.ipynb`: the wind alternates between
mean − 0.5 m/s and mean + 0.5 m/s every 10 s (period 20 s, peak-to-peak 1.0 m/s); edit the two values
in `np.where(...)` and the file name for each mean speed. With `VelInterpCubic = true` in the InflowWind
file, OpenFAST interpolates these vertices with cubic splines, so the simulated wind looks sinusoidal.

## 6. Training

Both stages use the agent sampling time `Ts = 0.35 s`, `step = 0.01` (Δβ in degrees) and the
reward in the `Recompensa` subsystem (TSR_opt = 8.02, Ω_rated = 1.21 rad/s, regime threshold 9.5 m/s).
Use the training wind and set the `offset` block to 0 (Section 8). The pitch-rate scaling
(`pitchrate` block) is used only for evaluation.

### Stage 1 — policy transfer (`Run_OpenLoop_tl_2step.m`, `PCMode = 5`)

ROSCO controls the pitch live during the simulation. The `logica_seguimiento` block converts the ROSCO
pitch into incremental actions that the agent stores and evaluates with its own reward: if the ROSCO angle
exceeds the internally tracked angle by more than `zona = 0.09°`, the action is +Δβ; if it is lower by more
than 0.09°, −Δβ; otherwise 0.

Run the script up to `%% Evaluate` (`TMax = 5100 s`, `LearningFrequency = 40`).
Output: `agent/agente_trainPitch.mat`, `agent/estadisticasPitch.mat`.

### Stage 2 — policy refinement (`Run_OpenLoop_pr_2step.m`, `PCMode = 4`)

Loads `agente_trainPitch.mat` and gives control to the agent with ε-greedy exploration
(ε0 = 0.025, ε_decay = 10^-3.25, `LearningFrequency = 10`, `TMax = 800 s`).
Run the script up to `%% Evaluate`.
Output: `agent/agente_trainPitch_pr.mat` (final agent), `agent/estadisticasPitch_pr.mat`.

**Selection of Δβ (Table 3).** Repeat both stages with `step` ∈ {0.125, 0.025, 0.010, 0.005} and the
`zona` value noted for each one in the comments of `Run_OpenLoop_tl_2step.m`.

## 7. Evaluation (validation and test)

1. Set `PCMode = 4`, the wind (Section 5) and the `pitchrate` / `offset` configuration (Section 8).
2. Run the `%% Evaluate` section of **`Run_OpenLoop_pr_2step.m`** (not the one of
   `Run_OpenLoop_tl_2step.m`, which loads the stage-1 agent). It loads the final agent
   `agente_trainPitch_pr.mat` and sets `Ts = 0.025 s` (the OpenFAST time step) and `TMax = 5250 s`.
3. Check that the final agent is loaded and that the greedy policy is used:
   ```matlab
   ref = load('./agent/agente_trainPitch_pr.mat','agent');
   isequal(getLearnableParameters(getCritic(agent)), getLearnableParameters(getCritic(ref.agent)))  % must be 1
   agent.UseExplorationPolicy                                                                      % must be 0
   ```
   If MATLAB is restarted, repeat steps 2 and 3 before the next run.
4. Run the Simulink model `OpenLoop_2step`.
5. Optionally, open `IEA3.4-RWT-OpenFAST/check_last_run.ipynb` to inspect the run. It reads only
   `IEA-3.4-130-RWT.SFunc.out` and shows its signals (wind, power, pitch, rotor, loads), the min/max
   values and the statistics in the window 200–5200 s. It works while the simulation is still running.
   Its scaled STD uses the run's own range; the paper values (normalized with the ROSCO range) come
   from the notebooks in `Results/`.
6. Rename the OpenFAST output `IEA-3.4-130-RWT.SFunc.out` following `Results/Data/README.md`
   (e.g. `val_11ti10_ddqn_0.8-0.3dps.out`) and move it to `Results/Data/`.

For each wind, the ROSCO baseline is run once (`PCMode = 5`) and saved as `<phase>_<wind>_rosco.out`.
The ROSCO runs in `Results/Data/` last 5500 s and the DDQN runs 5250 s; all metrics use the
window 200–5200 s (`Results/utils.py`), so both lengths cover it.

With `Ts = 0.025 s` and Δβ = 0.010°, κ = 1 gives a nominal pitch rate of 0.4 °/s.

## 8. Configurations in the Simulink model

Two MATLAB Function blocks in `OpenLoop_2step.mdl` change between experiments. **Check both before
every run** — the model keeps the configuration used last.

### `pitchrate(t, w, e)` — scaling factor κ (`e` = power error in W)

Nominal pitch rate = κ · 0.4 °/s. Three settings at the top of the block select the configuration:

```matlab
SAW10 = false;  % true only for the 10 m/s sawtooth profile (start-up, see below)
MODE  = 0;      % 0 = fixed rate, 1 = two-level adaptive rule (0.8/0.3 deg/s)
KFIX  = 1;      % fixed kappa (used only when MODE = 0)
```

**Start-up.** The first 200 s are excluded from the metrics. Because the incremental policy limits the
pitch rate, starting at κ = 1 from the fine pitch angle overspeeds the rotor at high wind speeds, so the
rate is raised while the turbine reaches its operating point. The same start-up is used for every DDQN
run of a given scenario:

| Scenario | Start-up | Evaluated configuration from |
|---|---|---|
| 10 m/s sawtooth (`SAW10 = true`) | κ = 1 (0.4 °/s) for t < 50 s | t = 50 s |
| All other scenarios (`SAW10 = false`) | κ = 10 (4 °/s) for t < 10 s, κ = 5 (2 °/s) for 10 ≤ t < 15 s, κ = 2.5 (1 °/s) for 15 ≤ t < 200 s | t = 200 s |

**Evaluated configuration.**

| Configuration | File tag | `MODE` | `KFIX` |
|---|---|---|---|
| Fixed 0.004 °/s | `0.004dps` | 0 | 0.01 |
| Fixed 0.04 °/s | `0.04dps` | 0 | 0.1 |
| Fixed 0.3 °/s | `0.3dps` | 0 | 0.75 |
| No scaling, 0.4 °/s | `0.4dps` | 0 | 1 |
| Fixed 0.6 °/s | `0.6dps` | 0 | 1.5 |
| Fixed 0.8 °/s | `0.8dps` | 0 | 2 |
| Two-level adaptive rule | `0.8-0.3dps` | 1 | — (κ = 2 if \|e\| > 0.1e6 W, else 0.75) |

Leave the block in the paper configuration (`SAW10 = false; MODE = 1; KFIX = 1;`) after the runs.

### `offset(t, w, e)` — pitch offset (`w` = hub-height wind speed in m/s)

| Configuration | File tag | Setting |
|---|---|---|
| No offset (all results except the offset tests) | — | `k = 0` |
| Diagnostic test, 10 m/s sawtooth (in the paper) | `off-1-below` | `k = -1*pi/180` when `t > 51` and `w < 9.8` |
| Complementary tests (not in the paper) | `off-0.5-below`, `off+0.5-below` | `k = ∓0.5*pi/180` when `t > 51` and `w < 9.8` |
| Complementary test (not in the paper) | `off+1-above` | `k = +1*pi/180` when `t > 51` and `w ≥ 9.8` |

All offset tests use the 10 m/s start-up (`SAW10 = true`) and `KFIX = 0.01` (0.004 °/s).

## 9. Paper results → runs

| Paper item | Wind(s) | DDQN configuration | Notebook |
|---|---|---|---|
| Table 3, Fig. 3 | Training wind | Agents with different Δβ, ε0, ε_decay | `01_training_selection.ipynb` |
| Table 4, Fig. 4 | 5 validation winds | κ = 1 (0.4 °/s) | `02_validation_results.ipynb` |
| Fig. 5A | 10 m/s sawtooth | Fixed rates 0.004, 0.04, 0.4, 0.6 °/s (0.3 °/s quoted in the text) | `03_pitch_rate_scaling.ipynb` |
| Fig. 5B | 11 m/s TI = 10 % (validation) | Fixed rates 0.3–0.8 °/s + adaptive rule | `03_pitch_rate_scaling.ipynb` |
| Table 5 | 15 m/s sawtooth; 11 and 15 m/s TI = 10 % (validation) | Adaptive rule (and 0.8 °/s at 15 m/s, quoted in the text) | `03_pitch_rate_scaling.ipynb` |
| Diagnostic offset test | 10 m/s sawtooth | 0.004 °/s + `off-1-below` | `03_pitch_rate_scaling.ipynb` |
| Table 6 | 11 and 15 m/s TI = 10 % (test) | Adaptive rule | `04_test_results.ipynb` |
| Figures 2–5 | — | — | `05_paper_figures.ipynb` (run 03 first) |

## 10. Checklist before each run

- [ ] `PCMode` in ServoDyn (5 = ROSCO / policy transfer, 4 = DDQN)
- [ ] `WindType` and wind file in the InflowWind file
- [ ] `pitchrate` (`SAW10`, `MODE`, `KFIX`) and `offset` blocks set for the intended configuration
- [ ] Final agent `agente_trainPitch_pr.mat` loaded (`isequal` check = 1), greedy policy, `Ts = 0.025 s`, `TMax = 5250 s`
- [ ] Run inspected with `check_last_run.ipynb` (optional), output renamed and copied to `Results/Data/`
