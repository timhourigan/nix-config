import pathlib

for p in pathlib.Path("data/raw").glob("*"):
    print(f"processing {p.name}")
