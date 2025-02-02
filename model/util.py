import logging
import sys
from pathlib import Path

# Directory containing gst_bespoke_scenarios.__init__
ROOT_PATH = Path(__file__).parents[1]


# Define logger
def get_logger(name: str):
    log = logging.getLogger(name)
    log.setLevel(logging.INFO)

    # Configure the handler and formatter as needed
    handler = logging.StreamHandler(sys.stdout)
    formatter = logging.Formatter("%(name)s %(asctime)s %(levelname)s %(message)s")

    # Add formatter to the handler
    handler.setFormatter(formatter)

    # Add handler to the logger
    log.addHandler(handler)

    return log
