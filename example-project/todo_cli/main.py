import json
from pathlib import Path
from typing import List

DATA_FILE = Path("todos.json")

class Todo:
    def __init__(self, id: int, task: str, done: bool = False, priority: str = "medium"):
        self.id = id
        self.task = task
        self.done = done
        self.priority = priority

    def to_dict(self):
        return vars(self)

def load_todos() -> List[Todo]:
    if not DATA_FILE.exists():
        return []
    with open(DATA_FILE) as f:
        return [Todo(**item) for item in json.load(f)]

def save_todos(todos: List[Todo]):
    with open(DATA_FILE, "w") as f:
        json.dump([t.to_dict() for t in todos], f, indent=2)

if __name__ == "__main__":
    print("✅ Todo CLI ready (powered by agent-team-dev-workflow)")
