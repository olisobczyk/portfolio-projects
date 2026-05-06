"""
portfolio.py — Persistent portfolio storage using pickle serialisation.

The portfolio is a simple {ticker: share_count} dict.  Using pickle rather
than JSON lets us swap the value type to a richer object later (e.g. including
cost-basis) without a migration step.  The file is only a few hundred bytes,
so the re-serialise-on-every-write approach is acceptable here.
"""

import pickle
from pathlib import Path
from typing import Dict

PORTFOLIO_FILE = Path("portfolio.pkl")

Portfolio = Dict[str, int]


def _default_portfolio() -> Portfolio:
    """Seed portfolio used only when no saved file exists yet."""
    return {
        "AAPL": 20,
        "TSLA": 5,
        "GS": 10,
    }


def load_portfolio() -> Portfolio:
    """
    Load the portfolio from disk, creating a default one on first run.

    Returns the in-memory dict that the rest of the application mutates.
    """
    if not PORTFOLIO_FILE.exists():
        portfolio = _default_portfolio()
        save_portfolio(portfolio)
        return portfolio

    with PORTFOLIO_FILE.open("rb") as f:
        return pickle.load(f)


def save_portfolio(portfolio: Portfolio) -> None:
    """Persist the current portfolio state to disk."""
    with PORTFOLIO_FILE.open("wb") as f:
        pickle.dump(portfolio, f)
