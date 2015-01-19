UNAME := $(shell uname)

CFLAGS = -std=gnu99 -Wall -Wno-unknown-pragmas -Os -msse -msse2 -mavx
LDFLAGS = -L lib -lrs

OBJS = rs.o les.o adm.o

MYLIB = lib/librs.a

PROGS = cldemo radarsim test_clreduce test_make_pulse test_rs test_les test_adm

ifeq ($(UNAME), Darwin)
CC = clang
CFLAGS += -D_DARWIN_C_SOURCE
LDFLAGS += -framework OpenCL
else
CC = gcc
# This option is actually special for OSCER's boomer
CFLAGS += -I /opt/local/software/Cuda/4.2.9/include
LDFLAGS += -L /usr/lib64/nvidia -lOpenCL
endif

LDFLAGS += -lm -lpthread

all: $(MYLIB) $(PROGS)

$(OBJS): %.o: %.c %.h rs_types.h
	$(CC) $(CFLAGS) -c $< -o $@

$(PROGS): %: %.c $(MYLIB)
	$(CC) $(CFLAGS) -o $@ $@.c $(LDFLAGS)

lib/librs.a: $(OBJS)
	ar rvcs $@ $(OBJS)


clean:
	rm -f *.o *.a
	rm -f $(MYLIB) $(PROGS)
	rm -rf *.dSYM

