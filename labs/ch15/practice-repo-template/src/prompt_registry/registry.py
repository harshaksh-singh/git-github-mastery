"""An in-memory registry that keeps every version of each prompt template."""


class PromptRegistry:
    def __init__(self):
        self._versions = {}

    def register(self, name, template):
        """Store a new version of the template and return its version number."""
        if not name:
            raise ValueError("a prompt needs a name")
        versions = self._versions.setdefault(name, [])
        versions.append(template)
        return len(versions)

    def get(self, name, version=None):
        """Return the given version of a template, or the latest one."""
        versions = self._versions[name]
        if version is None:
            return versions[-1]
        if not 1 <= version <= len(versions):
            raise KeyError(f"{name} has no version {version}")
        return versions[version - 1]

    def render(self, prompt_name, /, **values):
        """Fill the latest version of a template with values."""
        return self.get(prompt_name).format(**values)
