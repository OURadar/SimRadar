UNAME := $(shell uname)

CFLAGS = -std=gnu99 -Wall -Wno-unknown-pragmas -Os -msse2 -mavx -I /usr/local/include

LDFLAGS = -L lib -L /usr/local/lib -lrs

OBJS = rs.o les.o adm.o rcs.o obj.o

MYLIB = lib/librs.a

PROGS = cldemo test_clreduce test_make_pulse test_rs test_les test_adm test_rcs simple_ppi lsiq

MPI_PROGS = radarsim

ifeq ($(UNAME), Darwin)
CC = clang
CFLAGS += -D_DARWIN_C_SOURCE
LDFLAGS += -framework OpenCL
else
# These options are for Linux systems, boomer at OSCER included
CC = gcc
CFLAGS += -D_GNU_SOURCE
#CFLAGS += -I /usr/local/cuda/include
#LDFLAGS += -L /usr/local/cuda/lib64 -lOpenCL
#CFLAGS += -I /opt/oscer/software/CUDA/7.5.18-GCC-4.9.3-2.25/include
#LDFLAGS += -L /opt/oscer/software/CUDA/7.5.18-GCC-4.9.3-2.25/lib64 -L /opt/oscer/software/OpenCL/2.2-GCC-4.9.3-2.25/lib64 -lOpenCL
CFLAGS += -I /opt/oscer/software/CUDA/8.0.44-GCC-4.9.3-2.25/include -I /opt/oscer/software/OpenMPI/1.10.2-GCC-4.9.3-2.25/include
LDFLAGS += -L /opt/oscer/software/CUDA/8.0.44-GCC-4.9.3-2.25/lib64 -L /opt/oscer/software/OpenCL/2.2-GCC-4.9.3-2.25/lib64 -lOpenCL
endif

LDFLAGS += -lm -lpthread

all: $(MYLIB) $(PROGS) $(MPI_PROGS)

$(OBJS): %.o: %.c %.h rs_types.h
	$(CC) $(CFLAGS) -c $< -o $@

$(PROGS): %: %.c $(MYLIB)
	$(CC) $(CFLAGS) -o $@ $@.c $(LDFLAGS)

lib/librs.a: $(OBJS)
	mkdir -p lib
	ar rvcs $@ $(OBJS)

$(MPI_PROGS): %: %.c $(MYLIB)
ifdef OPEN_MPI_CLUSTER
#	mpicc $(CFLAGS) -D_OPEN_MPI -o $@ $@.c $(LDFLAGS)
	$(CC) $(CFLAGS) -I /opt/oscer/software/OpenMPI/1.10.2-GCC-4.9.3-2.25/include -o $@ $@.c $(LDFLAGS) -L /opt/oscer/software/OpenMPI/1.10.2-GCC-4.9.3-2.25/lib -lmpi
else
	$(CC) $(CFLAGS) -o $@ $@.c $(LDFLAGS)
endif

clean:
	rm -f *.o *.a
	rm -f $(MYLIB) $(PROGS) $(MPI_PROGS)
	rm -rf *.dSYM
