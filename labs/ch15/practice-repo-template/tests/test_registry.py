import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from prompt_registry import PromptRegistry  # noqa: E402


class PromptRegistryTest(unittest.TestCase):
    def setUp(self):
        self.registry = PromptRegistry()

    def test_register_returns_increasing_versions(self):
        self.assertEqual(self.registry.register("summary", "Summarize: {text}"), 1)
        self.assertEqual(self.registry.register("summary", "Summarize briefly: {text}"), 2)

    def test_get_returns_latest_by_default(self):
        self.registry.register("summary", "Summarize: {text}")
        self.registry.register("summary", "Summarize briefly: {text}")
        self.assertEqual(self.registry.get("summary"), "Summarize briefly: {text}")
        self.assertEqual(self.registry.get("summary", version=1), "Summarize: {text}")

    def test_unknown_version_is_an_error(self):
        self.registry.register("summary", "Summarize: {text}")
        with self.assertRaises(KeyError):
            self.registry.get("summary", version=3)

    def test_render_fills_values(self):
        self.registry.register("greeting", "Hello, {name}.")
        self.assertEqual(self.registry.render("greeting", name="Asha"), "Hello, Asha.")


if __name__ == "__main__":
    unittest.main()
