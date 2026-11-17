"""Shared helpers for the DDQN collective pitch control result notebooks.

All notebooks live in the Results folder and read the OpenFAST outputs from Results/Data.
"""
from pathlib import Path

import numpy as np
import pandas as pd
from openfast_toolbox import FASTOutputFile

ROOT = Path(__file__).resolve().parent
DATA_DIR = ROOT / "Data"
FIG_DIR = ROOT / "Figures"

P_RATED = 3370.0              # kW, rated electrical power used in the paper
T_MIN, T_MAX = 200.0, 5200.0  # evaluation window [s] for validation and test
CHANNELS = ["GenPwr", "TwrBsMyt", "RootMyb1"]
CHANNEL_LABELS = {"GenPwr": "Power", "TwrBsMyt": "TB", "RootMyb1": "BR"}


def load_fast_file(name):
    """Load an OpenFAST .out file from Data/ and strip the units from the column names.

    Returns (DataFrame, dict channel -> unit).
    """
    df = FASTOutputFile(str(DATA_DIR / name)).toDataFrame()
    rename, units = {}, {}
    for col in df.columns:
        base, _, unit = col.partition("_")
        rename[col] = base
        units[base] = unit.strip("[]")
    return df.rename(columns=rename), units


def window(df, t0=T_MIN, t1=T_MAX):
    """Return the samples with t0 <= Time <= t1."""
    return df[(df["Time"] >= t0) & (df["Time"] <= t1)].reset_index(drop=True)


def scaled_std(signal, reference):
    """STD of `signal` normalised with the min-max range of the ROSCO `reference` signal."""
    lo, hi = reference.min(), reference.max()
    return 0.0 if hi == lo else float(((signal - lo) / (hi - lo)).std())


def generated_energy(df, channel="GenPwr"):
    """Generated energy [kWh] by trapezoidal integration."""
    return float(np.trapezoid(df[channel].to_numpy(), df["Time"].to_numpy()) / 3600.0)


def compare_to_rosco(rosco, cases, t0=T_MIN, t1=T_MAX, channels=CHANNELS):
    """Mean and scaled STD of each channel for ROSCO and every DDQN case.

    rosco : DataFrame of the ROSCO simulation (reference for the scaled STD).
    cases : dict label -> DataFrame of DDQN simulations under the same wind.
    Returns a DataFrame with one column per controller. The last row reports the final
    simulated time, so truncated simulations are visible at a glance.
    """
    ref = window(rosco, t0, t1)
    table = {}
    for label, df in {"ROSCO": rosco, **cases}.items():
        d = window(df, t0, t1)
        row = {}
        for ch in channels:
            row[f"{ch} mean"] = d[ch].mean()
            row[f"{ch} scaled STD"] = scaled_std(d[ch], ref[ch])
        row["Last time step [s]"] = df["Time"].iloc[-1]
        table[label] = row
    return pd.DataFrame(table).round(3)
