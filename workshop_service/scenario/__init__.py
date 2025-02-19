import enum
import logging
import random
import time

from fastapi import APIRouter
from fastapi import HTTPException

from .scenario import Scenario
from .diskspace import DiskSpace
from .memleak import MemoryLeak
from .ratelimit import RateLimit


router = APIRouter(prefix="/scenario")

__scenarios = {
    scenario.display_name(): scenario
    for scenario in [MemoryLeak, DiskSpace, RateLimit]
}
__current_scenario: Scenario | None = None


@router.get("/health")
def health() -> dict:
    return {
        "status": "ok",
        "scenarios": {
            alias: "running" if __current_scenario and __current_scenario.is_alive() and __current_scenario.display_name() == alias else "stopped"
            for alias, scenario in __scenarios.items()
        }
    }

request_count_from = 0
request_count = 0

# TODO relocate to ratelimit scenario
@router.get("/do_something", include_in_schema=False)
def sample_endpoint() -> dict:
    # "Rate limit"
    global request_count, request_count_from
    if request_count_from <= time.time() - 60:
        request_count_from = time.time()
        request_count = 1
    elif request_count >= 10:
        raise HTTPException(status_code=429)
    else:
        request_count += 1

    seconds = float(random.randrange(100, 1000)) / 1000.0
    time.sleep(seconds)
    return {"status": "ok"}

@router.get("/{alias}")
def scenario_status(alias: str) -> dict:
    global __current_scenario

    requested = __scenarios.get(alias)
    if not requested:
        raise HTTPException(status_code=400, detail=f"Unknown scenario '{alias}'")
    if __current_scenario and __current_scenario.is_alive() and isinstance(__current_scenario, requested):
        return {"scenario": alias, "status": "running"}
    else:
        return {"scenario": alias, "status": "stopped"}

class Action(enum.Enum):
    START = "start"
    STOP = "stop"

@router.post("/{alias}")
def scenario_action(alias: str, action: Action) -> dict:
    global __current_scenario

    requested = __scenarios.get(alias)
    if not requested:
        raise HTTPException(status_code=400, detail=f"Unknown scenario '{alias}'")
    if not action:
        raise HTTPException(status_code=400, detail="Missing query parameter 'action'")

    if action == Action.START:
        if __current_scenario:
            if __current_scenario.is_alive():
                if not isinstance(__current_scenario, requested):
                    raise HTTPException(
                        status_code=409,
                        detail=f"Scenario '{__current_scenario.display_name()}' is in progress",
                    )
                else:
                    raise HTTPException(status_code=304)

        logging.info(f"Starting scenario {alias}")
        __current_scenario = requested()
        __current_scenario.start()
        return {"scenario": alias, "status": "running"}

    elif action == Action.STOP:
        if not __current_scenario or not __current_scenario.is_alive() or not isinstance(__current_scenario, requested):
            raise HTTPException(status_code=304)
        logging.info(f"Stopping scenario {alias}")
        __current_scenario.stop()
        return {"scenario": alias, "status": "stopped"}

    else:
        raise HTTPException(status_code=400, detail=f"Unknown action '{action}'")
