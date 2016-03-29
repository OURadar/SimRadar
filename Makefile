UNAME := $(shell uname)

CFLAGS = -std=gnu99 -Wall -Wno-unknown-pragmas -Os -msse2 -mavx -I /usr/local/include
LDFLAGS = -L lib -L /usr/local/lib -lrs

OBJS = rs.o les.o adm.o rcs.o

MYLIB = lib/librs.a

PROGS = cldemo radarsim test_clreduce test_make_pulse test_rs test_les test_adm test_rcs simple_ppi lsiq

ifeq ($(UNAME), Darwin)
CC = clang
CFLAGS += -D_DARWIN_C_SOURCE
LDFLAGS += -framework OpenCL
else
CC = gcc
# This option is actually special for Linux (OSCER's boomer included)
PROGS += radarsim_omp
CFLAGS += -D_GNU_SOURCE
CFLAGS += -I /usr/local/cuda/include
LDFLAGS += -L /usr/local/cuda/lib64 -lOpenCL
endif

LDFLAGS += -lm -lpthread

all: $(MYLIB) $(PROGS)

$(OBJS): %.o: %.c %.h rs_types.h
	$(CC) $(CFLAGS) -c $< -o $@

$(PROGS): %: %.c $(MYLIB)
	$(CC) $(CFLAGS) -o $@ $@.c $(LDFLAGS)

lib/librs.a: $(OBJS)
	mkdir -p lib
	ar rvcs $@ $(OBJS)

radarsim_omp:
	mpicc $(CFLAGS) -D_OPEN_MPI -o $@ radarsim.c $(LDFLAGS)

clean:
	rm -f *.o *.a
	rm -f $(MYLIB) $(PROGS)
	rm -rf *.dSYM

