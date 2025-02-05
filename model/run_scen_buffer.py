import os
import pandas as pd
import message_ix
import ixmp

mp = ixmp.Platform()
from pathlib import Path
from model.util import get_logger

log = get_logger(__name__)

set_list = [
    "technology",
    "addon",
    "type_addon",
    "cat_addon",
    "map_tec_addon",
    "commodity",
    "relation",
    "shares",
]

par_list = [
    "input",
    "output",
    "inv_cost",
    # "fix_cost",
    # "var_cost",
    # "emission_factor", # N2O, NOx, CO2 as outputs, added to relation_activity
    "relation_activity",
    "relation_lower",
    "technical_lifetime",
    "capacity_factor",
    "growth_new_capacity_up",
    "growth_new_capacity_lo",
    "initial_new_capacity_up",
    "addon_conversion",
    "addon_up",
    # "addon_lo",
    "share_mode_up",  # cofire retrofitting penetration rate
    # "demand",
    # "bound_activity_up",
    # "bound_new_capacity_up",
]

INPUT_DIR = "data"


def get_repo_root():
    """Get the root directory of the repository."""
    current_dir = os.getcwd()
    while not (Path(current_dir) / "setup.py").exists():
        current_dir = os.path.dirname(current_dir)
    return Path(current_dir)


def add_cf_nh3(scen):
    """Adds ammonia cofiring technologies to
    the coal-fired power plants (CFPPs) in Asian regions.

    All cofiring facilities are assumed to be retrofitting the existing CFPPs.
    The cofiring rate is 10%.
    Only green ammonia (eletr_NH3, biomass_NH3, and gas_NH3_ccs) are used.
    """
    scen.check_out()

    # Create data file list
    folder_path = (
        Path(get_repo_root()) / INPUT_DIR / "scenario" / "2c_buffer" / "cf_nh3"
    )
    data_files = [f for f in os.listdir(folder_path) if f.endswith(".csv")]
    log.info(f"Data files found: {data_files}")

    # Load data files
    dic_data = {}
    for file in data_files:
        file_path = os.path.join(folder_path, file)
        key_name = file.replace(".csv", "")  # Remove .csv extension
        df = pd.read_csv(file_path)
        if "source" in df.columns:
            df = df.drop(columns=["source"])  # Drop "source" if it exists
        dic_data[key_name] = df

    # Add set
    for i in set_list:
        if i in dic_data:
            if i in ["technology", "type_addon", "commodity", "relation", "shares"]:
                i_str = (
                    dic_data[i]
                    .apply(lambda row: row.astype(str).str.cat(sep=", "), axis=1)
                    .tolist()
                )  # str or list of str only
                scen.add_set(i, i_str)
            else:
                scen.add_set(i, dic_data[i])
        else:
            # print(f"Skipping: {i}")
            pass

    # Add par
    for i in par_list:
        if i in dic_data:
            scen.add_par(i, dic_data[i])
            print(f"Added: {i}")
        else:
            # print(f"Skipping: {i}")
            pass

    scen.commit("Cofiring NH3 added.")


def add_cf_biomass(scen):
    """Adds biomass cofiring technologies to
    the coal-fired power plants (CFPPs) in Asian regions.

    All cofiring facilities are assumed to be retrofitting the existing CFPPs.
    The cofiring rate is 10%.
    Only wood waste, rice husks, bagasse, and other vegetal/agricultural waste are considered.
    Landfill gas is not included.
    """
    scen.check_out()

    # Create data file list
    folder_path = (
        Path(get_repo_root()) / INPUT_DIR / "scenario" / "2c_buffer" / "cf_bio"
    )
    data_files = [f for f in os.listdir(folder_path) if f.endswith(".csv")]
    log.info(f"Data files found: {data_files}")

    # Load data files
    dic_data = {}
    for file in data_files:
        file_path = os.path.join(folder_path, file)
        key_name = file.replace(".csv", "")  # Remove .csv extension
        df = pd.read_csv(file_path)
        if "source" in df.columns:
            df = df.drop(columns=["source"])  # Drop "source" if it exists
        dic_data[key_name] = df

    # Add set
    for i in set_list:
        if i in dic_data:
            if i in ["technology", "type_addon", "commodity", "relation", "shares"]:
                i_str = (
                    dic_data[i]
                    .apply(lambda row: row.astype(str).str.cat(sep=", "), axis=1)
                    .tolist()
                )  # str or list of str only
                scen.add_set(i, i_str)
            else:
                scen.add_set(i, dic_data[i])
        else:
            # print(f"Skipping: {i}")
            pass

    # Add par
    for i in par_list:
        if i in dic_data:
            scen.add_par(i, dic_data[i])
            print(f"Added: {i}")
        else:
            # print(f"Skipping: {i}")
            pass

    scen.commit("Cofiring biomass added.")


def add_retro_ccs(scen):
    """Adds settings of xxx."""
    pass


def add_buffer_decoal(scen):
    """Adds ammonia multiple buffer options to
    the coal-fired power plants (CFPPs) in Asian regions.

    - Green ammonia cofiring
    - Biomass cofiring
    - Carbon capture retrofitting
    - No additional constraints to gas uptake
    """
    add_cf_nh3(scen)
    log.info("Scenario settings (cofiring NH3) added.")
    add_cf_biomass(scen)
    log.info("Scenario settings (cofiring biomass) added.")
    # add_retro_ccs(scen)
    # log.info("Scenario settings (retrofitting ccs) added.")


model_ori = "MESSAGEix-GLOBIOM 2.0-M-R12"
scen_ori = "sv_2c"
model_tgt = "MESSAGEix-GLOBIOM 2.0-M-R12"
scen_tgt = "sv_2c_buffer_decoal"

# Load scenario
base = message_ix.Scenario(mp, model=model_ori, scenario=scen_ori)
log.info("Scenario loaded.")

# Clone scenario
scen = base.clone(model_tgt, scen_tgt, keep_solution=False)
scen.set_as_default()
log.info("Scenario cloned.")

# Apply scenario settings
add_buffer_decoal(scen)

# Specify cplex solver options
message_ix.models.DEFAULT_CPLEX_OPTIONS = {
    "advind": 0,
    "lpmethod": 4,
    "threads": 4,
    "epopt": 1e-6,
    "scaind": -1,
    # "predual": 1,
    "barcrossalg": 0,
}

# Specify solver
solver = "MESSAGE"  # solver = "MESSAGE-MACRO"

# Solve scenario
scen.solve(solver)

# Close the connection to the database
log.info("Closing connection to the database.")
mp.close_db()
