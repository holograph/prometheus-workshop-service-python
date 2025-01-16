import os
import time
from datetime import timedelta
from threading import Event

from workshop_service.scenario import Scenario
from workshop_service.utils import parse_size

DEFAULT_CHUNK_SIZE = parse_size(os.environ.get("SCENARIO_MEMLEAK_CHUNK_SIZE", "1mb"))
DEFAULT_MAX_CHUNKS = int(os.environ.get("SCENARIO_MEMLEAK_MAX_CHUNKS", "600"))
DEFAULT_INTERVAL = timedelta(seconds=1)


class MemoryLeak(Scenario):
    @classmethod
    def display_name(cls) -> str:
        return "scenario1"

    chunk_size: int
    interval: timedelta
    _stop_signal: Event
    _chunks = []

    def __init__(
        self,
        chunk_size=DEFAULT_CHUNK_SIZE,
        max_chunks=DEFAULT_MAX_CHUNKS,
        interval=DEFAULT_INTERVAL,
    ):
        super().__init__(name=self.display_name(), daemon=True)
        self.chunk_size = chunk_size
        self.max_chunks = max_chunks
        self.interval = interval
        self._stop_signal = Event()

    def run(self):
        while not self._stop_signal.is_set():
            if len(self._chunks) < self.max_chunks:
                self._chunks.append([0] * self.chunk_size)
            time.sleep(self.interval.total_seconds())
        self._stop_signal.clear()
        self._chunks.clear()

    def stop(self, timeout: float | None = None):
        self._stop_signal.set()
        self.join(timeout)
