import os
import tempfile
import time
import random
from datetime import timedelta
from pathlib import Path
from threading import Event
from uuid import uuid4

from workshop_service.scenario import Scenario
from workshop_service.utils import parse_size

DEFAULT_CHUNK_SIZE = parse_size(os.environ.get("SCENARIO_DISKSPACE_CHUNK_SIZE", "4mb"))
DEFAULT_INTERVAL = timedelta(seconds=1)
DEFAULT_TARGET_PATH = os.environ.get("SCENARIO_DISKSPACE_TARGET_PATH", tempfile.gettempdir())


class DiskSpace(Scenario):
    chunk_size: int
    interval: timedelta
    target_path: Path
    _stop_signal: Event

    def __init__(
            self,
            chunk_size=DEFAULT_CHUNK_SIZE,
            interval=DEFAULT_INTERVAL,
            target_path=DEFAULT_TARGET_PATH,
    ):
        super().__init__(name=self.display_name(), daemon=True)
        self.chunk_size = chunk_size
        self.interval = interval
        self.target_path = Path(target_path)
        self._stop_signal = Event()

    def run(self):
        while not self._stop_signal.is_set():
            chunk = self.target_path / str(uuid4())
            with (f := chunk.open(mode='wb')):
                f.write(random.randbytes(self.chunk_size))
            time.sleep(self.interval.total_seconds())
        self._stop_signal.clear()

    def stop(self, timeout: float | None = None):
        self._stop_signal.set()
        self.join(timeout)


    @classmethod
    def display_name(cls):
        return "diskspace"
