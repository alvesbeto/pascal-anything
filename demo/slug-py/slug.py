"""Minimal slug helper used as a pascal-anything demo source."""

import re


def slugify(text: str) -> str:
    text = text.strip().lower()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return text.strip("-")


if __name__ == "__main__":
    import sys

    print(slugify(" ".join(sys.argv[1:]) if len(sys.argv) > 1 else "Hello, Pascal!"))
