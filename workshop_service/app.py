import logging

from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

import workshop_service.scenario
import workshop_service.showcase

app = FastAPI()
Instrumentator().instrument(app).expose(app)
logging.basicConfig(level=logging.INFO)

app.include_router(workshop_service.showcase.router)
app.include_router(workshop_service.scenario.router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
