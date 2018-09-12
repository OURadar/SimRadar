# Check for OS - Linux or Darwin (macOS)
UNAME := $(shell uname)

# Check for availability of MPI
MPIVER := $(shell [ ! -z ${EBVERSIONOPENMPI} ] && echo true || echo false)

CFLAGS = -std=gnu99 -Wall -Wno-unknown-pragmas -Os -msse2 -mavx -I /usr/local/include

LDFLAGS = -L lib -L /usr/local/lib -lrs

OBJS = rs.o les.o adm.o rcs.o obj.o pos.o

MYLIB = lib/librs.a

PROGS = cldemo test_clreduce test_make_pulse test_rs test_les test_adm test_rcs simple_ppi lsiq radarsim

MPI_PROGS =

ifeq ($(UNAME), Darwin)
    # macOS
    CC = clang
    CFLAGS += -D_DARWIN_C_SOURCE
    LDFLAGS += -framework OpenCL
else
    # Linux systems, mainly schooner of OSCER
    CC = gcc
    CFLAGS += -D_GNU_SOURCE
    CFLAGS += -I /opt/oscer/software/CUDA/8.0.44-GCC-4.9.3-2.25/include
    CFLAGS += -I /opt/oscer/software/OpenMPI/1.10.2-GCC-4.9.3-2.25/include
    LDFLAGS += -L /opt/oscer/software/CUDA/8.0.44-GCC-4.9.3-2.25/lib64 -lOpenCL
    ifeq ($(MPIVER), true)
        # Cluster with OpenMPI support
        MPI_PROGS += radarsim-mpi
        MPI_CFLAGS = -I /opt/oscer/software/OpenMPI/1.10.2-GCC-4.9.3-2.25/include
        MPI_LDFLAGS = -L /opt/oscer/software/OpenMPI/1.10.2-GCC-4.9.3-2.25/lib -lmpi
    endif
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
	$(CC) $(CFLAGS) -D_OPEN_MPI $(MPI_CFLAGS) -o $@ $@.c $(LDFLAGS) $(MPI_LDFLAGS)

prep: radarsim-mpi.c
	@ln -sfn radarsim.c radarsim-mpi.c

clean:
	rm -f *.o *.a
	rm -f $(MYLIB) $(PROGS) $(MPI_PROGS)
	rm -rf *.dSYM
