"""
intent_handlers.py — One function per chatbot intent, wired to the NLP layer.

Each handler is a zero-argument callable that the NeuralIntents dispatcher
calls when the corresponding intent is recognised.  They interact with the
user via stdin/stdout (matching the tutorial's CLI design) and mutate / query
portfolio state through the portfolio module.

Design notes
------------
* All user-visible prompts are plain print() calls so they appear before the
  input() cursor — no buffering surprises.
* Integer conversion of share counts is validated once here; downstream code
  can safely treat portfolio values as ints.
* MarketDataError is caught locally so a bad ticker doesn't crash the whole
  REPL loop.
"""

from __future__ import annotations

import datetime as dt
import sys

import mplfinance as mpf
import pandas as pd

from market_data import fetch_ohlcv, latest_close, MarketDataError
from portfolio import load_portfolio, save_portfolio

# Shared mutable state: loaded once at startup and kept in memory.
# All handlers reference this module-level variable so changes persist
# across calls within a single session.
portfolio = load_portfolio()


# ---------------------------------------------------------------------------
# Chart
# ---------------------------------------------------------------------------


def plot_chart() -> None:
    """
    Ask the user for a ticker and start date, then render a styled candlestick
    chart with volume using mplfinance.

    The dark 'nightclouds' base theme is overridden with explicit green/red
    candle colours to match the tutorial's preference for conventional
    bull/bear colouring regardless of the underlying theme's defaults.
    """
    ticker = input("Enter ticker symbol (e.g. AAPL): ").strip().upper()
    start_str = input("Enter starting date (DD/MM/YYYY): ").strip()

    try:
        start = dt.datetime.strptime(start_str, "%d/%m/%Y")
    except ValueError:
        print("Invalid date format. Please use DD/MM/YYYY.")
        return

    end = dt.datetime.now()

    try:
        data = fetch_ohlcv(ticker, start, end)
    except MarketDataError as exc:
        print(f"Could not retrieve data: {exc}")
        return

    # Build custom colours: green up-candles, red down-candles.  Wick/edge
    # inherit so they adapt to the night theme without hardcoding hex values.
    mc = mpf.make_marketcolors(
        up="#00ff00",
        down="#ff0000",
        wick="inherit",
        edge="inherit",
        volume="in",
    )
    style = mpf.make_mpf_style(base_mpf_style="nightclouds", marketcolors=mc)

    mpf.plot(
        data,
        type="candle",
        style=style,
        volume=True,
        title=f"{ticker} — {start.strftime('%d %b %Y')} to {end.strftime('%d %b %Y')}",
    )


# ---------------------------------------------------------------------------
# Portfolio CRUD
# ---------------------------------------------------------------------------


def add_portfolio() -> None:
    """
    Prompt for a ticker and share count, then add them to the portfolio.

    If the ticker already exists the share count is incremented rather than
    overwritten — critical for accurate position tracking.
    """
    ticker = input("Which stock do you want to add? (ticker symbol): ").strip().upper()
    amount_str = input("How many shares do you want to add? ").strip()

    try:
        amount = int(amount_str)
    except ValueError:
        print("Please enter a whole number of shares.")
        return

    if amount <= 0:
        print("Share count must be a positive integer.")
        return

    if ticker in portfolio:
        portfolio[ticker] += amount
        print(f"Added {amount} shares. You now hold {portfolio[ticker]} × {ticker}.")
    else:
        portfolio[ticker] = amount
        print(f"Added {ticker} to your portfolio with {amount} shares.")

    save_portfolio(portfolio)


def remove_portfolio() -> None:
    """
    Prompt for a ticker and share count to sell, then reduce the position.

    Refuses to sell more shares than are currently held to prevent negative
    balances.  Removes the ticker entirely when the resulting count reaches 0.
    """
    ticker = input("Which stock do you want to sell? (ticker symbol): ").strip().upper()

    if ticker not in portfolio:
        print(f"You don't own any shares of {ticker}.")
        return

    amount_str = input("How many shares do you want to sell? ").strip()

    try:
        amount = int(amount_str)
    except ValueError:
        print("Please enter a whole number of shares.")
        return

    if amount <= 0:
        print("Share count must be a positive integer.")
        return

    if amount > portfolio[ticker]:
        print(
            f"You only have {portfolio[ticker]} shares of {ticker} — "
            f"cannot sell {amount}."
        )
        return

    portfolio[ticker] -= amount

    if portfolio[ticker] == 0:
        del portfolio[ticker]
        print(f"Sold all shares of {ticker}. Position removed from portfolio.")
    else:
        print(
            f"Sold {amount} shares of {ticker}. "
            f"Remaining: {portfolio[ticker]} shares."
        )

    save_portfolio(portfolio)


def show_portfolio() -> None:
    """Print each position in the portfolio in a human-readable format."""
    if not portfolio:
        print("Your portfolio is empty.")
        return

    print("\nYour portfolio:")
    print("-" * 32)
    for ticker, shares in portfolio.items():
        print(f"  {ticker:<8} {shares:>6} shares")
    print("-" * 32)


# ---------------------------------------------------------------------------
# Portfolio analytics
# ---------------------------------------------------------------------------


def portfolio_worth() -> None:
    """
    Fetch the latest closing price for every holding and sum the total value.

    Tickers that fail to resolve (e.g. delisted) are skipped with a warning
    rather than crashing the whole calculation — a real portfolio may contain
    illiquid or defunct positions.
    """
    if not portfolio:
        print("Your portfolio is empty.")
        return

    print("Calculating portfolio value…")
    total = 0.0
    errors: list[str] = []

    for ticker, shares in portfolio.items():
        try:
            price = latest_close(ticker)
            position_value = price * shares
            total += position_value
            print(f"  {ticker}: {shares} × ${price:,.2f} = ${position_value:,.2f}")
        except MarketDataError as exc:
            errors.append(ticker)
            print(f"  {ticker}: could not retrieve price ({exc})")

    print(f"\nTotal portfolio value: ${total:,.2f} USD")
    if errors:
        print(f"(Skipped due to data errors: {', '.join(errors)})")


def portfolio_gains() -> None:
    """
    Compare the current portfolio value against its value on a historical date.

    Only positions currently in the portfolio are compared — the analysis does
    not account for shares bought or sold between the comparison date and now,
    which matches the tutorial's scope.  If a given day had no trading (e.g.
    it was a weekend or public holiday), pandas raises KeyError on the .loc
    lookup, which we catch and report clearly.
    """
    if not portfolio:
        print("Your portfolio is empty.")
        return

    start_str = input("Enter a comparison date (YYYY-MM-DD): ").strip()

    try:
        comparison_date = dt.datetime.strptime(start_str, "%Y-%m-%d")
    except ValueError:
        print("Invalid date format. Please use YYYY-MM-DD.")
        return

    print(f"Fetching data since {start_str}…")

    sum_now = 0.0
    sum_then = 0.0
    errors: list[str] = []

    for ticker, shares in portfolio.items():
        try:
            data = fetch_ohlcv(ticker, comparison_date)

            price_now = float(data["Close"].iloc[-1])

            # .loc with a timestamp — raises KeyError if that exact date isn't
            # in the index (non-trading day).  We convert the string to a
            # pandas Timestamp to make the lookup unambiguous.
            target_ts = pd.Timestamp(comparison_date)

            # Find the closest available trading day on or after the target date
            available_dates = data.index[data.index >= target_ts]
            if available_dates.empty:
                print(f"  {ticker}: no data available from {start_str}")
                errors.append(ticker)
                continue

            price_then = float(data.loc[available_dates[0], "Close"])

            sum_now += price_now * shares
            sum_then += price_then * shares

        except MarketDataError as exc:
            print(f"  {ticker}: could not retrieve data ({exc})")
            errors.append(ticker)

    if sum_then == 0:
        print("Could not calculate gains — no valid historical data found.")
        return

    absolute_gain = sum_now - sum_then
    relative_gain = ((sum_now - sum_then) / sum_then) * 100

    sign = "+" if absolute_gain >= 0 else ""
    print(f"\nPortfolio comparison vs {start_str}:")
    print(f"  Value then : ${sum_then:,.2f}")
    print(f"  Value now  : ${sum_now:,.2f}")
    print(f"  Absolute   : {sign}${absolute_gain:,.2f} USD")
    print(f"  Relative   : {sign}{relative_gain:.2f}%")

    if errors:
        print(f"(Skipped tickers due to data errors: {', '.join(errors)})")


# ---------------------------------------------------------------------------
# Exit
# ---------------------------------------------------------------------------


def buy() -> None:
    """
    'Buy' in the tutorial doubles as the goodbye / exit intent.

    Named 'buy' to match the intents.json tag used in the transcript.
    """
    print("Goodbye! Happy investing!")
    sys.exit(0)
