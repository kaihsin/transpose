
CUDAC = nvcc
GENCODE_FLAGS = -gencode arch=compute_70,code=sm_70

CFLAGS = -std=c++11

CUTT_FLAGS = -I${CUTT_ROOT}/include -L${CUTT_ROOT}/lib -lcutt
CUTENSOR_FLAGS = -I${CUTENSOR_ROOT}/include -L${CUTENSOR_ROOT}/lib/10.1/ -lcutensor

CUDA_FLAGS = 

all: cutt cutensor

cutt: cutt.cu
	$(CUDAC) $(CUDA_FLAGS) $(CFLAGS) $(CUTT_FLAGS) -o $@ $<

cutensor: cutensor.cu
	$(CUDAC) $(CUDA_FLAGS) $(CFLAGS) $(CUTENSOR_FLAGS) -o $@ $<

clean:
	rm -f cutt cutensor *.out *.err
