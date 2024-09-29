from fastapi import FastAPI, HTTPException
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from workshop_service.memleak import MemoryLeak
from workshop_service.scenario import Scenario

__scenarios = {
    scenario.display_name(): scenario
    for scenario in [MemoryLeak]
}
__current_scenario: Scenario | None = None


app = FastAPI()
FastAPIInstrumentor.instrument_app(app)


@app.get("/health")
def health() -> dict:
    # global __current_scenario

    return {
        "status": "ok",
        "scenarios": {
            alias: "running" if __current_scenario and __current_scenario.is_alive() and __current_scenario.display_name() == alias else "stopped"
            for alias, scenario in __scenarios.items()
        }
    }


@app.get("/scenario/{alias}")
def scenario_status(alias: str) -> dict:
    global __current_scenario

    requested = __scenarios.get(alias)
    if not requested:
        raise HTTPException(status_code=400, detail=f"Unknown scenario '{alias}'")
    if __current_scenario and __current_scenario.is_alive() and type(__current_scenario) == requested:
        return {"scenario": alias, "status": "running"}
    else:
        return {"scenario": alias, "status": "stopped"}


@app.post("/scenario/{alias}")
def scenario_action(alias: str, action: str) -> dict:
    global __current_scenario

    requested = __scenarios.get(alias)
    if not requested:
        raise HTTPException(status_code=400, detail=f"Unknown scenario '{alias}'")
    if not action:
        raise HTTPException(status_code=400, detail="Missing query parameter 'action'")

    if action == "start":
        if __current_scenario:
            if __current_scenario.is_alive():
                if type(__current_scenario) != requested:
                    raise HTTPException(
                        status_code=409,
                        detail=f"Scenario '{__current_scenario.display_name()}' is in progress",
                    )
                else:
                    raise HTTPException(status_code=304)

        __current_scenario = requested()
        __current_scenario.start()
        return {"scenario": alias, "status": "running"}

    elif action == "stop":
        if not __current_scenario or not __current_scenario.is_alive() or type(__current_scenario) != requested:
            raise HTTPException(status_code=304)
        __current_scenario.stop()
        return {"scenario": alias, "status": "stopped"}

    else:
        raise HTTPException(status_code=400, detail=f"Unknown action '{action}'")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
