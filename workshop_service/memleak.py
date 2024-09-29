import os
import time
from datetime import timedelta
from threading import Thread, Event

from workshop_service.scenario import Scenario
from workshop_service.utils import parse_size

DEFAULT_CHUNK_SIZE = parse_size(os.environ.get("SCENARIO_MEMLEAK_CHUNK_SIZE", "4mb"))

class MemoryLeak(Scenario):
    @classmethod
    def display_name(cls) -> str:
        return "memleak"

    chunk_size: int
    interval: timedelta
    _stop_signal: Event
    _chunks = []

    def __init__(
        self,
        chunk_size=4 * 1024 * 1024,
        interval=timedelta(seconds=1),
    ):
        super().__init__(name="leak-generator", daemon=True)
        self.chunk_size = chunk_size
        self.interval = interval
        self._stop_signal = Event()

    def run(self):
        while not self._stop_signal.is_set():
            self._chunks.append([0] * self.chunk_size)
            time.sleep(self.interval.total_seconds())
        self._stop_signal.clear()
        self._chunks.clear()

    def stop(self, timeout: float | None = None):
        self._stop_signal.set()
        self.join(timeout)
