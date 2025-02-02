import os
import sys
import message_ix
import ixmp

mp = ixmp.Platform()
import time
import numpy as np
import pandas as pd

from model.util import get_logger
from model.report import report

log = get_logger(__name__)

# Load the scenario
tar_model = "MESSAGEix-GLOBIOM 2.0-M-R12"
tar_scen = "sv_2c_cf"
scen = message_ix.Scenario(mp, tar_model, tar_scen)
log.info("Scenario loaded.")

# Report the scenario
report(scen)
log.info("Reporting completed.")
