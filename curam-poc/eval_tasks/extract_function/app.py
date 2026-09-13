def price(items):
    total = 0
    for i in items:
        total += i * 1.2  # tax
    return total
