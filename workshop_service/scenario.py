from abc import abstractmethod, abstractproperty, ABC, abstractclassmethod
from threading import Thread


class Scenario(Thread, ABC):
    @classmethod
    @abstractmethod
    def display_name(cls):
        ...

    @abstractmethod
    def stop(self, timeout: float | None = None):
        ...

