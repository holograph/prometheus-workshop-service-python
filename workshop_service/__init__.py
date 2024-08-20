from fastapi import FastAPI, Response
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from workshop_service.memleak import MemoryLeak

app = FastAPI()
FastAPIInstrumentor.instrument_app(app)

__memleak: MemoryLeak


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/scenario/memleak")
def scenario_memleak(action: str):
    global __memleak

    if action == "start":
        if __memleak and __memleak.isAlive():
            return Response(status_code=304)
        __memleak = MemoryLeak()
        __memleak.start()
    elif action == "stop":
        if not (__memleak and __memleak.isAlive()):
            return Response(status_code=304)
        __memleak.stop()
