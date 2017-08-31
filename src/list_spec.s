# list_spec.s

# List node header definition
# The sentinels only has `prev` and `next` items
# Items offset:
.equ ND_PREV, 0
.equ ND_NEXT, 4
.equ ND_LEVEL, 8
# Metadata:
.equ ND_SENTINEL_SZ, 8
.equ ND_HEADER_SZ, 12

