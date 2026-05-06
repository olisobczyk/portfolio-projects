"""
market_data.py — Thin wrapper around pandas-datareader / yfinance for price retrieval.

pandas-datareader's Yahoo Finance backend has historically been fragile (Yahoo
frequently breaks the undocumented API it depends on).  We therefore add a
yfinance fallback: if datareader raises, we retry with yfinance, which
maintains its own actively-updated scraping layer.

All public functions raise MarketDataError on unrecoverable failures so callers
don't have to inspect raw library exceptions.
"""

from __future__ import annotations

import datetime as dt
from typing import Optional

import pandas as pd


class MarketDataError(Exception):
    """Raised when price data cannot be retrieved for any ticker."""


def _fetch_via_datareader(
    ticker: str,
    start: dt.datetime,
    end: dt.datetime,
) -> pd.DataFrame:
    """Primary fetch path using pandas-datareader."""
    import pandas_datareader as web  # deferred so missing install gives a clear message

    return web.DataReader(ticker, "yahoo", start, end)


def _fetch_via_yfinance(
    ticker: str,
    start: dt.datetime,
    end: dt.datetime,
) -> pd.DataFrame:
    """
    Fallback fetch path using yfinance.

    yfinance returns lowercase column names ('close', 'open', …); we normalise
    to title-case to stay consistent with pandas-datareader's output schema.
    """
    import yfinance as yf  # deferred — optional dependency

    df = yf.download(ticker, start=start, end=end, progress=False)
    if df.empty:
        raise MarketDataError(f"yfinance returned no data for '{ticker}'")
    # Normalise column names: 'close' → 'Close', etc.
    df.columns = [c.title() for c in df.columns]
    return df


def fetch_ohlcv(
    ticker: str,
    start: dt.datetime,
    end: Optional[dt.datetime] = None,
) -> pd.DataFrame:
    """
    Fetch OHLCV data for *ticker* between *start* and *end* (defaults to now).

    Returns a DataFrame with at minimum a 'Close' column indexed by date.
    Raises MarketDataError if both data sources fail.
    """
    if end is None:
        end = dt.datetime.now()

    try:
        df = _fetch_via_datareader(ticker, start, end)
    except Exception as primary_err:
        try:
            df = _fetch_via_yfinance(ticker, start, end)
        except Exception as fallback_err:
            raise MarketDataError(
                f"Could not fetch data for '{ticker}'. "
                f"Primary: {primary_err}. Fallback: {fallback_err}"
            ) from fallback_err

    if df.empty:
        raise MarketDataError(
            f"No trading data found for '{ticker}' in the requested date range."
        )
    return df


def latest_close(ticker: str) -> float:
    """
    Return the most recent closing price for *ticker*.

    Fetches the last 5 trading days to guard against weekends / holidays
    where today would return an empty frame.
    """
    end = dt.datetime.now()
    start = end - dt.timedelta(days=7)
    df = fetch_ohlcv(ticker, start, end)
    return float(df["Close"].iloc[-1])
