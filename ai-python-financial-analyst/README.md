# Financial AI Assistant

A conversational command-line assistant for managing a stock portfolio and visualising market data. Built with [NeuralIntents](https://github.com/neuralNine/neuralintents) for intent classification and `mplfinance` / `pandas-datareader` for financial data.

---

## What it does

| Intent | What you can say | What happens |
|---|---|---|
| **Greetings** | "hello", "hey", "hi" | Friendly greeting back |
| **Plot chart** | "plot a stock", "show me a candlestick chart" | Prompts for ticker + start date, renders styled candlestick chart with volume |
| **Add to portfolio** | "add a stock to my portfolio", "I bought some shares" | Prompts for ticker + share count, updates persisted portfolio |
| **Sell from portfolio** | "sell a stock", "remove a position" | Prompts for ticker + share count, validates you own enough |
| **Show portfolio** | "show my portfolio", "what do I own" | Lists all current holdings |
| **Portfolio worth** | "how much is my portfolio worth" | Fetches live prices and sums total value |
| **Portfolio gains** | "how is my portfolio performing" | Compares current value to a historical date |
| **Quit** | "bye", "goodbye", "exit" | Exits the assistant |

---

## Prerequisites

- Python **3.9–3.11** (NeuralIntents has TensorFlow as an indirect dependency; TF 2.x requires Python ≤ 3.11 on most platforms)
- `pip`
- An internet connection (for Yahoo Finance data)

---

## Installation

```bash
# 1. Clone or copy the project folder
cd financial_assistant

# 2. Create and activate a virtual environment (recommended)
python -m venv .venv
source .venv/bin/activate      # macOS / Linux
.venv\Scripts\activate         # Windows

# 3. Install dependencies
pip install -r requirements.txt
```

> **TensorFlow note**: NeuralIntents pulls in TensorFlow. If you're on Apple Silicon, install `tensorflow-macos` and `tensorflow-metal` instead of plain `tensorflow` before running pip install.

---

## Configuration

The project has no required configuration — Yahoo Finance data is free and key-less.

If you want to customise anything, copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

---

## Usage

### First run (trains the model)

```bash
python main.py
```

Training typically completes in under 30 seconds. The trained weights are saved as `financial_assistant_model.*` files in the project directory.

### Subsequent runs (skip training)

```bash
python main.py --load
```

This loads the saved model, making startup ~5–10× faster.

### Example session

```
Training model on intents…
Model trained and saved.

Financial Assistant ready. Type your message below (Ctrl-C to quit).

You: hello
Assistant: Hey! How can I help you with your finances today?

You: show my portfolio
Your portfolio:
--------------------------------
  AAPL        20 shares
  TSLA         5 shares
  GS          10 shares
--------------------------------

You: plot a stock
Enter ticker symbol (e.g. AAPL): MSFT
Enter starting date (DD/MM/YYYY): 01/01/2023
[candlestick chart opens in a window]

You: how much is my portfolio worth
Calculating portfolio value…
  AAPL: 20 × $189.30 = $3,786.00
  TSLA: 5 × $248.50 = $1,242.50
  GS: 10 × $412.00 = $4,120.00

Total portfolio value: $9,148.50 USD

You: goodbye
Goodbye! Happy investing!
```

---

## Project structure

```
financial_assistant/
├── main.py              # Entry point — REPL loop and assistant setup
├── intent_handlers.py   # One function per chatbot intent
├── market_data.py       # Yahoo Finance data fetching with yfinance fallback
├── portfolio.py         # Pickle-based portfolio persistence
├── intents.json         # NLP training data (tags, patterns, responses)
├── requirements.txt
├── .env.example
└── README.md
```

---

## Extending the assistant

### Adding a new intent

1. Add a new object to the `intents` array in `intents.json`:

```json
{
  "tag": "company_news",
  "patterns": [
    "get me the latest news for a stock",
    "show company news",
    "any news about a stock?"
  ],
  "responses": []
}
```

2. Write a handler function in `intent_handlers.py`:

```python
def company_news() -> None:
    ticker = input("Which company? (ticker symbol): ").strip().upper()
    # ... your logic here
```

3. Register it in `INTENT_METHODS` in `main.py`:

```python
INTENT_METHODS = {
    ...
    "company_news": company_news,
}
```

4. Delete the saved model files and retrain:

```bash
rm financial_assistant_model.*
python main.py
```

---

## Known limitations

- **Portfolio gains** compares the *current* set of holdings to a past date. It does not account for positions opened or closed between then and now.
- **Yahoo Finance** is an undocumented API; `pandas-datareader`'s backend occasionally breaks when Yahoo changes their endpoints. The `yfinance` fallback handles most such outages automatically.
- NeuralIntents requires a minimum number of training patterns per intent to classify reliably. If you add a new intent, provide at least 6–8 varied pattern phrases.

---

## Credits

Based on the tutorial *"Build an Intelligent Financial Assistant in Python"* by Florian (NeuralNine). The NeuralIntents library is available at [github.com/neuralNine/neuralintents](https://github.com/neuralNine/neuralintents).
