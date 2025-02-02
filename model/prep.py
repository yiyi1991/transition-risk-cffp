import os
import pandas as pd
import message_ix
import ixmp

mp = ixmp.Platform()
from pathlib import Path

from message_ix import Reporter
from model.util import get_logger


log = get_logger(__name__)

# Define constants or configuration
TECH_LIST = [
    "coal_adv",
    "coal_adv_cfNH3",
    "coal_adv_ccs",
    "coal_ppl",
    "coal_ppl_cfNH3",
    "coal_ppl_u",
    "coal_ppl_u_cfNH3",
    "igcc",
    "igcc_ccs",
]

TECH_BF_LIST = [
    "gas_cc",
    "gas_cc_ccs",
    "gas_ct",
    "gas_ppl",
]

SCEN_LIST = [
    "sv_2c",
    # "sv_2c_rapid_phase",
    # "sv_2c_buffer_phase",
    # "sv_1p5c",
    "sv_cpol",
    "sv_2c_cf",
]

REG_LIST = ["R12_SAS", "R12_CHN", "R12_PAS", "R12_RCPA"]

OUTPUT_DIR = "plot"


def get_repo_root():
    """Get the root directory of the repository."""
    current_dir = os.getcwd()
    while not (Path(current_dir) / "setup.py").exists():
        current_dir = os.path.dirname(current_dir)
    return Path(current_dir)


def save_prep(df, file_name):
    """Save a DataFrame to the plot folder with a given filename."""
    file_path = Path(get_repo_root()) / OUTPUT_DIR / file_name
    file_path.parent.mkdir(
        parents=True, exist_ok=True
    )  # Ensure the parent directory exists
    df.to_csv(file_path, index=False)
    log.info(f"File {file_name} saved at: {file_path}")


def prep():
    """Get the data frame ready for plotting. All scenarios included."""
    # Avoid the expensive overhead of calling .append() repeatedly
    d_prep = pd.DataFrame(
        columns=[
            "sc",
            "nl",
            "t",
            "yv",
            "ya",
            "m",
            "ACT",
            "CAP",
            "inv_cost",
        ]
    )

    for scen in SCEN_LIST:
        # Load the scenario
        tar_model = "MESSAGEix-GLOBIOM 2.0-M-R12"
        tar_scen = scen
        scen = message_ix.Scenario(mp, tar_model, tar_scen)

        # Initialize Reporter object
        rep = Reporter.from_scenario(scen)

        # Retrieve scenario name
        sc = scen.scenario
        log.info(f"Scenario {sc} loaded.")

        # Data frame ACT
        s = rep.get("out:nl-t-yv-ya-m")
        df = s.reset_index()
        df.columns = [
            "nl",
            "t",
            "yv",
            "ya",
            "m",
            "ACT",
        ]
        df_act = df.loc[
            (df["t"].isin(TECH_LIST + TECH_BF_LIST)) & (df["nl"].isin(REG_LIST))
        ].copy()

        # Data frame ACT_hist
        s = rep.get("historical_activity:nl-t-ya-m")  # out = output * ACT; output = 1
        df = s.reset_index()
        df.columns = [
            "nl",
            "t",
            "ya",
            "m",
            "ACT",
        ]
        df_act_hist = df.loc[
            (df["t"].isin(TECH_LIST + TECH_BF_LIST)) & (df["nl"].isin(REG_LIST))
        ].copy()
        df_act_hist.loc[:, "yv"] = "hist"
        d = pd.concat([df_act, df_act_hist], ignore_index=True)

        # Data frame CAP
        s = rep.get("CAP:nl-t-yv-ya")
        df = s.reset_index()
        df.columns = [
            "nl",
            "t",
            "yv",
            "ya",
            "CAP",
        ]
        df_cap = df.loc[(df["t"].isin(TECH_LIST)) & (df["nl"].isin(REG_LIST))].copy()
        d = d.merge(df_cap, on=["nl", "t", "yv", "ya"], how="outer")

        # Data frame CAP_hist
        s = rep.get("historical_new_capacity:nl-t-yv")
        df = s.reset_index()
        df.columns = [
            "nl",
            "t",
            "yv",
            "CAP",
        ]
        df_cap_hist = df.loc[
            (df["t"].isin(TECH_LIST)) & (df["nl"].isin(REG_LIST))
        ].copy()
        df_cap_hist.loc[:, "ya"] = df_cap_hist["yv"]
        df_cap_hist["yv"] = "hist"
        ## TODO: Retrive the fmy and adding historical capacity to current capacity

        ## TODO: Scaling by duration period
        ## The baseline is still in a version where historical capacity is reported
        ## as average yearly installed, thus have to be multiplied by period length.

        d = pd.concat([d, df_cap_hist], ignore_index=True)

        # Data frame inv_cost
        s = rep.get("inv_cost:nl-t-yv")
        df = s.reset_index()
        df.columns = ["nl", "t", "yv", "inv_cost"]
        df_inv = df.loc[(df["t"].isin(TECH_LIST)) & (df["nl"].isin(REG_LIST))].copy()
        d = d.merge(
            df_inv,
            on=[
                "nl",
                "t",
                "yv",
            ],
            how="outer",
        ).copy()

        d.loc[:, "sc"] = sc
        print(d.head())

        # Data frame prep
        if d_prep.empty:
            d_prep = d
        else:
            d_prep = pd.concat([d_prep, d], ignore_index=True)
        log.info(f"Scenario {sc} prepped.")

    # Save the prep file to plot folder
    save_prep(d_prep, "d_prep.csv")


# prep()
