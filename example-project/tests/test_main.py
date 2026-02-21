import pytest
from todo_cli.main import Todo, load_todos, save_todos

def test_todo_serialization(tmp_path):
    # Simple test – workflow will expand this
    todo = Todo(1, "Buy milk", priority="high")
    assert todo.to_dict()["priority"] == "high"
