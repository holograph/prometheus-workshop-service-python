import logging
from datetime import timedelta
from threading import Event
import requests

from workshop_service.scenario import Scenario

class RateLimit(Scenario):
    rate_limit: int
    interval: timedelta
    _stop_signal: Event

    def __init__(self):
        super().__init__(name=self.display_name(), daemon=True)
        self._stop_signal = Event()

    def run(self):
        while not self._stop_signal.is_set():
            response = requests.get("http://localhost:8080/do_something")
            if response.status_code != 200:
                logging.warning(f"Got status code {response.status_code}!")
        self._stop_signal.clear()

    def stop(self, timeout: float | None = None):
        self._stop_signal.set()
        self.join(timeout)


    @classmethod
    def display_name(cls):
        return "scenario3"
