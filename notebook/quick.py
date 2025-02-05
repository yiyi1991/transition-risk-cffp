import message_ix
import ixmp

mp = ixmp.Platform()

from model.util import get_logger
from model.report import report

log = get_logger(__name__)

# Load the scenario
tar_model = "MESSAGEix-GLOBIOM 2.0-M-R12"
tar_scen = "sv_2c_buffer_decoal"
scen = message_ix.Scenario(mp, tar_model, tar_scen)
log.info("Scenario loaded.")

# Report the scenario
report(scen)
log.info("Reporting completed.")
