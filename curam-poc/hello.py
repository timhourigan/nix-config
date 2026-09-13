#!/usr/bin/env python3
"""Greeting script that uses argparse."""

import argparse


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Print a greeting with an optional name."
    )
    parser.add_argument(
        "--name", "-n",
        type=str,
        default=None,
        help="The name to greet. If omitted, greets 'World'."
    )
    args = parser.parse_args()

    name = args.name if args.name else "World"
    print(f"Hello {name}.")


if __name__ == "__main__":
    main()