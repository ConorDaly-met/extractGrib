# Convert the ENSMSEL variable to a list
import sys

if sys.argv[1] == "":
    # Deterministic mode
    exit(0)
    
ENSMSEL = sys.argv[1]

def ensmsel_to_list(ENSMSEL):
    ensmsel = sum(((list(range(*[int(b) + c
        for c, b in enumerate(a.split('-'))]))
        if '-' in a else [int(a)]) for a in ENSMSEL.split(',')), [])
    # Pad this list to 3 digits
    ensmbrs = [str(mbr).zfill(3) for mbr in ensmsel]
    print(ensmbrs)
    return ensmbrs

ensmsel_to_list(ENSMSEL)
