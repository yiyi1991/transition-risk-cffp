import os
from pathlib import Path

from message_ix import Reporter
from model.util import get_logger

log = get_logger(__name__)

# Define constants or configuration
TECH_LIST = [
    "coal_adv",
    "coal_adv_cfNH3",
    "coal_adv_cfbio",
    "coal_adv_ccs",
    "coal_adv_rccs",
    "coal_ppl",
    "coal_ppl_cfNH3",
    "coal_ppl_cfbio",
    "coal_ppl_u",
    "coal_ppl_u_cfNH3",
    "coal_ppl_u_cfbio",
    "igcc",
    "igcc_ccs",
]

TECH_BF_LIST = [
    "gas_cc",
    "gas_cc_ccs",
    "gas_ct",
    "gas_ppl",
]

OUTPUT_DIR = "report"


def get_repo_root():
    """Get the root directory of the repository."""
    current_dir = os.getcwd()
    while not (Path(current_dir) / "setup.py").exists():
        current_dir = os.path.dirname(current_dir)
    return Path(current_dir)


def save_report(df, file_name):
    """Save a DataFrame to the report folder with a given filename."""
    file_path = Path(get_repo_root()) / OUTPUT_DIR / file_name
    file_path.parent.mkdir(
        parents=True, exist_ok=True
    )  # Ensure the parent directory exists
    df.to_csv(file_path, index=False)
    log.info(f"File {file_name} saved at: {file_path}")


def report(scen):
    """Report the activity level (ACT), capacity (CAP), and capital cost (inv_cost) of CFFP technologies in a scenario."""

    # Initialize Reporter object
    rep = Reporter.from_scenario(scen)

    # Retrieve scenario name
    sc = scen.scenario

    # Report ACT
    s = rep.get("out:nl-t-yv-ya-m")
    df_act = s.reset_index()
    df_act.columns = ["nl", "t", "yv", "ya", "m", "ACT"]
    df_act_filtered = df_act.loc[df_act["t"].isin(TECH_LIST)].copy()
    df_act_filtered.loc[:, "sc"] = sc
    save_report(df_act_filtered, f"d_act_{sc}.csv")

    # Report ACT of buffer technologies
    s = rep.get("out:nl-t-ya-m")
    df_act_bf = s.reset_index()
    df_act_bf.columns = ["nl", "t", "ya", "m", "ACT"]
    df_act_bf_filtered = df_act_bf.loc[df_act_bf["t"].isin(TECH_BF_LIST)].copy()
    df_act_bf_filtered.loc[:, "sc"] = sc
    save_report(df_act_bf_filtered, f"d_act_bf_{sc}.csv")

    # Report CAP
    s = rep.get("CAP:nl-t-yv-ya")
    df_cap = s.reset_index()
    df_cap.columns = ["nl", "t", "yv", "ya", "CAP"]
    df_cap_filtered = df_cap.loc[df_cap["t"].isin(TECH_LIST)].copy()
    df_cap_filtered.loc[:, "sc"] = sc
    save_report(df_cap_filtered, f"d_cap_{sc}.csv")

    # Report inv_cost
    s = rep.get("inv_cost:nl-t-yv")
    df_inv_cost = s.reset_index()
    df_inv_cost.columns = ["nl", "t", "yv", "inv_cost"]
    df_inv_cost_filtered = df_inv_cost.loc[df_inv_cost["t"].isin(TECH_LIST)].copy()
    df_inv_cost_filtered.loc[:, "sc"] = sc
    save_report(df_inv_cost_filtered, f"d_inv_cost_{sc}.csv")
