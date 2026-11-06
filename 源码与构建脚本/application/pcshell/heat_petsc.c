#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include "pcshell_mt.h"
#include <dlfcn.h>
#include <math.h>
#include <omp.h>
#include <sched.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

static uint64_t HashBytes(const void *p, size_t n)
{
  const unsigned char *bytes = p;
  uint64_t hash = UINT64_C(14695981039346656037);
  for (size_t i = 0; i < n; i++) { hash ^= bytes[i]; hash *= UINT64_C(1099511628211); }
  return hash;
}

static PetscErrorCode MatrixHash(Mat A, uint64_t *hash)
{
  PetscInt n;
  const PetscInt *rowptr, *colind;
  const PetscScalar *values;
  PetscBool done;

  PetscFunctionBeginUser;
  PetscCall(MatGetRowIJ(A, 0, PETSC_FALSE, PETSC_FALSE, &n, &rowptr, &colind, &done));
  PetscCheck(done, PETSC_COMM_SELF, PETSC_ERR_SUP, "CSR view required");
  PetscCall(MatSeqAIJGetArrayRead(A, &values));
  *hash = HashBytes(rowptr, (n+1)*sizeof(*rowptr)) ^ HashBytes(colind, rowptr[n]*sizeof(*colind)) ^ HashBytes(values, rowptr[n]*sizeof(*values));
  PetscCall(MatSeqAIJRestoreArrayRead(A, &values));
  PetscCall(MatRestoreRowIJ(A, 0, PETSC_FALSE, PETSC_FALSE, &n, &rowptr, &colind, &done));
  PetscFunctionReturn(PETSC_SUCCESS);
}

static PetscErrorCode Provider(const char *symbol)
{
  void *address = dlsym(RTLD_DEFAULT, symbol);
  Dl_info info = {0};

  PetscFunctionBeginUser;
  PetscCheck(address && dladdr(address, &info), PETSC_COMM_SELF, PETSC_ERR_LIB, "Missing provider for %s", symbol);
  printf("PETSC_HEAT_PROVIDER {\"symbol\":\"%s\",\"path\":\"%s\"}\n", symbol, info.dli_fname);
  PetscFunctionReturn(PETSC_SUCCESS);
}

int main(int argc, char **argv)
{
  PetscInt grid = 16, steps = 10, N;
  PetscReal dt = .001, h, ratio, lambda, gain, lastenergy, maxerror = 0, maxresidual = 0;
  PetscReal error, residual, rhsnorm, refnorm, norm, minimum, maximum, en, continuous;
  PetscScalar *array;
  const PetscScalar *read;
  Mat A;
  Vec current, next, initial, reference, scratch;
  KSP ksp;
  PC pc;
  KSPConvergedReason reason;
  HeatMTContext ctx = {0};
  PetscBool builtin = PETSC_FALSE;
  uint64_t before, after;
  int team = 0, cpus[2] = {-1, -1}, affinity_ok[2] = {0, 0};
  unsigned long vlenb;
  char version[256];
  typedef float (*Slamch)(char *);
  typedef double (*Dlamch)(char *);
  typedef const char *(*Config)(void);
  typedef int (*Threads)(void);
  Slamch sm = (Slamch)dlsym(RTLD_DEFAULT, "slamch_");
  Dlamch dm = (Dlamch)dlsym(RTLD_DEFAULT, "dlamch_");
  Config config = (Config)dlsym(RTLD_DEFAULT, "openblas_get_config");
  Threads threads = (Threads)dlsym(RTLD_DEFAULT, "openblas_get_num_threads");
  char eps = 'E', safe = 'S';

  /* Initialize LAPACK's machine constants before any OpenMP worker uses them. */
  if (!sm || !dm || !config || !threads || !strstr(config(), "USE_LOCKING") || threads() != 1) return 2;
  if (!(sm(&eps)>0 && sm(&safe)>0 && dm(&eps)>0 && dm(&safe)>0)) return 3;
  PetscCall(PetscInitialize(&argc, &argv, NULL, "Transient heat conduction with PETSc and STRUMPACK MT\n"));
  PetscCall(PetscOptionsGetInt(NULL, NULL, "-heat_grid", &grid, NULL));
  PetscCall(PetscOptionsGetInt(NULL, NULL, "-heat_steps", &steps, NULL));
  PetscCall(PetscOptionsGetReal(NULL, NULL, "-heat_dt", &dt, NULL));
  PetscCall(PetscOptionsGetBool(NULL, NULL, "-heat_petsc_lu", &builtin, NULL));
  PetscCheck(grid >= 2 && grid <= 128 && steps > 0 && steps <= 100 && dt > 0 && isfinite(dt), PETSC_COMM_SELF, PETSC_ERR_ARG_OUTOFRANGE, "Invalid heat model parameters");
  PetscCheck(omp_get_max_threads() >= 1 && omp_get_max_threads() <= 2, PETSC_COMM_SELF, PETSC_ERR_SUP, "This QEMU protocol admits one or two workers");
  #pragma omp parallel shared(team, cpus, affinity_ok)
  {
    int t = omp_get_thread_num();
    cpu_set_t requested, actual;
    CPU_ZERO(&requested); CPU_SET(t, &requested);
    affinity_ok[t] = !sched_setaffinity(0, sizeof(requested), &requested) && !sched_getaffinity(0, sizeof(actual), &actual) && CPU_EQUAL(&requested, &actual);
    cpus[t] = sched_getcpu();
    #pragma omp single
    team = omp_get_num_threads();
  }
  PetscCheck(affinity_ok[0] && (team == 1 || affinity_ok[1]), PETSC_COMM_SELF, PETSC_ERR_SYS, "Worker binding failed");
  __asm__ volatile("csrr %0, 0xc22" : "=r"(vlenb));
  PetscCheck(vlenb == 32, PETSC_COMM_SELF, PETSC_ERR_SUP, "VLEN256 required by this protocol");
  PetscCall(PetscGetVersion(version, sizeof(version)));
  printf("PETSC_HEAT_ENV {\"petsc_built\":true,\"team\":%d,\"cpus\":[%d,%d],\"vlenb\":%lu,\"builtin_lu\":%s,\"version\":\"%s\"}\n", team, cpus[0], cpus[1], vlenb, builtin ? "true" : "false", version);
  PetscCall(Provider("PetscInitialize")); PetscCall(Provider("KSPSolve"));
  PetscCall(Provider("PCShellSetApply")); PetscCall(Provider("STRUMPACK_init_mt"));
  PetscCall(Provider("omp_get_num_threads")); PetscCall(Provider("dgemv_")); PetscCall(Provider("dgemv_n"));
  N = grid*grid; h = 1./(grid+1); ratio = dt/(h*h);
  lambda = 8./(h*h)*pow(sin(PETSC_PI*h/2), 2); gain = 1./(1.+dt*lambda);
  PetscCall(MatCreateSeqAIJ(PETSC_COMM_SELF, N, N, 5, NULL, &A));
  for (PetscInt row = 0; row < grid; row++) for (PetscInt col = 0; col < grid; col++) {
    PetscInt i = col+grid*row, count = 0, columns[5];
    PetscScalar values[5];
    columns[count] = i; values[count++] = 1.+4.*ratio;
    if (col > 0) { columns[count] = i-1; values[count++] = -ratio; }
    if (col+1 < grid) { columns[count] = i+1; values[count++] = -ratio; }
    if (row > 0) { columns[count] = i-grid; values[count++] = -ratio; }
    if (row+1 < grid) { columns[count] = i+grid; values[count++] = -ratio; }
    PetscCall(MatSetValues(A, 1, &i, count, columns, values, INSERT_VALUES));
  }
  PetscCall(MatAssemblyBegin(A, MAT_FINAL_ASSEMBLY)); PetscCall(MatAssemblyEnd(A, MAT_FINAL_ASSEMBLY));
  PetscCall(MatrixHash(A, &before));
  PetscCall(MatCreateVecs(A, &current, &next));
  PetscCall(VecDuplicate(current, &initial)); PetscCall(VecDuplicate(current, &reference)); PetscCall(VecDuplicate(current, &scratch));
  PetscCall(VecGetArray(initial, &array));
  for (PetscInt row = 0; row < grid; row++) for (PetscInt col = 0; col < grid; col++) array[col+grid*row] = sin(PETSC_PI*(col+1)*h)*sin(PETSC_PI*(row+1)*h);
  PetscCall(VecRestoreArray(initial, &array)); PetscCall(VecCopy(initial, current));
  PetscCall(KSPCreate(PETSC_COMM_SELF, &ksp)); PetscCall(KSPSetType(ksp, KSPPREONLY)); PetscCall(KSPSetOperators(ksp, A, A));
  PetscCall(KSPGetPC(ksp, &pc));
  if (builtin) PetscCall(PCSetType(pc, PCLU));
  else PetscCall(HeatMTAttach(pc, grid, &ctx));
  PetscCall(KSPSetErrorIfNotConverged(ksp, PETSC_TRUE)); PetscCall(KSPSetUp(ksp));
  PetscCall(VecNorm(current, NORM_2, &norm)); lastenergy = h*h*norm*norm;
  for (PetscInt step = 1; step <= steps; step++) {
    PetscCall(KSPSolve(ksp, current, next)); PetscCall(KSPGetConvergedReason(ksp, &reason));
    PetscCheck(reason > 0, PETSC_COMM_SELF, PETSC_ERR_NOT_CONVERGED, "Heat solve failed");
    PetscCall(MatMult(A, next, scratch)); PetscCall(VecAXPY(scratch, -1., current));
    PetscCall(VecNorm(scratch, NORM_2, &residual)); PetscCall(VecNorm(current, NORM_2, &rhsnorm)); residual /= rhsnorm;
    PetscCall(VecCopy(initial, reference)); PetscCall(VecScale(reference, pow(gain, step)));
    PetscCall(VecWAXPY(scratch, -1., reference, next)); PetscCall(VecNorm(scratch, NORM_2, &error)); PetscCall(VecNorm(reference, NORM_2, &refnorm)); error /= refnorm;
    PetscCall(VecNorm(next, NORM_2, &norm)); en = h*h*norm*norm;
    PetscCall(VecMin(next, NULL, &minimum)); PetscCall(VecMax(next, NULL, &maximum));
    PetscCheck(isfinite(error) && error < 1e-10 && isfinite(residual) && residual < 1e-10, PETSC_COMM_SELF, PETSC_ERR_PLIB, "Heat discrete reference or residual mismatch");
    PetscCheck(minimum >= -1e-12 && maximum <= 1.+1e-12 && en < lastenergy, PETSC_COMM_SELF, PETSC_ERR_PLIB, "Heat energy or maximum principle failed");
    continuous = fabs(pow(gain, step)-exp(-2.*PETSC_PI*PETSC_PI*step*dt))/exp(-2.*PETSC_PI*PETSC_PI*step*dt);
    PetscCall(MatrixHash(A, &after)); PetscCheck(before == after, PETSC_COMM_SELF, PETSC_ERR_PLIB, "Operator changed");
    printf("PETSC_HEAT_STEP {\"step\":%d,\"time\":%.17g,\"energy\":%.17g,\"discrete_relative_error\":%.17g,\"continuous_relative_error\":%.17g,\"relative_residual\":%.17g}\n", (int)step, step*dt, en, error, continuous, residual);
    maxerror = fmax(maxerror, error); maxresidual = fmax(maxresidual, residual); lastenergy = en;
    PetscCall(VecCopy(next, current));
  }
  PetscCall(VecGetArrayRead(current, &read));
  for (PetscInt row = 0; row < grid; row++) for (PetscInt col = 0; col < grid; col++) printf("PETSC_HEAT_FIELD %d %d %.17g\n", (int)row, (int)col, (double)read[col+grid*row]);
  PetscCall(VecRestoreArrayRead(current, &read));
  PetscCall(KSPView(ksp, PETSC_VIEWER_STDOUT_SELF));
  PetscCall(KSPDestroy(&ksp));
  PetscCheck(builtin || (ctx.setups == 1 && ctx.applies == steps && ctx.destroys == 1 && !ctx.initialized), PETSC_COMM_SELF, PETSC_ERR_PLIB, "PCSHELL lifecycle mismatch");
  PetscCall(VecDestroy(&current)); PetscCall(VecDestroy(&next)); PetscCall(VecDestroy(&initial)); PetscCall(VecDestroy(&reference)); PetscCall(VecDestroy(&scratch)); PetscCall(MatDestroy(&A));
  printf("PETSC_HEAT_RESULT {\"grid\":%d,\"steps\":%d,\"setups\":%d,\"applies\":%d,\"destroys\":%d,\"operator_unchanged\":true,\"max_discrete_error\":%.17g,\"max_residual\":%.17g,\"final_energy\":%.17g,\"performance\":\"NOT_MEASURED\"}\n", (int)grid, (int)steps, (int)ctx.setups, (int)ctx.applies, (int)ctx.destroys, maxerror, maxresidual, lastenergy);
  PetscCall(PetscFinalize());
  puts("PETSC_HEAT_EXIT=0");
  return 0;
}
