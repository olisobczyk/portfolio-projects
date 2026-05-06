"""
main.py — Entry point for the Financial AI Assistant.

Architecture
------------
The assistant is built on the neuralintents library, which wraps a small
Keras/TensorFlow intent-classification model.  intents.json provides the
training corpus; intent_handlers.py maps each recognised intent tag to an
action.  Market data and portfolio persistence live in their own modules so
they can be tested or swapped out independently.

First-run vs. returning-user behaviour
----------------------------------------
* First run  : the model is trained from intents.json and saved to disk.
* Subsequent : --load-model (or the LOAD_MODEL env var) skips training and
  loads the saved weights, making startup ~5–10× faster.

Usage
-----
    python main.py            # train and run
    python main.py --load     # skip training, load saved model
"""

from __future__ import annotations

import argparse
import sys

from neuralintents import GenericAssistant

from intent_handlers import (
    add_portfolio,
    buy,
    plot_chart,
    portfolio_gains,
    portfolio_worth,
    remove_portfolio,
    show_portfolio,
)

# ---------------------------------------------------------------------------
# Intent → handler mapping
# Each key must match a "tag" field in intents.json exactly.
# ---------------------------------------------------------------------------
INTENT_METHODS: dict[str, callable] = {
    "plot_chart": plot_chart,
    "add_portfolio": add_portfolio,
    "remove_portfolio": remove_portfolio,
    "show_portfolio": show_portfolio,
    "portfolio_worth": portfolio_worth,
    "portfolio_gains": portfolio_gains,
    "buy": buy,
}


def build_assistant(load_saved_model: bool = False) -> GenericAssistant:
    """
    Construct and return a trained (or loaded) GenericAssistant.

    Parameters
    ----------
    load_saved_model:
        When True, skip training and restore weights from the previously saved
        model file.  This is faster but requires a prior training run.
    """
    assistant = GenericAssistant(
        "intents.json",
        intent_methods=INTENT_METHODS,
        model_name="financial_assistant_model",
    )

    if load_saved_model:
        try:
            assistant.load_model()
            print("Loaded saved model — skipping training.")
        except Exception as exc:
            print(f"Could not load saved model ({exc}). Training from scratch…")
            assistant.train_model()
            assistant.save_model()
    else:
        print("Training model on intents…")
        assistant.train_model()
        assistant.save_model()
        print("Model trained and saved.")

    return assistant


def run_repl(assistant: GenericAssistant) -> None:
    """
    Run the main read-evaluate-print loop until the user exits.

    The assistant's .request() method returns None when an intent is mapped
    to a handler function (the handler runs as a side-effect); it returns a
    string when the intent has a direct response defined in intents.json.
    We print the string response only when it's non-None so mapped intents
    don't produce a spurious 'None' output line.
    """
    print("\nFinancial Assistant ready.  Type your message below (Ctrl-C to quit).\n")

    while True:
        try:
            message = input("You: ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\nGoodbye!")
            sys.exit(0)

        if not message:
            continue

        response = assistant.request(message)
        if response:
            print(f"Assistant: {response}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Financial AI Assistant powered by NeuralIntents"
    )
    parser.add_argument(
        "--load",
        action="store_true",
        help="Load a previously saved model instead of retraining",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    assistant = build_assistant(load_saved_model=args.load)
    run_repl(assistant)
