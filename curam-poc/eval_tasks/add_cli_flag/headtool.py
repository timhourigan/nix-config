import sys


def run(argv):
    for line in sys.stdin:
        print(line, end="")


run(sys.argv)
