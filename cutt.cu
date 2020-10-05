#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cutt.h>
#include <random>
#include <complex>

typedef float floatType;

#define CudaSafeCall(err) __cudaSafeCall( err, __FILE__, __LINE__ )
void __cudaSafeCall(cudaError err, const char *file, const int line);

void __cudaSafeCall(cudaError err, const char *file, const int line) {
  if (cudaSuccess != err) {
    fprintf(stderr, "cudaSafeCall() failed at %s:%i : %s\n", file, line,
            cudaGetErrorString(err));
    exit(-1);
  }
}

void cuttCheck(cuttResult err) {
  if (CUTT_SUCCESS != err) {
    fprintf(stderr, "cuttCheck() failed at %s:%i\n", __FILE__, __LINE__);
    exit(-1);
  }
}

const int NUM_REPS = 10;


void parse(char *source, std::vector<int>& vec)
{
  char delims[] = "=,";
  char *token;
  
  token = strtok(source, delims); // remove flag
  token = strtok(NULL, delims);
  while (token != NULL) {
    //printf("%s\n", token);
    vec.push_back(atoi(token));
    token = strtok(NULL, delims);
  }
}

int main(int argc, char *argv[])
{
  int bondDim;
  char* datname;
  std::vector<int> vecperm;
  std::vector<int> vecsize;
  for(int i = 0; i < argc; ++i) {
    if (!strncmp(argv[i], "--bond", 6)) {
      char delims[] = "=,";
      char *token;
      token = strtok(argv[i], delims); // remove flag
      token = strtok(NULL, delims);
      bondDim = atoi(token);
    }
    if (!strncmp(argv[i], "--datname", 9)) {
      char delims[] = "=";
      char *token;
      token = strtok(argv[i], delims); // remove flag
      token = strtok(NULL, delims);
      datname = token;
    }
    if (!strncmp(argv[i], "--size", 6))
      parse(argv[i], vecsize);
    if (!strncmp(argv[i], "--perm", 6))
      parse(argv[i], vecperm);
  }

  int dim = vecsize.size();
  int* perm = vecperm.data();
  int* size = vecsize.data();

  size_t total_size = 1;
  for(int i = 0; i < dim ; ++i)
    total_size *= size[i];

  int memSize = total_size*sizeof(floatType);

  floatType *h_idata = (floatType*)malloc(memSize);
  floatType *h_odata = (floatType*)malloc(memSize);

  floatType *d_idata, *d_odata;
  CudaSafeCall( cudaMalloc(&d_idata, memSize) );
  CudaSafeCall( cudaMalloc(&d_odata, memSize) );

  for (int i = 0; i < total_size; i++)
    h_idata[i] = (floatType)rand() / RAND_MAX;

  CudaSafeCall( cudaMemcpy(d_idata, h_idata, memSize, cudaMemcpyHostToDevice) );
  CudaSafeCall( cudaMemset(d_odata, 0, memSize) );


  // Events for timing
  cudaEvent_t startEvent, stopEvent;
  CudaSafeCall( cudaEventCreate(&startEvent) );
  CudaSafeCall( cudaEventCreate(&stopEvent) );
  float ms;

  cuttHandle plan;
  cuttCheck( cuttPlan(&plan, dim, vecsize.data(), vecperm.data(), sizeof(floatType), 0) );

  double minTime = 1e100;
  for (int i = 0; i < NUM_REPS; i++) {
    CudaSafeCall( cudaMemcpy(d_idata, h_idata, memSize, cudaMemcpyHostToDevice) );

    CudaSafeCall( cudaEventRecord(startEvent, 0) );

    cuttCheck( cuttExecute(plan, d_idata, d_odata) );

    CudaSafeCall( cudaEventRecord(stopEvent, 0) );
    CudaSafeCall( cudaEventSynchronize(stopEvent) );
    CudaSafeCall( cudaEventElapsedTime(&ms, startEvent, stopEvent) );

    minTime = (minTime < ms) ? minTime : ms;
  }

  FILE *pf = fopen(datname, "a");
  fprintf(pf,"%5d%20.12f%20.12f\n", bondDim, ms, 2*total_size*sizeof(float)*1e-6/ms);
  fclose(pf);

  cuttCheck( cuttDestroy(plan) );
}
